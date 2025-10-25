import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'category.dart';

class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime date;
  final TimeOfDay time;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool notificationsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final String? customSoundUri;
  final TaskRecurrence recurrence;
  final String? categoryId;

  Task({
    String? id,
    required this.title,
    this.description,
    required this.date,
    required this.time,
    this.isCompleted = false,
    DateTime? createdAt,
    this.completedAt,
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = false,
    this.customSoundUri,
    this.recurrence = TaskRecurrence.none,
    this.categoryId,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  // Convertir Task en Map pour la base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'hour': time.hour,
      'minute': time.minute,
      'isCompleted': isCompleted ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'notificationsEnabled': notificationsEnabled ? 1 : 0,
      'soundEnabled': soundEnabled ? 1 : 0,
      'vibrationEnabled': vibrationEnabled ? 1 : 0,
      'customSoundUri': customSoundUri,
      'recurrence': recurrence.name,
      'categoryId': categoryId,
    };
  }

  // Créer une Task à partir d'un Map de la base de données
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      date: DateTime.parse(map['date']),
      time: TimeOfDay(hour: map['hour'], minute: map['minute']),
      isCompleted: map['isCompleted'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      completedAt: map['completedAt'] != null 
          ? DateTime.parse(map['completedAt']) 
          : null,
      notificationsEnabled: map['notificationsEnabled'] == 1,
      soundEnabled: map['soundEnabled'] == 1,
      vibrationEnabled: map['vibrationEnabled'] == 1,
      customSoundUri: map['customSoundUri'],
      recurrence: TaskRecurrence.values.firstWhere(
        (e) => e.name == map['recurrence'],
        orElse: () => TaskRecurrence.none,
      ),
      categoryId: map['categoryId'],
    );
  }

  // Créer une copie de la Task avec des modifications
  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    TimeOfDay? time,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    String? customSoundUri,
    TaskRecurrence? recurrence,
    String? categoryId,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      customSoundUri: customSoundUri ?? this.customSoundUri,
      recurrence: recurrence ?? this.recurrence,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  // Obtenir la DateTime complète (date + heure)
  DateTime get fullDateTime {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  // Vérifier si la tâche est pour aujourd'hui
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }

  // Vérifier si la tâche est en retard
  bool get isOverdue {
    if (isCompleted) return false;
    return fullDateTime.isBefore(DateTime.now());
  }

  // Obtenir le statut de la tâche
  TaskStatus get status {
    if (isCompleted) return TaskStatus.completed;
    if (isOverdue) return TaskStatus.overdue;
    return TaskStatus.pending;
  }

  @override
  String toString() {
    return 'Task{id: $id, title: $title, date: $date, time: $time, isCompleted: $isCompleted}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum TaskStatus {
  pending,
  completed,
  overdue,
}

enum TaskRecurrence {
  none,
  daily,
  weekly,
  monthly,
  yearly,
}

extension TaskStatusExtension on TaskStatus {
  String get displayName {
    switch (this) {
      case TaskStatus.pending:
        return 'En attente';
      case TaskStatus.completed:
        return 'Terminée';
      case TaskStatus.overdue:
        return 'En retard';
    }
  }
}

extension TaskRecurrenceExtension on TaskRecurrence {
  String get displayName {
    switch (this) {
      case TaskRecurrence.none:
        return 'Aucune répétition';
      case TaskRecurrence.daily:
        return 'Quotidien';
      case TaskRecurrence.weekly:
        return 'Hebdomadaire';
      case TaskRecurrence.monthly:
        return 'Mensuel';
      case TaskRecurrence.yearly:
        return 'Annuel';
    }
  }

  String get shortDisplayName {
    switch (this) {
      case TaskRecurrence.none:
        return 'Aucune';
      case TaskRecurrence.daily:
        return 'Jour';
      case TaskRecurrence.weekly:
        return 'Semaine';
      case TaskRecurrence.monthly:
        return 'Mois';
      case TaskRecurrence.yearly:
        return 'An';
    }
  }

  /// Calcule la prochaine date de répétition basée sur la date actuelle
  DateTime getNextDate(DateTime currentDate) {
    switch (this) {
      case TaskRecurrence.none:
        return currentDate;
      case TaskRecurrence.daily:
        return currentDate.add(const Duration(days: 1));
      case TaskRecurrence.weekly:
        return currentDate.add(const Duration(days: 7));
      case TaskRecurrence.monthly:
        // Gérer les mois avec différents nombres de jours
        int nextMonth = currentDate.month + 1;
        int nextYear = currentDate.year;
        if (nextMonth > 12) {
          nextMonth = 1;
          nextYear++;
        }
        
        // Ajuster le jour si la prochaine date n'existe pas (ex: 31 janvier -> 28/29 février)
        int day = currentDate.day;
        try {
          return DateTime(nextYear, nextMonth, day);
        } catch (e) {
          // Si le jour n'existe pas dans le mois suivant, prendre le dernier jour du mois
          return DateTime(nextYear, nextMonth + 1, 0);
        }
      case TaskRecurrence.yearly:
        try {
          return DateTime(currentDate.year + 1, currentDate.month, currentDate.day);
        } catch (e) {
          // Gérer le cas du 29 février (années non bissextiles)
          return DateTime(currentDate.year + 1, currentDate.month, currentDate.day - 1);
        }
    }
  }

  /// Génère les prochaines dates de répétition (limitée à un an ou 52 occurrences)
  List<DateTime> generateNextDates(DateTime startDate, {int maxCount = 52}) {
    if (this == TaskRecurrence.none) {
      return [startDate];
    }

    List<DateTime> dates = [];
    DateTime currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    
    for (int i = 0; i < maxCount; i++) {
      currentDate = getNextDate(currentDate);
      // Limiter à un an dans le futur pour éviter trop d'occurrences
      if (currentDate.isAfter(DateTime.now().add(const Duration(days: 365)))) {
        break;
      }
      dates.add(currentDate);
    }
    
    return dates;
  }
}
