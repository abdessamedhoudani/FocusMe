import 'dart:async';
import 'dart:isolate';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/task.dart';

/// Service pour gérer les notifications en arrière-plan
class BackgroundNotificationService {
  static const String _isolateName = 'background_notification_isolate';
  static const String _portName = 'background_notification_port';

  /// Point d'entrée pour l'isolate en arrière-plan - Simplifié
  @pragma('vm:entry-point')
  static Future<void> backgroundNotificationHandler(NotificationResponse response) async {
    print('=== BACKGROUND NOTIFICATION HANDLER ===');
    print('Notification reçue en arrière-plan: ${response.payload}');
    
    try {
      // Initialiser les timezones dans l'isolate
      tz.initializeTimeZones();
      
      // Traitement simple - Android gère automatiquement les sons système
      final taskId = response.payload;
      if (taskId != null) {
        print('Notification traitée en arrière-plan pour tâche: $taskId');
      }
    } catch (e) {
      print('Erreur dans le handler de notification en arrière-plan: $e');
    }
    
    print('=== FIN BACKGROUND NOTIFICATION HANDLER ===');
  }


  /// Programmer une notification en arrière-plan
  static Future<void> scheduleBackgroundNotification(Task task) async {
    try {
      print('Programmation de notification en arrière-plan pour: ${task.title}');
      
      final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
      
      // Configuration pour les notifications en arrière-plan
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: backgroundNotificationHandler,
      );

      // Configuration simplifiée - utiliser seulement le son système par défaut
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'task_reminders_default',
        'Rappels de tâches',
        channelDescription: 'Notifications avec son système par défaut',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        enableVibration: task.vibrationEnabled,
        playSound: task.soundEnabled,
        sound: null, // Son système par défaut
        ongoing: false,
        autoCancel: true,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        onlyAlertOnce: false,
        channelShowBadge: true,
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      );

      final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: task.soundEnabled,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Programmer la notification
      await notifications.zonedSchedule(
        task.id.hashCode,
        'Rappel de tâche',
        task.title,
        tz.TZDateTime.from(task.fullDateTime, tz.local),
        details,
        payload: task.id,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // Mode exact même en veille
      );

      print('Notification en arrière-plan programmée pour: ${task.title} à ${task.fullDateTime}');
    } catch (e) {
      print('Erreur lors de la programmation de la notification en arrière-plan: $e');
    }
  }
}
