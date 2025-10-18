import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

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
