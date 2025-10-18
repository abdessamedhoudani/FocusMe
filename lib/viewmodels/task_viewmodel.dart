import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../services/db_service.dart';
import '../services/notification_service.dart';

class TaskViewModel extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final NotificationService _notificationService = NotificationService();

  List<Task> _tasks = [];
  List<Task> _todayTasks = [];
  List<Task> _overdueTasks = [];
  bool _isLoading = false;
  String? _error;
  DateTime _selectedDate = DateTime.now();

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
      
      // Initialiser les notifications en arrière-plan (non bloquant)
      _initializeNotificationsAsync();
    } catch (e) {
      _setError('Erreur lors de l\'initialisation: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Initialiser les notifications de manière asynchrone
  void _initializeNotificationsAsync() async {
    try {
      await _notificationService.initialize();
      await _scheduleNotificationsForToday();
    } catch (e) {
      print('Erreur notifications (non bloquant): $e');
    }
  }

  // Charger toutes les tâches
  Future<void> loadAllTasks() async {
    try {
      _tasks = await _dbService.getAllTasks();
      await _updateTodayTasks();
      await _updateOverdueTasks();
      _clearError();
    } catch (e) {
      _setError('Erreur lors du chargement des tâches: $e');
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
      );

      // Ajouter immédiatement à l'UI (feedback instantané)
      _tasks.add(task);
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

  // Sauvegarder la tâche de manière asynchrone
  void _saveTaskAsync(Task task) async {
    try {
      await _dbService.insertTask(task);
      
      // Programmer la notification si nécessaire
      if (task.fullDateTime.isAfter(DateTime.now())) {
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
  Future<bool> updateTask(Task task) async {
    try {
      // Mettre à jour immédiatement dans la liste
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
        _updateTodayTasksSync();
        _updateOverdueTasksSync();
        notifyListeners();
      }
      
      // Sauvegarder en base de données en arrière-plan
      _updateTaskAsync(task);

      return true;
    } catch (e) {
      _setError('Erreur lors de la mise à jour de la tâche: $e');
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
  Future<bool> deleteTask(String taskId) async {
    try {
      // Supprimer immédiatement de la liste
      _tasks.removeWhere((task) => task.id == taskId);
      _updateTodayTasksSync();
      _updateOverdueTasksSync();
      notifyListeners();
      
      // Supprimer de la base de données en arrière-plan
      _deleteTaskAsync(taskId);

      return true;
    } catch (e) {
      _setError('Erreur lors de la suppression de la tâche: $e');
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
        _tasks[index] = _tasks[index].copyWith(
          isCompleted: true,
          completedAt: DateTime.now(),
        );
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
      
      // Reprogrammer la notification si nécessaire
      final task = _tasks.firstWhere((t) => t.id == taskId);
      if (task.fullDateTime.isAfter(DateTime.now())) {
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
    notifyListeners();
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


  // Obtenir le résumé de la journée
  String getTodaySummary() {
    if (_todayTasks.isEmpty) {
      return 'Aucune tâche prévue aujourd\'hui';
    }
    
    final completed = todayCompletedTasks;
    final total = _todayTasks.length;
    
    if (completed == total) {
      return '🎉 Toutes les tâches sont terminées !';
    } else if (completed == 0) {
      return '📋 $total tâche${total > 1 ? 's' : ''} en attente';
    } else {
      return '✅ $completed/$total tâches terminées';
    }
  }

  // Obtenir le message de motivation
  String getMotivationalMessage() {
    final percentage = todayCompletionPercentage;
    
    if (percentage == 100) {
      return 'Excellent travail ! Vous avez terminé toutes vos tâches ! 🎉';
    } else if (percentage >= 75) {
      return 'Vous êtes sur la bonne voie ! Continuez comme ça ! 💪';
    } else if (percentage >= 50) {
      return 'Bon début ! Il reste encore quelques tâches à accomplir.';
    } else if (percentage > 0) {
      return 'Chaque petit pas compte ! Vous pouvez y arriver ! 🌟';
    } else {
      return 'Il est temps de commencer ! Vous avez tout ce qu\'il faut pour réussir ! 🚀';
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
