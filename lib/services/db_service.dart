import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';

class DatabaseService {
  static const String _tasksBoxName = 'tasks';
  static const String _settingsBoxName = 'settings';
  
  static Box<Task>? _tasksBox;
  static Box<dynamic>? _settingsBox;

  // Initialisation de Hive
  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Enregistrer les adaptateurs
    Hive.registerAdapter(TaskAdapter());
    
    // Ouvrir les boîtes
    _tasksBox = await Hive.openBox<Task>(_tasksBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }

  // Gestion des tâches
  static Future<void> addTask(Task task) async {
    await _tasksBox?.put(task.id, task);
  }

  static Future<void> updateTask(Task task) async {
    await _tasksBox?.put(task.id, task);
  }

  static Future<void> deleteTask(String taskId) async {
    await _tasksBox?.delete(taskId);
  }

  static Task? getTask(String taskId) {
    return _tasksBox?.get(taskId);
  }

  static List<Task> getAllTasks() {
    return _tasksBox?.values.toList() ?? [];
  }

  static List<Task> getTasksForDate(DateTime date) {
    final allTasks = getAllTasks();
    return allTasks.where((task) {
      return task.date.year == date.year &&
          task.date.month == date.month &&
          task.date.day == date.day;
    }).toList();
  }

  static List<Task> getTodayTasks() {
    return getTasksForDate(DateTime.now());
  }

  static List<Task> getCompletedTasks() {
    return getAllTasks().where((task) => task.isCompleted).toList();
  }

  static List<Task> getPendingTasks() {
    return getAllTasks().where((task) => !task.isCompleted).toList();
  }

  // Statistiques
  static Map<DateTime, int> getTasksCompletedByDate(DateTime startDate, DateTime endDate) {
    final completedTasks = getCompletedTasks();
    final Map<DateTime, int> stats = {};

    for (var task in completedTasks) {
      if (task.completedAt != null) {
        final completedDate = DateTime(
          task.completedAt!.year,
          task.completedAt!.month,
          task.completedAt!.day,
        );
        
        if (completedDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
            completedDate.isBefore(endDate.add(const Duration(days: 1)))) {
          stats[completedDate] = (stats[completedDate] ?? 0) + 1;
        }
      }
    }

    return stats;
  }

  static int getTotalTasksCompleted() {
    return getCompletedTasks().length;
  }

  static int getTotalTasksCreated() {
    return getAllTasks().length;
  }

  // Réinitialisation quotidienne
  static Future<void> resetDailyTasks() async {
    final today = DateTime.now();
    final todayTasks = getTasksForDate(today);
    
    for (var task in todayTasks) {
      if (task.isCompleted) {
        final updatedTask = task.copyWith(
          isCompleted: false,
          completedAt: null,
        );
        await updateTask(updatedTask);
      }
    }
  }

  // Tâches d'exemple
  static Future<void> addSampleTasks() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final sampleTasks = [
      Task(
        id: 'sample_1',
        title: 'Réveil matinal',
        description: 'Se lever à 7h00 pour commencer la journée',
        date: today,
        time: DateTime(today.year, today.month, today.day, 7, 0),
        createdAt: now,
      ),
      Task(
        id: 'sample_2',
        title: 'Petit-déjeuner',
        description: 'Prendre un petit-déjeuner équilibré',
        date: today,
        time: DateTime(today.year, today.month, today.day, 8, 0),
        createdAt: now,
      ),
      Task(
        id: 'sample_3',
        title: 'Exercice physique',
        description: '30 minutes de sport ou de marche',
        date: today,
        time: DateTime(today.year, today.month, today.day, 9, 0),
        createdAt: now,
      ),
      Task(
        id: 'sample_4',
        title: 'Travail/Études',
        description: 'Se concentrer sur les tâches importantes',
        date: today,
        time: DateTime(today.year, today.month, today.day, 10, 0),
        createdAt: now,
      ),
      Task(
        id: 'sample_5',
        title: 'Pause déjeuner',
        description: 'Prendre une pause pour déjeuner',
        date: today,
        time: DateTime(today.year, today.month, today.day, 12, 30),
        createdAt: now,
      ),
    ];

    for (var task in sampleTasks) {
      await addTask(task);
    }
  }

  // Nettoyage des anciennes tâches (plus de 30 jours)
  static Future<void> cleanupOldTasks() async {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
    final allTasks = getAllTasks();
    
    for (var task in allTasks) {
      if (task.date.isBefore(cutoffDate)) {
        await deleteTask(task.id);
      }
    }
  }

  // Fermeture des boîtes
  static Future<void> close() async {
    await _tasksBox?.close();
    await _settingsBox?.close();
  }
}
