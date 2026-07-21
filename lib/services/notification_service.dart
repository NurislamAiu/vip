import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/constants/app_constants.dart';

/// Background/terminated FCM handler. Must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Nothing heavy here: the system tray already shows the notification. This
  // hook exists so background delivery is registered.
}

/// Wires up Firebase Cloud Messaging and mirrors foreground pushes into the
/// system tray via local notifications.
///
/// The scheduled reminders described in the spec (2h-before-arrival,
/// 30min-before-appointment, departure-today) are produced server-side by a
/// scheduled Cloud Function that queries Firestore and sends to the [staff]
/// topic; the client only needs to be subscribed and able to display them.
class NotificationService {
  NotificationService();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'vip_clients',
    'Client updates',
    description: 'Arrivals, appointments, departures and client changes.',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    // Messaging is best-effort: a failure here (permissions, no APNS token on
    // the iOS simulator, offline, …) must never crash the app.
    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);

      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await _local.initialize(initSettings);

      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      // Show the notification tray entry even for foreground iOS messages.
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen(_showForeground);

      // On Apple platforms FCM cannot mint a token or subscribe to a topic
      // until the APNS token is available. On the simulator it may never
      // arrive, so wait briefly and bail out gracefully if it doesn't.
      final isApple = !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.macOS);
      if (isApple && await _waitForApnsToken() == null) {
        debugPrint(
          'APNS token unavailable (likely an iOS simulator); skipping FCM '
          'token and topic subscription.',
        );
        return;
      }

      await _messaging.subscribeToTopic(AppConstants.staffTopic).catchError((_) {
        // Topic subscription is best-effort; ignore transient failures.
      });

      if (kDebugMode) {
        final token = await _messaging.getToken();
        debugPrint('FCM token: $token');
      }
    } catch (e) {
      debugPrint('NotificationService.initialize skipped: $e');
    }
  }

  /// Polls for the APNS token for a few seconds. Returns it once available, or
  /// `null` if it never arrives (e.g. push-less simulators).
  Future<String?> _waitForApnsToken() async {
    for (var attempt = 0; attempt < 3; attempt++) {
      final token = await _messaging.getAPNSToken();
      if (token != null) return token;
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    return _messaging.getAPNSToken();
  }

  void _showForeground(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
