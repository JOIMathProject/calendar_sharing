import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationService {

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> init() async {
    // Request permission
    await _fcm.requestPermission();

    // Get the token
    String? token = await _fcm.getToken();
    print("FCM Token: $token");

    // Handle foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Foreground message received: ${message.notification?.title} - ${message.notification?.body}");
    });

    // Handle background/terminated state notifications
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Notification clicked: ${message.notification?.title} - ${message.notification?.body}");
    });

    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      print("App opened by notification: ${initialMessage.notification?.title} - ${initialMessage.notification?.body}");
    }
  }
}

