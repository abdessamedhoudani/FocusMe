import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  DateTime time;

  @HiveField(5)
  bool isCompleted;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime? completedAt;

  @HiveField(8)
  bool notificationEnabled;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    required this.time,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
    this.notificationEnabled = true,
  });

  // Méthode pour obtenir la date et l'heure combinées
  DateTime get dateTime => DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

  // Méthode pour vérifier si la tâche est pour aujourd'hui
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // Méthode pour vérifier si la tâche est en retard
  bool get isOverdue {
    if (isCompleted) return false;
    return dateTime.isBefore(DateTime.now());
  }

  // Méthode pour marquer la tâche comme terminée
  void markAsCompleted() {
    isCompleted = true;
    completedAt = DateTime.now();
  }

  // Méthode pour marquer la tâche comme non terminée
  void markAsIncomplete() {
    isCompleted = false;
    completedAt = null;
  }

  // Méthode pour créer une copie de la tâche
  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    DateTime? time,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    bool? notificationEnabled,
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
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
    );
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
