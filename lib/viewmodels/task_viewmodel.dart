import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../services/db_service.dart';
import '../services/notification_service.dart';
import '../services/daily_reset_service.dart';

class TaskViewModel extends ChangeNotifier {
  final List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;
  DateTime _selectedDate = DateTime.now();

  // Getters
  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get selectedDate => _selectedDate;

  List<Task> get todayTasks {
    final today = DateTime.now();
    return _tasks.where((task) {
      return task.date.year == today.year &&
          task.date.month == today.month &&
          task.date.day == today.day;
    }).toList();
  }

  List<Task> get selectedDateTasks {
    return _tasks.where((task) {
      return task.date.year == _selectedDate.year &&
          task.date.month == _selectedDate.month &&
          task.date.day == _selectedDate.day;
    }).toList();
  }

  List<Task> get completedTasks {
    return _tasks.where((task) => task.isCompleted).toList();
  }

  List<Task> get pendingTasks {
    return _tasks.where((task) => !task.isCompleted).toList();
  }

  int get totalTasks => _tasks.length;
  int get completedTasksCount => completedTasks.length;
  int get pendingTasksCount => pendingTasks.length;

  double get completionRate {
    if (_tasks.isEmpty) return 0.0;
    return completedTasksCount / _tasks.length;
  }

  // Initialisation
  Future<void> init() async {
    _setLoading(true);
    try {
      await _loadTasks();
      await DailyResetService.checkAndPerformDailyReset();
      await _scheduleNotifications();
    } catch (e) {
      _setError('Erreur lors de l\'initialisation: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Charger les tâches depuis la base de données
  Future<void> _loadTasks() async {
    try {
      _tasks.clear();
      _tasks.addAll(DatabaseService.getAllTasks());
      _tasks.sort((a, b) => a.time.compareTo(b.time));
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors du chargement des tâches: $e');
    }
  }


  // Programmer les notifications pour les tâches d'aujourd'hui
  Future<void> _scheduleNotifications() async {
    try {
      await NotificationService.scheduleTodayNotifications(todayTasks);
    } catch (e) {
      _setError('Erreur lors de la programmation des notifications: $e');
    }
  }

  // Ajouter une nouvelle tâche
  Future<void> addTask({
    required String title,
    String? description,
    required DateTime date,
    required DateTime time,
    bool notificationEnabled = true,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final task = Task(
        id: const Uuid().v4(),
        title: title,
        description: description,
        date: date,
        time: time,
        createdAt: DateTime.now(),
        notificationEnabled: notificationEnabled,
      );

      await DatabaseService.addTask(task);
      await _loadTasks();
      
      // Programmer la notification si activée
      if (notificationEnabled && task.isToday) {
        await NotificationService.scheduleTaskNotification(task);
      }
    } catch (e) {
      _setError('Erreur lors de l\'ajout de la tâche: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Modifier une tâche existante
  Future<void> updateTask(Task task) async {
    try {
      _setLoading(true);
      _clearError();

      await DatabaseService.updateTask(task);
      await _loadTasks();
      
      // Mettre à jour la notification
      await NotificationService.cancelTaskNotification(task.id);
      if (task.notificationEnabled && task.isToday) {
        await NotificationService.scheduleTaskNotification(task);
      }
    } catch (e) {
      _setError('Erreur lors de la modification de la tâche: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Supprimer une tâche
  Future<void> deleteTask(String taskId) async {
    try {
      _setLoading(true);
      _clearError();

      await NotificationService.cancelTaskNotification(taskId);
      await DatabaseService.deleteTask(taskId);
      await _loadTasks();
    } catch (e) {
      _setError('Erreur lors de la suppression de la tâche: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Marquer une tâche comme terminée
  Future<void> toggleTaskCompletion(String taskId) async {
    try {
      final task = _tasks.firstWhere((t) => t.id == taskId);
      final updatedTask = task.isCompleted
          ? task.copyWith(isCompleted: false, completedAt: null)
          : task.copyWith(isCompleted: true, completedAt: DateTime.now());

      await updateTask(updatedTask);
    } catch (e) {
      _setError('Erreur lors du changement de statut de la tâche: $e');
    }
  }

  // Changer la date sélectionnée
  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  // Obtenir les statistiques pour une période
  Map<DateTime, int> getStatsForPeriod(DateTime startDate, DateTime endDate) {
    return DatabaseService.getTasksCompletedByDate(startDate, endDate);
  }

  // Ajouter des tâches d'exemple
  Future<void> addSampleTasks() async {
    try {
      _setLoading(true);
      _clearError();
      
      await DatabaseService.addSampleTasks();
      await _loadTasks();
      await _scheduleNotifications();
    } catch (e) {
      _setError('Erreur lors de l\'ajout des tâches d\'exemple: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Nettoyer les anciennes tâches
  Future<void> cleanupOldTasks() async {
    try {
      _setLoading(true);
      _clearError();
      
      await DatabaseService.cleanupOldTasks();
      await _loadTasks();
    } catch (e) {
      _setError('Erreur lors du nettoyage: $e');
    } finally {
      _setLoading(false);
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
  }


  // Rafraîchir les données
  Future<void> refresh() async {
    await _loadTasks();
    await _scheduleNotifications();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
