import 'package:calendar_sharing/screen/wrapper.dart';
import 'package:calendar_sharing/services/UserData.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'setting/color.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';

void main() async{
  runApp(
      ChangeNotifierProvider(create: (context) => UserData(),
          child: const MyApp(),
      ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        SfGlobalLocalizations.delegate
      ],
      supportedLocales: [
        const Locale('ja'),
      ],
      locale: const Locale('ja'),
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: Wrapper(),
    );
  }
}