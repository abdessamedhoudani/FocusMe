import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/task.dart';

// Callback global pour les notifications en arrière-plan - Simplifié
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) async {
  print('=== CALLBACK ARRIÈRE-PLAN DÉCLENCHÉ ===');
  final payload = notificationResponse.payload;
  print('Payload reçu: $payload');
  
  if (payload != null) {
    // Traitement simple - notification avec payload
    print('Notification traitée avec payload: $payload');
  }
  print('=== FIN CALLBACK ARRIÈRE-PLAN ===');
}


class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  Future<void>? _initializationFuture;

  // Initialiser le service de notifications
  Future<void> initialize() async {
    if (_isInitialized) {
      print('NotificationService déjà initialisé');
      return;
    }

    // Si une initialisation est déjà en cours, attendre qu'elle se termine
    if (_initializationFuture != null) {
      print('Initialisation déjà en cours, attente...');
      try {
        await _initializationFuture;
        print('Attente de l\'initialisation terminée');
        return;
      } catch (e) {
        print('Erreur lors de l\'attente de l\'initialisation: $e');
        // Réinitialiser le future en cas d'erreur
        _initializationFuture = null;
      }
    }

    print('Démarrage de l\'initialisation...');
    _initializationFuture = _performInitialization();

    // Ajouter un timeout pour éviter les blocages
    try {
      await _initializationFuture?.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Timeout lors de l\'initialisation des notifications');
          _isInitialized =
              true; // Marquer comme initialisé même en cas de timeout
          throw TimeoutException(
            'Initialisation timeout',
            const Duration(seconds: 10),
          );
        },
      );
    } catch (e) {
      print('Erreur ou timeout lors de l\'initialisation: $e');
      _isInitialized =
          true; // Marquer comme initialisé pour éviter les blocages futurs
      _initializationFuture = null;
    }
  }

  Future<void> _performInitialization() async {
    print('=== INITIALISATION NOTIFICATION SERVICE ===');

    try {
      // Initialiser les timezones
      print('Initialisation des timezones...');
      tz.initializeTimeZones();
      print('Timezones initialisées');

      // Configuration Android avec support arrière-plan
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // Configuration iOS
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
            requestCriticalPermission: true, // Pour les notifications critiques
          );

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      print('Configuration des notifications créée');

      print('Initialisation du plugin de notifications...');
      await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );
      print('Plugin de notifications initialisé');

      // Demander les permissions pour Android 13+
      print('Demande des permissions...');
      await requestPermissions();
      print('Permissions demandées');

      // Créer les canaux de notification avec des configurations spécifiques
      print('Création des canaux de notification...');
      await _createNotificationChannels();
      print('Canaux de notification créés');

      _isInitialized = true;
      print('NotificationService initialisé avec succès');
    } catch (e) {
      print('Erreur lors de l\'initialisation des notifications: $e');
      print('Stack trace: ${StackTrace.current}');
      // Continuer même si les notifications échouent
      _isInitialized = true;
    } finally {
      _initializationFuture =
          null; // Réinitialiser pour permettre une nouvelle initialisation si nécessaire
    }

    print('=== FIN INITIALISATION NOTIFICATION SERVICE ===');
  }

  // Créer le canal de notification simplifié
  Future<void> _createNotificationChannels() async {
    try {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        print('=== CRÉATION DU CANAL DE NOTIFICATION ===');
        
        // Un seul canal pour toutes les notifications - Android utilisera le son système par défaut
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'task_reminders_default',
            'Rappels de tâches',
            description: 'Notifications avec son système par défaut',
            importance: Importance.max,
            playSound: true,
            // Pas de son spécifique - Android utilisera le son système par défaut
          ),
        );
        print('Canal créé: task_reminders_default - Son système par défaut');
      }
    } catch (e) {
      print('Erreur lors de la création du canal: $e');
    }
  }

  // Gérer le tap sur une notification - Simplifié
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      print('Notification tapped for task: $payload');
      // Android gère le son système automatiquement
    }
  }


  // Programmer une notification pour une tâche
  Future<void> scheduleTaskNotification(Task task) async {
    if (!_isInitialized) await initialize();

    try {
      print('=== DEBUG NOTIFICATION ===');
      print('Tâche: ${task.title}');
      print('Date/heure: ${task.fullDateTime}');
      print('Maintenant: ${DateTime.now()}');
      print('Notifications activées: ${task.notificationsEnabled}');
      print('Dans le futur: ${task.fullDateTime.isAfter(DateTime.now())}');

      // Annuler toute notification existante pour cette tâche
      await cancelTaskNotification(task.id);

      // Vérifier si les notifications sont activées pour cette tâche
      if (!task.notificationsEnabled) {
        print('Notifications désactivées pour cette tâche: ${task.title}');
        return;
      }

      // Vérifier si la tâche est dans le futur
      if (task.fullDateTime.isBefore(DateTime.now())) {
        print(
          'Tâche dans le passé, notification non programmée: ${task.title}',
        );
        return;
      }

      // Configuration simplifiée - utiliser seulement le son système par défaut
      const String channelId = 'task_reminders_default';
      const String channelName = 'Rappels de tâches';
      const AndroidNotificationCategory category = AndroidNotificationCategory.reminder;
      const dynamic notificationSound = null; // Utiliser le son système par défaut
      
      print('=== CONFIGURATION SIMPLIFIÉE ===');
      print('Son: système par défaut');
      print('Vibration: ${task.vibrationEnabled ? "activée" : "désactivée"}');
      print('=== FIN CONFIGURATION ===');

      // Créer la notification avec les paramètres de la tâche
      final AndroidNotificationDetails
      androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'Notifications pour les rappels de tâches',
        importance: Importance.max, // Importance maximale
        priority: Priority.max, // Priorité maximale
        showWhen: true,
        enableVibration: task.vibrationEnabled,
        playSound: task.soundEnabled, // Utiliser le son système par défaut
        sound: notificationSound, // Son système par défaut
        ongoing: false, // Ne pas rendre la notification persistante
        autoCancel: true, // Permettre à l'utilisateur de fermer la notification
        category: category,
        visibility: NotificationVisibility.public,
        fullScreenIntent:
            true, // Afficher en plein écran pour forcer l'affichage
        usesChronometer: false,
        showProgress: false,
        maxProgress: 0,
        onlyAlertOnce: false, // Permettre plusieurs alertes
        channelShowBadge: true,
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: const BigTextStyleInformation(''),
        // Paramètres pour forcer l'affichage
        ticker: 'Rappel de tâche: ${task.title}',
        when: task.fullDateTime.millisecondsSinceEpoch,
        indeterminate: false,
        actions: [
          const AndroidNotificationAction(
            'complete',
            'Marquer comme terminé',
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            'snooze',
            'Reporter',
            showsUserInterface: true,
          ),
        ],
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

      // Vérifier les permissions avant de programmer
      print('Vérification des permissions...');
      final hasPermission = await requestPermissions();
      print('Permission accordée: $hasPermission');

      // Programmer la notification (fonctionne même si l'app est fermée)
      print('Programmation de la notification...');
      final scheduledTime = tz.TZDateTime.from(task.fullDateTime, tz.local);
      print('Heure programmée (timezone): $scheduledTime');
      
      // Payload simplifié - juste l'ID de la tâche
      final String payload = task.id;
      
      await _notifications.zonedSchedule(
        task.id.hashCode, // Utiliser le hash de l'ID comme ID de notification
        'Rappel de tâche',
        task.title,
        scheduledTime,
        details,
        payload: payload,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        androidScheduleMode: AndroidScheduleMode
            .exactAllowWhileIdle, // Mode exact même en veille
      );

      print('Notification programmée avec succès !');
      print('ID de notification: ${task.id.hashCode}');
      print('Heure programmée: ${task.fullDateTime}');
      print('Heure actuelle: ${DateTime.now()}');
      print('Différence en minutes: ${task.fullDateTime.difference(DateTime.now()).inMinutes}');

      // Vérifier que la notification est bien programmée
      final pendingNotifications = await getPendingNotifications();
      print('Notifications en attente totales: ${pendingNotifications.length}');
      
      try {
        final ourNotification = pendingNotifications.firstWhere(
          (n) => n.id == task.id.hashCode,
        );
        print('Notre notification trouvée avec payload: ${ourNotification.payload}');
      } catch (e) {
        print('Notification pas encore visible dans la liste (normal): $e');
        // C'est normal que la notification ne soit pas immédiatement visible
      }

      print(
        'Notification programmée pour: ${task.title} à ${task.fullDateTime}',
      );
      print('=== FIN DEBUG NOTIFICATION ===');
    } catch (e) {
      print('Erreur lors de la programmation de la notification: $e');
      print('=== FIN DEBUG NOTIFICATION (ERREUR) ===');
      // Continuer même si la notification échoue
    }
  }

  // Annuler une notification pour une tâche
  Future<void> cancelTaskNotification(String taskId) async {
    if (!_isInitialized) await initialize();
    await _notifications.cancel(taskId.hashCode);
  }

  // Annuler toutes les notifications
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) await initialize();
    await _notifications.cancelAll();
  }

  // Programmer des notifications pour toutes les tâches d'une liste
  Future<void> scheduleNotificationsForTasks(List<Task> tasks) async {
    for (final task in tasks) {
      if (!task.isCompleted && task.fullDateTime.isAfter(DateTime.now())) {
        await scheduleTaskNotification(task);
      }
    }
  }

  // Mettre à jour les notifications après modification d'une tâche
  Future<void> updateTaskNotification(Task task) async {
    if (task.isCompleted) {
      // Si la tâche est terminée, annuler la notification
      await cancelTaskNotification(task.id);
    } else {
      // Sinon, reprogrammer la notification
      await scheduleTaskNotification(task);
    }
  }

  // Obtenir les notifications programmées
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_isInitialized) await initialize();
    return await _notifications.pendingNotificationRequests();
  }

  // Vérifier les permissions (Android)
  Future<bool> requestPermissions() async {
    if (!_isInitialized) await initialize();

    try {
      print('Demande des permissions de notification...');
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin == null) {
        print('Plugin Android non disponible');
        return false;
      }

      // Vérifier si les permissions sont déjà accordées
      final bool? granted = await androidPlugin.areNotificationsEnabled();
      print('Notifications déjà activées: $granted');

      if (granted == true) {
        print('Permissions déjà accordées');
        return true;
      }

      // Demander les permissions
      final result = await androidPlugin.requestNotificationsPermission();
      print('Résultat de la demande de permission: $result');
      
      return result ?? false;
    } catch (e) {
      print('Erreur lors de la demande de permissions: $e');
      return false;
    }
  }

  // Afficher une notification immédiate (pour les tests)
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    print('=== SHOW IMMEDIATE NOTIFICATION ===');
    print('Titre: $title');
    print('Body: $body');
    print('Payload: $payload');
    print('Initialisé: $_isInitialized');

    // S'assurer que le service est initialisé
    if (!_isInitialized) {
      print('Service non initialisé, initialisation...');
      await initialize();
    }

    // Attendre un peu pour s'assurer que l'initialisation est complète
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'immediate_notifications',
            'Notifications immédiates',
            channelDescription: 'Notifications affichées immédiatement',
            importance: Importance.high,
            priority: Priority.high,
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

      print('Détails de notification créés');
      print('Envoi de la notification...');

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
        payload: payload,
      );

      print('Notification envoyée avec succès !');
    } catch (e) {
      print('Erreur lors de l\'envoi de la notification: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }

    print('=== FIN SHOW IMMEDIATE NOTIFICATION ===');
  }

  // Nettoyer les notifications pour les tâches supprimées
  Future<void> cleanupNotifications(List<String> existingTaskIds) async {
    final pendingNotifications = await getPendingNotifications();

    for (final notification in pendingNotifications) {
      if (!existingTaskIds.contains(notification.payload)) {
        await _notifications.cancel(notification.id);
      }
    }
  }

  // Vérifier les notifications programmées
  Future<void> checkScheduledNotifications() async {
    try {
      final pendingNotifications = await getPendingNotifications();
      print('=== NOTIFICATIONS PROGRAMMÉES ===');
      print(
        'Nombre de notifications programmées: ${pendingNotifications.length}',
      );

      for (final notification in pendingNotifications) {
        print('ID: ${notification.id}, Payload: ${notification.payload}');
      }
      print('=== FIN NOTIFICATIONS PROGRAMMÉES ===');
    } catch (e) {
      print('Erreur lors de la vérification des notifications: $e');
    }
  }

  // Programmer une notification de test dans 30 secondes
  Future<void> scheduleTestNotification() async {
    try {
      print('=== PROGRAMMATION NOTIFICATION DE TEST ===');

      final testTime = DateTime.now().add(const Duration(seconds: 30));
      print('Notification de test programmée pour: $testTime');

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'test_notifications',
            'Notifications de test',
            channelDescription:
                'Notifications de test pour vérifier le système',
            importance: Importance.max,
            priority: Priority.max,
            showWhen: true,
            enableVibration: true,
            playSound: true,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.reminder,
            visibility: NotificationVisibility.public,
            channelShowBadge: true,
            icon: '@mipmap/ic_launcher',
            largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            styleInformation: BigTextStyleInformation(''),
            ticker: 'Test de notification FocusMe',
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
        999999, // ID unique pour le test
        'Test FocusMe',
        'Cette notification de test confirme que le système fonctionne !',
        tz.TZDateTime.from(testTime, tz.local),
        details,
        payload: 'test_notification',
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      print('Notification de test programmée avec succès !');
      print('=== FIN PROGRAMMATION NOTIFICATION DE TEST ===');
    } catch (e) {
      print('Erreur lors de la programmation de la notification de test: $e');
    }
  }

}
