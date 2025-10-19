import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

      Future<Database> _initDatabase() async {
        String path = join(await getDatabasesPath(), 'focusme.db');
        return await openDatabase(
          path,
          version: 4,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        );
      }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        hour INTEGER NOT NULL,
        minute INTEGER NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        completedAt TEXT,
        notificationsEnabled INTEGER NOT NULL DEFAULT 1,
        soundEnabled INTEGER NOT NULL DEFAULT 1,
        vibrationEnabled INTEGER NOT NULL DEFAULT 0,
        customSoundUri TEXT,
        recurrence TEXT NOT NULL DEFAULT 'none'
      )
    ''');

    // Créer un index sur la date pour des requêtes plus rapides
    await db.execute('''
      CREATE INDEX idx_tasks_date ON tasks(date)
    ''');

    // Créer un index sur isCompleted pour filtrer les tâches terminées
    await db.execute('''
      CREATE INDEX idx_tasks_completed ON tasks(isCompleted)
    ''');
  }

  // Migration de la base de données
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Ajouter les nouvelles colonnes pour les notifications
      await db.execute('''
        ALTER TABLE tasks ADD COLUMN notificationsEnabled INTEGER NOT NULL DEFAULT 1
      ''');
      await db.execute('''
        ALTER TABLE tasks ADD COLUMN soundEnabled INTEGER NOT NULL DEFAULT 1
      ''');
      await db.execute('''
        ALTER TABLE tasks ADD COLUMN vibrationEnabled INTEGER NOT NULL DEFAULT 0
      ''');
      await db.execute('''
        ALTER TABLE tasks ADD COLUMN customSoundUri TEXT
      ''');
    }
    
    if (oldVersion < 3) {
      // Ajouter la colonne customSoundUri si elle n'existe pas déjà
      try {
        await db.execute('''
          ALTER TABLE tasks ADD COLUMN customSoundUri TEXT
        ''');
      } catch (e) {
        // La colonne existe déjà, ignorer l'erreur
        print('Colonne customSoundUri déjà présente: $e');
      }
    }
    
    if (oldVersion < 4) {
      // Ajouter la colonne recurrence
      try {
        await db.execute('''
          ALTER TABLE tasks ADD COLUMN recurrence TEXT NOT NULL DEFAULT 'none'
        ''');
      } catch (e) {
        // La colonne existe déjà, ignorer l'erreur
        print('Colonne recurrence déjà présente: $e');
      }
    }
  }

  // Insérer une nouvelle tâche
  Future<String> insertTask(Task task) async {
    final db = await database;
    await db.insert('tasks', task.toMap());
    return task.id;
  }

  // Récupérer toutes les tâches
  Future<List<Task>> getAllTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      orderBy: 'date ASC, hour ASC, minute ASC',
    );

    return List.generate(maps.length, (i) {
      return Task.fromMap(maps[i]);
    });
  }

  // Récupérer les tâches pour une date spécifique
  Future<List<Task>> getTasksForDate(DateTime date) async {
    final db = await database;
    final dateString = DateTime(date.year, date.month, date.day).toIso8601String();
    
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'date LIKE ?',
      whereArgs: ['$dateString%'],
      orderBy: 'hour ASC, minute ASC',
    );

    return List.generate(maps.length, (i) {
      return Task.fromMap(maps[i]);
    });
  }

  // Récupérer les tâches d'aujourd'hui
  Future<List<Task>> getTodayTasks() async {
    return getTasksForDate(DateTime.now());
  }

  // Récupérer les tâches en retard
  Future<List<Task>> getOverdueTasks() async {
    final db = await database;
    final now = DateTime.now();
    final nowString = now.toIso8601String();
    
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'isCompleted = 0 AND (date || "T" || printf("%02d", hour) || ":" || printf("%02d", minute) || ":00") < ?',
      whereArgs: [nowString],
      orderBy: 'date ASC, hour ASC, minute ASC',
    );

    return List.generate(maps.length, (i) {
      return Task.fromMap(maps[i]);
    });
  }

  // Mettre à jour une tâche
  Future<int> updateTask(Task task) async {
    final db = await database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  // Marquer une tâche comme terminée
  Future<int> completeTask(String taskId) async {
    final db = await database;
    return await db.update(
      'tasks',
      {
        'isCompleted': 1,
        'completedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  // Marquer une tâche comme non terminée
  Future<int> uncompleteTask(String taskId) async {
    final db = await database;
    return await db.update(
      'tasks',
      {
        'isCompleted': 0,
        'completedAt': null,
      },
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  // Supprimer une tâche
  Future<int> deleteTask(String taskId) async {
    final db = await database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  // Supprimer toutes les tâches terminées
  Future<int> deleteCompletedTasks() async {
    final db = await database;
    return await db.delete(
      'tasks',
      where: 'isCompleted = 1',
    );
  }

  // Supprimer toutes les tâches
  Future<int> deleteAllTasks() async {
    final db = await database;
    return await db.delete('tasks');
  }

  // Réinitialiser les tâches quotidiennes (marquer comme non terminées)
  Future<int> resetDailyTasks() async {
    final db = await database;
    return await db.update(
      'tasks',
      {
        'isCompleted': 0,
        'completedAt': null,
      },
      where: 'isCompleted = 1',
    );
  }

  // Obtenir les statistiques pour une période
  Future<Map<String, dynamic>> getStatistics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database;
    
    // Normaliser les dates pour inclure toute la journée (00:00:00 à 23:59:59)
    final startDateStr = startDate.toIso8601String().split('T')[0];
    final endDateStr = endDate.toIso8601String().split('T')[0];
    final startDateTimeStr = '${startDateStr}T00:00:00';
    final endDateTimeStr = '${endDateStr}T23:59:59';
    
    // Tâches créées dans la période (basé sur createdAt)
    final createdResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM tasks 
      WHERE DATE(createdAt) >= ? AND DATE(createdAt) <= ?
    ''', [startDateStr, endDateStr]);
    
    // Tâches terminées dans la période (basé sur completedAt)
    final completedResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM tasks 
      WHERE isCompleted = 1 AND completedAt IS NOT NULL 
      AND DATE(completedAt) >= ? AND DATE(completedAt) <= ?
    ''', [startDateStr, endDateStr]);
    
    // Tâches en retard (utiliser la même logique que Task.isOverdue)
    final allTasks = await getAllTasks();
    final overdueCount = allTasks.where((task) => task.isOverdue).length;

    return {
      'totalCreated': createdResult.first['count'] as int,
      'totalCompleted': completedResult.first['count'] as int,
      'totalOverdue': overdueCount,
    };
  }

  // Obtenir les statistiques par jour pour une période
  Future<List<Map<String, dynamic>>> getDailyStatistics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database;
    
    // Normaliser les dates pour inclure toute la journée
    final startDateStr = startDate.toIso8601String().split('T')[0];
    final endDateStr = endDate.toIso8601String().split('T')[0];
    
    final result = await db.rawQuery('''
      SELECT 
        DATE(createdAt) as day,
        COUNT(*) as total,
        SUM(CASE WHEN isCompleted = 1 THEN 1 ELSE 0 END) as completed
      FROM tasks 
      WHERE DATE(createdAt) >= ? AND DATE(createdAt) <= ?
      GROUP BY DATE(createdAt)
      ORDER BY day ASC
    ''', [startDateStr, endDateStr]);

    return result;
  }

  // Fermer la base de données
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // Supprimer la base de données (pour les tests ou la réinitialisation)
  Future<void> deleteDatabase() async {
    final db = await database;
    await db.close();
    String path = join(await getDatabasesPath(), 'focusme.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
