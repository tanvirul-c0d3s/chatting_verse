import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
  FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(
      android: androidSettings,
    );

    await _local.initialize(
      settings: settings,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;

      if (notification != null) {
        await _local.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'chat_messages',
              'Chat Messages',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
  }

  Future<String> getFcmToken() async {
    return await _messaging.getToken() ?? '';
  }
}