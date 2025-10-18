import 'dart:async';
import 'dart:isolate';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'db_service.dart';
import 'audio_service.dart';
import 'sound_service.dart';
import '../models/task.dart';

/// Service pour gérer les notifications en arrière-plan
class BackgroundNotificationService {
  static const String _isolateName = 'background_notification_isolate';
  static const String _portName = 'background_notification_port';

  /// Point d'entrée pour l'isolate en arrière-plan
  @pragma('vm:entry-point')
  static Future<void> backgroundNotificationHandler(NotificationResponse response) async {
    print('=== BACKGROUND NOTIFICATION HANDLER ===');
    print('Notification reçue en arrière-plan: ${response.payload}');
    
    try {
      // Initialiser les timezones dans l'isolate
      tz.initializeTimeZones();
      
      // Récupérer la tâche depuis la base de données
      final dbService = DatabaseService();
      final tasks = await dbService.getAllTasks();
      final taskId = response.payload;
      
      if (taskId != null) {
        final task = tasks.firstWhere(
          (t) => t.id == taskId,
          orElse: () => throw Exception('Tâche non trouvée'),
        );
        
        // Jouer le son de la tâche
        await _playTaskSoundInBackground(task);
      }
    } catch (e) {
      print('Erreur dans le handler de notification en arrière-plan: $e');
    }
    
    print('=== FIN BACKGROUND NOTIFICATION HANDLER ===');
  }

  /// Jouer le son d'une tâche en arrière-plan
  static Future<void> _playTaskSoundInBackground(Task task) async {
    try {
      print('Lecture du son en arrière-plan pour: ${task.title}');
      
      if (task.soundEnabled) {
        // Avec les sons système, nous n'avons plus besoin de lecture personnalisée 
        // car les notifications Android utilisent directement les sons système
        await AudioService().playDefaultSound();
        print('Son système joué en arrière-plan: ${task.title}');
      } else {
        print('Son désactivé pour la tâche: ${task.title}');
      }
    } catch (e) {
      print('Erreur lors de la lecture du son en arrière-plan: $e');
      await AudioService().playDefaultSound();
    }
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

      // Pour les notifications en arrière-plan, utiliser uniquement les sons système Android
      String? soundUri;
      if (task.soundEnabled) {
        // Utiliser le son système par défaut d'Android
        soundUri = null; // null = son système par défaut
      }

      // Créer la notification
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'background_task_reminders',
        'Rappels de tâches en arrière-plan',
        channelDescription: 'Notifications pour les rappels de tâches même quand l\'app est fermée',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: task.vibrationEnabled,
        playSound: task.soundEnabled,
        sound: soundUri != null ? RawResourceAndroidNotificationSound(soundUri.split('/').last.split('.').first) : null,
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
        sound: soundUri != null ? soundUri.split('/').last : null,
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
