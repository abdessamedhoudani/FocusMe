import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../models/task.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Initialisation du service de notifications
  static Future<void> init() async {
    // Initialiser timezone
    tz.initializeTimeZones();
    
    // Configuration Android
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuration iOS
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Demander les permissions
    await _requestPermissions();
  }

  // Demander les permissions nécessaires
  static Future<void> _requestPermissions() async {
    // Permission pour les notifications
    await Permission.notification.request();
    
    // Permission pour les notifications exactes (Android 12+)
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
  }

  // Programmer une notification pour une tâche
  static Future<void> scheduleTaskNotification(Task task) async {
    if (!task.notificationEnabled) return;

    final notificationId = task.id.hashCode;
    final scheduledDate = tz.TZDateTime.from(task.dateTime, tz.local);

    // Vérifier que la date n'est pas dans le passé
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      return;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'task_reminders',
      'Rappels de tâches',
      channelDescription: 'Notifications pour les rappels de tâches',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF2196F3),
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      notificationId,
      'FocusMe - Rappel de tâche',
      task.title,
      scheduledDate,
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: task.id,
    );
  }

  // Annuler une notification
  static Future<void> cancelTaskNotification(String taskId) async {
    final notificationId = taskId.hashCode;
    await _notifications.cancel(notificationId);
  }

  // Annuler toutes les notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Programmer toutes les notifications pour les tâches d'aujourd'hui
  static Future<void> scheduleTodayNotifications(List<Task> tasks) async {
    await cancelAllNotifications();
    
    for (var task in tasks) {
      if (task.notificationEnabled && !task.isCompleted) {
        await scheduleTaskNotification(task);
      }
    }
  }

  // Gestion du clic sur une notification
  static void _onNotificationTapped(NotificationResponse response) {
    final taskId = response.payload;
    if (taskId != null) {
      // Ici, vous pouvez naviguer vers la tâche spécifique
      // Cette logique sera gérée par le ViewModel
      print('Notification tapped for task: $taskId');
    }
  }

  // Afficher une notification immédiate (pour les tests)
  static Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'immediate_notifications',
      'Notifications immédiates',
      channelDescription: 'Notifications affichées immédiatement',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Vérifier si les notifications sont activées
  static Future<bool> areNotificationsEnabled() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  // Obtenir les notifications en attente
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // Programmer une notification de réinitialisation quotidienne
  static Future<void> scheduleDailyResetNotification() async {
    // Programmer à minuit chaque jour
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final scheduledDate = tz.TZDateTime.from(tomorrow, tz.local);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'daily_reset',
      'Réinitialisation quotidienne',
      channelDescription: 'Notification de réinitialisation des tâches quotidiennes',
      importance: Importance.low,
      priority: Priority.low,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: true,
      presentSound: false,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      999999, // ID spécial pour la réinitialisation
      'FocusMe - Nouveau jour',
      'Vos tâches ont été réinitialisées pour aujourd\'hui !',
      scheduledDate,
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
