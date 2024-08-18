import 'package:calendar_sharing/screen/wrapper.dart';
import 'package:calendar_sharing/services/UserData.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'setting/color.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/PushNotification.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  PushNotificationService().init();

  final messagingInstance = FirebaseMessaging.instance;
  messagingInstance.requestPermission();
  final fcmToken = await messagingInstance.getToken();
  debugPrint('FCM TOKEN: $fcmToken');

  runApp(
      ChangeNotifierProvider(create: (context) => UserData(),
          child: const MyApp(),
      ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        SfGlobalLocalizations.delegate
      ],
      supportedLocales: [
        const Locale('zh'),
        const Locale('ar'),
        const Locale('ja'),
      ],
      locale: const Locale('ja'),
      theme: appTheme,
      home: Wrapper(),
    );
  }
}