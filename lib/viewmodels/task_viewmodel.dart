import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../services/db_service.dart';
import '../services/notification_service.dart';
import '../services/translation_service.dart';
import '../services/category_service.dart';

class TaskViewModel extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  final CategoryService _categoryService = CategoryService();

  List<Task> _tasks = [];
  List<Task> _todayTasks = [];
  List<Task> _overdueTasks = [];
  bool _isLoading = false;
  String? _error;
  DateTime _selectedDate = DateTime.now();
  
  // Flag pour éviter la génération récursive pendant les mises à jour
  bool _isGeneratingRecurringTasks = false;

  // Constructeur - configurer le callback immédiatement
  TaskViewModel() {
    // Configurer le callback dès la création du ViewModel
    _notificationService.setNotificationActionCallback((taskId, actionId) {
      print('=== CALLBACK D\'ACTION DÉCLENCHÉ (CONSTRUCTEUR) ===');
      print('TaskId reçu: $taskId, ActionId reçu: $actionId');
      _handleNotificationAction(taskId, actionId);
    });
    print('Callback d\'action configuré dans le constructeur TaskViewModel');
  }

  // Getters
  List<Task> get tasks => _tasks;
  List<Task> get todayTasks => _todayTasks;
  List<Task> get overdueTasks => _overdueTasks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get selectedDate => _selectedDate;

  // Statistiques
  int get totalTasks => _tasks.length;
  int get completedTasks => _tasks.where((task) => task.isCompleted).length;
  int get pendingTasks => _tasks.where((task) => !task.isCompleted).length;
  int get todayCompletedTasks => _todayTasks.where((task) => task.isCompleted).length;
  int get todayPendingTasks => _todayTasks.where((task) => !task.isCompleted).length;

  // Pourcentage de completion aujourd'hui
  double get todayCompletionPercentage {
    if (_todayTasks.isEmpty) return 0.0;
    return (todayCompletedTasks / _todayTasks.length) * 100;
  }

  // Initialiser le ViewModel
  Future<void> initialize() async {
    _setLoading(true);
    try {
      // Charger les tâches en premier (plus rapide)
      await loadAllTasks();
      
      // Initialiser les catégories par défaut en arrière-plan
      _initializeCategoriesAsync();
      
      // Permettre à l'UI de se charger avant d'initialiser les notifications
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Initialiser les notifications en arrière-plan (non bloquant)
      _initializeNotificationsAsync();
    } catch (e) {
      print('Erreur lors de l\'initialisation du ViewModel: $e');
      _setError('Erreur lors de l\'initialisation: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Initialiser les notifications de manière asynchrone
  void _initializeNotificationsAsync() async {
    // IMPORTANT: Configurer le callback AVANT toute tentative d'initialisation
    _notificationService.setNotificationActionCallback((taskId, actionId) {
      print('=== CALLBACK D\'ACTION DÉCLENCHÉ ===');
      print('TaskId reçu: $taskId, ActionId reçu: $actionId');
      _handleNotificationAction(taskId, actionId);
    });
    print('Callback d\'action configuré dans TaskViewModel');
    
    try {
      // Attendre un peu avant d'initialiser pour éviter les conflits
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Initialiser avec un timeout pour éviter les blocages
      await _notificationService.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Timeout lors de l\'initialisation des notifications, continuation sans notifications');
          return;
        },
      );
      print('Initialisation du service de notifications terminée');
      
      // Programmer les notifications en arrière-plan
      _scheduleNotificationsForTodayAsync();
      
    } catch (e) {
      print('Erreur notifications (non bloquant): $e');
      // Le callback reste configuré même en cas d'erreur
    }
  }

  // Initialiser les catégories par défaut de manière asynchrone
  void _initializeCategoriesAsync() async {
    try {
      // Utiliser le français par défaut pour l'initialisation
      // Les catégories peuvent être traduites manuellement par l'utilisateur
      await _categoryService.createDefaultCategories(language: 'fr');
    } catch (e) {
      print('Erreur lors de l\'initialisation des catégories: $e');
    }
  }

  // Méthode publique pour initialiser les catégories avec une langue spécifique
  Future<void> initializeCategoriesWithLanguage(String language) async {
    try {
      await _categoryService.createDefaultCategories(language: language);
    } catch (e) {
      print('Erreur lors de l\'initialisation des catégories avec la langue $language: $e');
    }
  }

  // Programmer les notifications de manière asynchrone
  void _scheduleNotificationsForTodayAsync() async {
    try {
      await _scheduleNotificationsForToday();
    } catch (e) {
      print('Erreur lors de la programmation des notifications: $e');
    }
  }

  // Gérer les actions des notifications
  void _handleNotificationAction(String taskId, String actionId) async {
    print('=== GESTION ACTION NOTIFICATION ===');
    print('TaskId: $taskId, ActionId: $actionId');
    print('Nombre de tâches en mémoire: ${_tasks.length}');
    
    try {
      // Vérifier si la tâche existe
      final taskExists = _tasks.any((task) => task.id == taskId);
      print('Tâche trouvée: $taskExists');
      
      if (!taskExists) {
        print('ERREUR: Tâche $taskId non trouvée en mémoire');
        return;
      }
      
      if (actionId == 'complete') {
        // Marquer la tâche comme terminée
        print('Marquage de la tâche $taskId comme terminée via notification');
        final result = await completeTask(taskId);
        print('Résultat completion: $result');
      } else if (actionId == 'snooze') {
        // Reporter la notification de 10 minutes
        print('Report de la tâche $taskId de 10 minutes via notification');
        await _snoozeTaskNotification(taskId);
      } else {
        print('Action non reconnue: $actionId');
      }
    } catch (e) {
      print('Erreur lors de la gestion de l\'action notification: $e');
      print('Stack trace: ${StackTrace.current}');
      _setError('Erreur lors de l\'action sur notification: $e');
    }
    
    print('=== FIN GESTION ACTION NOTIFICATION ===');
  }

  // Reporter une notification de tâche
  Future<void> _snoozeTaskNotification(String taskId) async {
    try {
      final task = _tasks.firstWhere((t) => t.id == taskId);
      if (!task.isCompleted) {
        // Annuler l'ancienne notification
        await _notificationService.cancelTaskNotification(taskId);
        
        // Reporter de 10 minutes - créer une tâche temporaire pour la notification
        final newTime = DateTime.now().add(const Duration(minutes: 10));
        final snoozedTask = task.copyWith(
          date: DateTime(newTime.year, newTime.month, newTime.day),
          time: TimeOfDay(hour: newTime.hour, minute: newTime.minute),
        );
        
        // Programmer la notification différée sans modifier la tâche originale
        await _notificationService.scheduleTaskNotification(snoozedTask);
        
        print('Notification reportée de 10 minutes pour la tâche: ${task.title}');
      }
    } catch (e) {
      print('Erreur lors du report de notification: $e');
    }
  }

  // Charger toutes les tâches
  Future<void> loadAllTasks() async {
    try {
      _tasks = await _dbService.getAllTasks();
      
      print('Chargement de ${_tasks.length} tâches depuis la base de données');
      
      // Nettoyer les doublons potentiels
      _removeDuplicateTasks();
      
      // Mettre à jour les tâches d'aujourd'hui et en retard immédiatement
      await _updateTodayTasks();
      await _updateOverdueTasks();
      _clearError();
      
      // Ne PAS générer automatiquement les tâches récurrentes au démarrage
      // Cela sera fait à la demande quand l'utilisateur navigue vers des dates futures
      print('Chargement terminé: ${_tasks.length} tâches chargées depuis la base de données');
      
    } catch (e) {
      print('Erreur lors du chargement des tâches: $e');
      _setError('Erreur lors du chargement des tâches: $e');
    }
  }

  // Nettoyer les doublons de tâches
  void _removeDuplicateTasks() {
    final seen = <String>{};
    final uniqueTasks = <Task>[];
    
    for (final task in _tasks) {
      // Créer une clé unique basée sur les propriétés importantes
      final key = '${task.title}_${task.date}_${task.time.hour}_${task.time.minute}_${task.description ?? ''}_${task.categoryId ?? ''}';
      
      if (!seen.contains(key)) {
        seen.add(key);
        uniqueTasks.add(task);
      } else {
        print('Doublon détecté et supprimé: ${task.title} - ${task.date}');
      }
    }
    
    if (_tasks.length != uniqueTasks.length) {
      print('${_tasks.length - uniqueTasks.length} doublons supprimés');
      _tasks = uniqueTasks;
    }
  }

  // Mettre à jour les tâches d'aujourd'hui
  Future<void> _updateTodayTasks() async {
    _todayTasks = _tasks.where((task) => task.isToday).toList();
    _todayTasks.sort((a, b) => a.fullDateTime.compareTo(b.fullDateTime));
  }

  // Mettre à jour les tâches en retard
  Future<void> _updateOverdueTasks() async {
    _overdueTasks = _tasks.where((task) => task.isOverdue).toList();
    _overdueTasks.sort((a, b) => a.fullDateTime.compareTo(b.fullDateTime));
  }

  // Ajouter une nouvelle tâche
  Future<bool> addTask({
    required String title,
    String? description,
    required DateTime date,
    required TimeOfDay time,
    bool notificationsEnabled = true,
    bool soundEnabled = true,
    bool vibrationEnabled = false,
    String? customSoundUri,
    TaskRecurrence recurrence = TaskRecurrence.none,
    String? categoryId,
  }) async {
    try {
      final task = Task(
        title: title,
        description: description,
        date: date,
        time: time,
        notificationsEnabled: notificationsEnabled,
        soundEnabled: soundEnabled,
        vibrationEnabled: vibrationEnabled,
        customSoundUri: customSoundUri,
        recurrence: recurrence,
        categoryId: categoryId,
      );

      // Ajouter seulement la tâche originale (les répétitions seront générées dynamiquement)
      _tasks.add(task);
      
      // Ne générer des tâches récurrentes que si on n'a pas dépassé la limite
      if (_tasks.length < 900) {
        _generateRecurringTasksIfNeeded();
      }
      
      _updateTodayTasksSync();
      _updateOverdueTasksSync();
      notifyListeners();
      
      // Sauvegarder en base de données en arrière-plan
      _saveTaskAsync(task);

      return true;
    } catch (e) {
      _setError('Erreur lors de l\'ajout de la tâche: $e');
      return false;
    }
  }

  // Générer dynamiquement les tâches récurrentes manquantes pour une période limitée (synchrone)
  void _generateRecurringTasksIfNeeded() {
    // Éviter la génération récursive qui peut causer des problèmes de mémoire
    if (_isGeneratingRecurringTasks) {
      print('Génération de tâches récurrentes en cours, évitement de la récursion');
      return;
    }
    
    _isGeneratingRecurringTasks = true;
    
    try {
      final now = DateTime.now();
      final futureLimit = now.add(const Duration(days: 30)); // Limiter à 30 jours dans le futur
      
      // Limiter le nombre total de tâches pour éviter l'exhaustion mémoire (limite plus stricte)
      if (_tasks.length > 300) {
        print('Trop de tâches en mémoire (${_tasks.length}), limitation de la génération');
        return;
      }
      
      // Obtenir toutes les tâches originales récurrentes (pas les occurrences déjà générées)
      final originalRecurringTasks = _getOriginalRecurringTasks();
      
      print('Génération de tâches récurrentes pour ${originalRecurringTasks.length} tâches originales');
      
      for (final task in originalRecurringTasks) {
        if (task.recurrence != TaskRecurrence.none) {
          _generateNextRecurringTasks(task, futureLimit);
        }
      }
      
      // Nettoyer les doublons après génération
      _removeDuplicateTasks();
    } finally {
      _isGeneratingRecurringTasks = false;
    }
  }

  // Générer dynamiquement les tâches récurrentes de manière asynchrone pour éviter le blocage
  Future<void> _generateRecurringTasksIfNeededAsync() async {
    // Éviter la génération récursive
    if (_isGeneratingRecurringTasks) {
      print('Génération asynchrone de tâches récurrentes en cours, évitement de la récursion');
      return;
    }
    
    _isGeneratingRecurringTasks = true;
    
    try {
      final now = DateTime.now();
      final futureLimit = now.add(const Duration(days: 30));
      
      // Limiter le nombre total de tâches (limite plus stricte pour éviter l'OOM)
      if (_tasks.length > 300) {
        print('Trop de tâches en mémoire (${_tasks.length}), limitation de la génération asynchrone');
        return;
      }
      
      // Obtenir toutes les tâches originales récurrentes
      final originalRecurringTasks = _getOriginalRecurringTasks();
      
      print('Génération asynchrone de tâches récurrentes pour ${originalRecurringTasks.length} tâches originales');
      
      // Traiter les tâches par batch pour éviter de bloquer l'UI
      for (int i = 0; i < originalRecurringTasks.length; i++) {
        final task = originalRecurringTasks[i];
        if (task.recurrence != TaskRecurrence.none) {
          _generateNextRecurringTasks(task, futureLimit);
          
          // Permettre à l'UI de se mettre à jour après chaque tâche
          if (i % 3 == 0) {
            await Future.delayed(const Duration(milliseconds: 10));
            notifyListeners();
          }
        }
      }
      
      // Nettoyer les doublons après génération
      _removeDuplicateTasks();
      
      // Mettre à jour l'UI à la fin
      await _updateTodayTasks();
      await _updateOverdueTasks();
      notifyListeners();
      
      print('Génération asynchrone de tâches récurrentes terminée');
      
    } catch (e) {
      print('Erreur lors de la génération asynchrone: $e');
    } finally {
      _isGeneratingRecurringTasks = false;
    }
  }

  // Obtenir les tâches récurrentes originales (éliminer les doublons)
  List<Task> _getOriginalRecurringTasks() {
    final Map<String, Task> originalTasks = {};
    
    for (final task in _tasks) {
      if (task.recurrence != TaskRecurrence.none) {
        // Utiliser une clé basée sur le titre, récurrence et heure pour identifier l'originale
        final taskKey = '${task.title}_${task.recurrence.name}_${task.time.hour}_${task.time.minute}';
        
        if (!originalTasks.containsKey(taskKey) || 
            task.createdAt.isBefore(originalTasks[taskKey]!.createdAt)) {
          originalTasks[taskKey] = task;
        }
      }
    }
    
    return originalTasks.values.toList();
  }

  // Générer les prochaines tâches récurrentes pour une tâche donnée
  void _generateNextRecurringTasks(Task originalTask, DateTime limitDate) {
    final now = DateTime.now();
    final pastLimit = now.subtract(const Duration(days: 7)); // Ne pas générer de tâches trop anciennes
    
    // Améliorer la détection des doublons en utilisant une clé unique
    final existingDates = _tasks
        .where((t) => t.title == originalTask.title && 
                     t.recurrence == originalTask.recurrence && 
                     t.time == originalTask.time &&
                     t.description == originalTask.description &&
                     t.categoryId == originalTask.categoryId)
        .map((t) => DateTime(t.date.year, t.date.month, t.date.day))
        .toSet();

    // Trouver la date de début : soit la date originale, soit la dernière occurrence existante
    DateTime currentDate = originalTask.date;
    final latestExistingDate = existingDates.isNotEmpty 
        ? existingDates.reduce((a, b) => a.isAfter(b) ? a : b)
        : originalTask.date;
    
    // Commencer à partir de la dernière occurrence connue pour éviter les doublons
    if (latestExistingDate.isAfter(currentDate)) {
      currentDate = latestExistingDate;
    }

    int generatedCount = 0;
    final maxGenerateCount = originalTask.recurrence == TaskRecurrence.daily ? 30 : 12;
    
    // Limite de sécurité pour éviter l'exhaustion mémoire
    final safetyLimit = 50;
    int loopCount = 0;

    while (currentDate.isBefore(limitDate) && 
           generatedCount < maxGenerateCount && 
           loopCount < safetyLimit &&
           _tasks.length < 1000) { // Limite absolue de tâches en mémoire
      
      currentDate = originalTask.recurrence.getNextDate(currentDate);
      loopCount++;
      
      final normalizedCurrentDate = DateTime(currentDate.year, currentDate.month, currentDate.day);
      
      // Générer la tâche si:
      // 1. Elle n'existe pas déjà
      // 2. Elle n'est pas trop ancienne (dans les 7 derniers jours)
      if (!existingDates.contains(normalizedCurrentDate) && 
          currentDate.isAfter(pastLimit)) {
        final recurringTask = originalTask.copyWith(
          id: const Uuid().v4(),
          date: currentDate,
        );
        _tasks.add(recurringTask);
        generatedCount++;
        
        // Sauvegarder la nouvelle tâche en arrière-plan mais éviter les appels récursifs
        _saveTaskAsyncSafe(recurringTask);
      }
    }
    
    if (generatedCount > 0) {
      print('Généré $generatedCount nouvelles tâches récurrentes pour ${originalTask.title}');
    }
  }

  // Générer la prochaine tâche récurrente après completion d'une tâche
  void _generateNextRecurringTaskAfterCompletion(Task completedTask) {
    final now = DateTime.now();
    final futureLimit = now.add(const Duration(days: 30));
    
    // Trouver la prochaine date de récurrence après la tâche complétée
    DateTime nextDate = completedTask.recurrence.getNextDate(completedTask.date);
    
    // Vérifier si cette date n'existe pas déjà et est dans la limite acceptable
    final existingDates = _tasks
        .where((t) => t.title == completedTask.title && 
                     t.recurrence == completedTask.recurrence && 
                     t.time == completedTask.time &&
                     !t.isCompleted)
        .map((t) => DateTime(t.date.year, t.date.month, t.date.day))
        .toSet();

    final normalizedNextDate = DateTime(nextDate.year, nextDate.month, nextDate.day);
    
    if (!existingDates.contains(normalizedNextDate) && nextDate.isBefore(futureLimit)) {
      final nextRecurringTask = completedTask.copyWith(
        id: const Uuid().v4(),
        date: nextDate,
        isCompleted: false,
        completedAt: null,
      );
      
      _tasks.add(nextRecurringTask);
      
      // Sauvegarder la nouvelle tâche en arrière-plan
      _saveTaskAsync(nextRecurringTask);
    }
  }

  // Sauvegarder la tâche de manière asynchrone
  void _saveTaskAsync(Task task) async {
    try {
      await _dbService.insertTask(task);
      
      // Programmer la notification seulement pour les tâches d'aujourd'hui
      if (task.isToday && task.fullDateTime.isAfter(DateTime.now())) {
        _scheduleNotificationAsync(task);
      }
    } catch (e) {
      print('Erreur sauvegarde tâche (non bloquant): $e');
      // Optionnel: retirer la tâche de la liste si la sauvegarde échoue
      _tasks.removeWhere((t) => t.id == task.id);
      _updateTodayTasksSync();
      _updateOverdueTasksSync();
      notifyListeners();
    }
  }

  // Sauvegarder la tâche de manière asynchrone sécurisée (évite la récursion)
  void _saveTaskAsyncSafe(Task task) async {
    try {
      await _dbService.insertTask(task);
      
      // Programmer la notification seulement pour les tâches d'aujourd'hui, mais éviter les appels récursifs
      if (task.isToday && task.fullDateTime.isAfter(DateTime.now()) && !_isGeneratingRecurringTasks) {
        _scheduleNotificationAsync(task);
      }
    } catch (e) {
      print('Erreur sauvegarde tâche sécurisée (non bloquant): $e');
      // Ne pas retirer la tâche automatiquement lors de la génération pour éviter les problèmes
    }
  }

  // Mise à jour synchrone des tâches d'aujourd'hui
  void _updateTodayTasksSync() {
    _todayTasks = _tasks.where((task) => task.isToday).toList();
    _todayTasks.sort((a, b) => a.fullDateTime.compareTo(b.fullDateTime));
  }

  // Mise à jour synchrone des tâches en retard
  void _updateOverdueTasksSync() {
    _overdueTasks = _tasks.where((task) => task.isOverdue).toList();
    _overdueTasks.sort((a, b) => a.fullDateTime.compareTo(b.fullDateTime));
  }

  // Programmer une notification de manière asynchrone
  void _scheduleNotificationAsync(Task task) async {
    try {
      await _notificationService.scheduleTaskNotification(task);
    } catch (e) {
      print('Erreur programmation notification (non bloquant): $e');
    }
  }

  // Mettre à jour une tâche
  Future<bool> updateTask(Task task, {bool updateAllOccurrences = false}) async {
    try {
      final originalTask = _tasks.firstWhere((t) => t.id == task.id);
      
      // Limiter le nombre de tâches à traiter pour éviter l'exhaustion mémoire (limite plus stricte)
      if (_tasks.length > 300) {
        print('Trop de tâches en mémoire (${_tasks.length}), limitation de la mise à jour');
        // Faire seulement une mise à jour simple pour éviter les problèmes
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _tasks[index] = task;
          _updateTodayTasksSync();
          _updateOverdueTasksSync();
          notifyListeners();
          _updateTaskAsync(task);
        }
        return true;
      }
      
      if (updateAllOccurrences && originalTask.recurrence != TaskRecurrence.none) {
        // Mettre à jour toutes les occurrences de cette tâche récurrente
        return await _updateAllRecurringTasks(originalTask, task);
      } else {
        // Mettre à jour seulement cette occurrence
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _tasks[index] = task;
          _updateTodayTasksSync();
          _updateOverdueTasksSync();
          notifyListeners();
        }
        
        // Sauvegarder en base de données en arrière-plan
        _updateTaskAsync(task);
      }

      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour de la tâche: $e');
      _setError('Erreur lors de la mise à jour de la tâche: $e');
      return false;
    }
  }

  // Mettre à jour toutes les occurrences d'une tâche récurrente
  Future<bool> _updateAllRecurringTasks(Task originalTask, Task updatedTask) async {
    try {
      // Limiter le nombre de tâches pour éviter l'exhaustion mémoire (limite plus stricte)
      if (_tasks.length > 300) {
        print('Trop de tâches (${_tasks.length}), limitation de la mise à jour récurrente');
        return false;
      }
      
      // Trouver toutes les occurrences de cette tâche récurrente
      final tasksToUpdate = _tasks.where((task) => 
        task.title == originalTask.title &&
        task.recurrence == originalTask.recurrence &&
        task.time == originalTask.time
      ).toList();

      print('Mise à jour de ${tasksToUpdate.length} occurrences de tâches récurrentes');
      
      // Limiter le nombre d'occurrences mises à jour simultanément
      final maxUpdates = 100;
      final limitedTasksToUpdate = tasksToUpdate.take(maxUpdates).toList();
      
      if (tasksToUpdate.length > maxUpdates) {
        print('Limitation à $maxUpdates tâches sur ${tasksToUpdate.length} trouvées');
      }

      int updateCount = 0;
      // Mettre à jour toutes les occurrences avec les nouvelles données
      for (int i = 0; i < _tasks.length && updateCount < limitedTasksToUpdate.length; i++) {
        final currentTask = _tasks[i];
        if (limitedTasksToUpdate.any((t) => t.id == currentTask.id)) {
          _tasks[i] = updatedTask.copyWith(
            id: currentTask.id, // Garder l'ID original
            date: currentTask.date, // Garder la date originale de chaque occurrence
            createdAt: currentTask.createdAt, // Garder la date de création originale
            isCompleted: currentTask.isCompleted, // Garder le statut de completion
            completedAt: currentTask.completedAt, // Garder la date de completion
          );
          
          updateCount++;
          
          // Sauvegarder en base de données en arrière-plan
          _updateTaskAsync(_tasks[i]);
        }
      }

      _updateTodayTasksSync();
      _updateOverdueTasksSync();
      notifyListeners();

      print('Mise à jour terminée: $updateCount tâches mises à jour');
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour de toutes les occurrences: $e');
      _setError('Erreur lors de la mise à jour de toutes les occurrences: $e');
      return false;
    }
  }

  // Mettre à jour la tâche de manière asynchrone
  void _updateTaskAsync(Task task) async {
    try {
      await _dbService.updateTask(task);
      await _notificationService.updateTaskNotification(task);
    } catch (e) {
      print('Erreur mise à jour tâche (non bloquant): $e');
    }
  }

  // Supprimer une tâche
  Future<bool> deleteTask(String taskId, {bool deleteAllOccurrences = false}) async {
    try {
      final taskToDelete = _tasks.firstWhere((task) => task.id == taskId);
      
      if (deleteAllOccurrences && taskToDelete.recurrence != TaskRecurrence.none) {
        // Supprimer toutes les occurrences de cette tâche récurrente
        return await _deleteAllRecurringTasks(taskToDelete);
      } else {
        // Supprimer seulement cette occurrence
        _tasks.removeWhere((task) => task.id == taskId);
        _updateTodayTasksSync();
        _updateOverdueTasksSync();
        notifyListeners();
        
        // Supprimer de la base de données en arrière-plan
        _deleteTaskAsync(taskId);
      }

      return true;
    } catch (e) {
      _setError('Erreur lors de la suppression de la tâche: $e');
      return false;
    }
  }

  // Supprimer toutes les occurrences d'une tâche récurrente
  Future<bool> _deleteAllRecurringTasks(Task originalTask) async {
    try {
      // Trouver toutes les occurrences de cette tâche récurrente
      final tasksToDelete = _tasks.where((task) => 
        task.title == originalTask.title &&
        task.recurrence == originalTask.recurrence &&
        task.time == originalTask.time
      ).toList();

      // Supprimer immédiatement de la liste
      for (final task in tasksToDelete) {
        _tasks.removeWhere((t) => t.id == task.id);
        // Supprimer de la base de données en arrière-plan
        _deleteTaskAsync(task.id);
      }

      _updateTodayTasksSync();
      _updateOverdueTasksSync();
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Erreur lors de la suppression de toutes les occurrences: $e');
      return false;
    }
  }

  // Supprimer la tâche de manière asynchrone
  void _deleteTaskAsync(String taskId) async {
    try {
      await _notificationService.cancelTaskNotification(taskId);
      await _dbService.deleteTask(taskId);
    } catch (e) {
      print('Erreur suppression tâche (non bloquant): $e');
    }
  }

  // Marquer une tâche comme terminée
  Future<bool> completeTask(String taskId) async {
    try {
      // Mettre à jour immédiatement dans la liste
      final index = _tasks.indexWhere((task) => task.id == taskId);
      if (index != -1) {
        final completedTask = _tasks[index];
        _tasks[index] = completedTask.copyWith(
          isCompleted: true,
          completedAt: DateTime.now(),
        );
        
        // Si c'est une tâche récurrente, générer automatiquement la prochaine occurrence
        if (completedTask.recurrence != TaskRecurrence.none) {
          _generateNextRecurringTaskAfterCompletion(completedTask);
        }
        
        _updateTodayTasksSync();
        _updateOverdueTasksSync();
        notifyListeners();
      }
      
      // Sauvegarder en base de données en arrière-plan
      _completeTaskAsync(taskId);

      return true;
    } catch (e) {
      _setError('Erreur lors de la completion de la tâche: $e');
      return false;
    }
  }

  // Marquer la tâche comme terminée de manière asynchrone
  void _completeTaskAsync(String taskId) async {
    try {
      await _dbService.completeTask(taskId);
      await _notificationService.cancelTaskNotification(taskId);
    } catch (e) {
      print('Erreur completion tâche (non bloquant): $e');
    }
  }

  // Marquer une tâche comme non terminée
  Future<bool> uncompleteTask(String taskId) async {
    try {
      await _dbService.uncompleteTask(taskId);
      await loadAllTasks();
      
      // Reprogrammer la notification seulement pour les tâches d'aujourd'hui
      final task = _tasks.firstWhere((t) => t.id == taskId);
      if (task.isToday && task.fullDateTime.isAfter(DateTime.now())) {
        await _notificationService.scheduleTaskNotification(task);
      }
      
      return true;
    } catch (e) {
      _setError('Erreur lors de la réactivation de la tâche: $e');
      return false;
    }
  }

  // Basculer le statut d'une tâche
  Future<bool> toggleTaskCompletion(String taskId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    if (task.isCompleted) {
      return await uncompleteTask(taskId);
    } else {
      return await completeTask(taskId);
    }
  }

  // Réinitialiser les tâches quotidiennes
  Future<bool> resetDailyTasks() async {
    try {
      await _dbService.resetDailyTasks();
      await loadAllTasks();
      await _scheduleNotificationsForToday();
      return true;
    } catch (e) {
      _setError('Erreur lors de la réinitialisation: $e');
      return false;
    }
  }

  // Supprimer toutes les tâches terminées
  Future<bool> deleteCompletedTasks() async {
    try {
      await _dbService.deleteCompletedTasks();
      await loadAllTasks();
      return true;
    } catch (e) {
      _setError('Erreur lors de la suppression des tâches terminées: $e');
      return false;
    }
  }

  // Supprimer toutes les tâches
  Future<bool> deleteAllTasks() async {
    try {
      // Étape 1: Vider immédiatement les listes locales
      _tasks.clear();
      _todayTasks.clear();
      _overdueTasks.clear();
      notifyListeners();
      
      // Étape 2: Supprimer toutes les tâches de la base de données
      await _dbService.deleteAllTasks();
      
      // Étape 3: Annuler les notifications (en arrière-plan, non bloquant)
      _cancelNotificationsAsync();
      
      return true;
    } catch (e) {
      _setError('Erreur lors de la suppression de toutes les tâches: $e');
      return false;
    }
  }

  // Annuler les notifications de manière asynchrone (non bloquant)
  void _cancelNotificationsAsync() async {
    try {
      await _notificationService.cancelAllNotifications();
    } catch (e) {
      // Erreur non bloquante pour les notifications
    }
  }

  // Changer la date sélectionnée
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    // Vérifier les tâches récurrentes quand on change de date
    _checkAndGenerateRecurringTasks();
    notifyListeners();
  }

  // Vérifier et générer les tâches récurrentes manquantes
  void _checkAndGenerateRecurringTasks() {
    _generateRecurringTasksIfNeeded();
    _updateTodayTasksSync();
    _updateOverdueTasksSync();
  }

  // Obtenir les tâches pour une date spécifique
  List<Task> getTasksForDate(DateTime date) {
    return _tasks.where((task) {
      return task.date.year == date.year &&
             task.date.month == date.month &&
             task.date.day == date.day;
    }).toList()..sort((a, b) => a.fullDateTime.compareTo(b.fullDateTime));
  }

  // Obtenir les statistiques pour une période
  Future<Map<String, dynamic>> getStatistics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      return await _dbService.getStatistics(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _setError('Erreur lors du chargement des statistiques: $e');
      return {};
    }
  }

  // Obtenir les statistiques quotidiennes pour une période
  Future<List<Map<String, dynamic>>> getDailyStatistics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      return await _dbService.getDailyStatistics(
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _setError('Erreur lors du chargement des statistiques quotidiennes: $e');
      return [];
    }
  }

  // Programmer les notifications pour les tâches d'aujourd'hui
  Future<void> _scheduleNotificationsForToday() async {
    final todayTasks = _tasks.where((task) => 
        task.isToday && !task.isCompleted && task.fullDateTime.isAfter(DateTime.now())
    ).toList();
    
    await _notificationService.scheduleNotificationsForTasks(todayTasks);
  }

  // Nettoyer les notifications obsolètes
  Future<void> cleanupNotifications() async {
    final existingTaskIds = _tasks.map((task) => task.id).toList();
    await _notificationService.cleanupNotifications(existingTaskIds);
  }

  // Nettoyer les doublons manuellement
  Future<void> cleanupDuplicateTasks() async {
    final initialCount = _tasks.length;
    _removeDuplicateTasks();
    
    await _updateTodayTasks();
    await _updateOverdueTasks();
    notifyListeners();
    
    final removedCount = initialCount - _tasks.length;
    if (removedCount > 0) {
      print('$removedCount doublons supprimés manuellement');
    }
  }


  // Obtenir le résumé de la journée
  String getTodaySummary() {
    if (_todayTasks.isEmpty) {
      return 'Aucune tâche prévue aujourd\'hui'; // Fallback pour compatibilité
    }
    
    final completed = todayCompletedTasks;
    final total = _todayTasks.length;
    
    if (completed == total) {
      return '🎉 Toutes les tâches sont terminées !'; // Fallback pour compatibilité
    } else if (completed == 0) {
      return '📋 $total tâche${total > 1 ? 's' : ''} en attente'; // Fallback pour compatibilité
    } else {
      return '✅ $completed/$total tâches terminées'; // Fallback pour compatibilité
    }
  }

  // Obtenir le résumé de la journée avec traduction
  String getTodaySummaryTranslated(BuildContext context) {
    if (_todayTasks.isEmpty) {
      return TranslationService.getTranslation(context, 'noTasksTodayMessage');
    }
    
    final completed = todayCompletedTasks;
    final total = _todayTasks.length;
    
    if (completed == total) {
      return TranslationService.getTranslation(context, 'allTasksCompleted');
    } else if (completed == 0) {
      // Gestion intelligente des pluriels selon la langue
      final locale = Localizations.localeOf(context);
      
      if (locale.languageCode == 'fr') {
        final plural = total > 1 ? 's' : '';
        return TranslationService.getTranslation(context, 'tasksPending')
            .replaceAll('{count}', total.toString())
            .replaceAll('{plural}', plural);
      } else {
        // Pour l'anglais et l'arabe, utiliser la clé appropriée selon le nombre
        final key = total == 1 ? 'tasksPendingSingular' : 'tasksPending';
        return TranslationService.getTranslation(context, key)
            .replaceAll('{count}', total.toString())
            .replaceAll('{plural}', ''); // Pas utilisé dans les autres langues
      }
    } else {
      return TranslationService.getTranslation(context, 'tasksCompletedCount')
          .replaceAll('{completed}', completed.toString())
          .replaceAll('{total}', total.toString());
    }
  }

  // Obtenir le message de motivation
  String getMotivationalMessage() {
    final percentage = todayCompletionPercentage;
    
    if (percentage == 100) {
      return 'Excellent travail ! Vous avez terminé toutes vos tâches ! 🎉'; // Fallback pour compatibilité
    } else if (percentage >= 75) {
      return 'Vous êtes sur la bonne voie ! Continuez comme ça ! 💪'; // Fallback pour compatibilité
    } else if (percentage >= 50) {
      return 'Bon début ! Il reste encore quelques tâches à accomplir.'; // Fallback pour compatibilité
    } else if (percentage > 0) {
      return 'Chaque petit pas compte ! Vous pouvez y arriver ! 🌟'; // Fallback pour compatibilité
    } else {
      return 'Il est temps de commencer ! Vous avez tout ce qu\'il faut pour réussir ! 🚀'; // Fallback pour compatibilité
    }
  }

  // Obtenir le message de motivation avec traduction
  String getMotivationalMessageTranslated(BuildContext context) {
    final percentage = todayCompletionPercentage;
    
    if (percentage == 100) {
      return TranslationService.getTranslation(context, 'excellentWork');
    } else if (percentage >= 75) {
      return TranslationService.getTranslation(context, 'onRightTrack');
    } else if (percentage >= 50) {
      return TranslationService.getTranslation(context, 'goodStart');
    } else if (percentage > 0) {
      return TranslationService.getTranslation(context, 'everyStepCounts');
    } else {
      return TranslationService.getTranslation(context, 'timeToStart');
    }
  }

  // Méthodes privées pour la gestion de l'état
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Formater une date pour l'affichage
  String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);
    
    if (taskDate == today) {
      return 'Aujourd\'hui';
    } else if (taskDate == today.add(const Duration(days: 1))) {
      return 'Demain';
    } else if (taskDate == today.subtract(const Duration(days: 1))) {
      return 'Hier';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  // Formater une heure pour l'affichage
  String formatTime(TimeOfDay time) {
    return DateFormat('HH:mm').format(DateTime(2023, 1, 1, time.hour, time.minute));
  }

}
