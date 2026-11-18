import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// جذر التطبيق: عربي وRTL. مفيش أي اعتماد على Firebase هنا عشان
/// يفضل قابل للاختبار من غير تهيئة (التهيئة في main.dart).
class CenterNetApp extends StatelessWidget {
  const CenterNetApp({super.key});

  static const _locale = Locale('ar');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CenterNet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      locale: _locale,
      supportedLocales: const [_locale],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const Scaffold(body: Center(child: Text('أهلاً بك في CenterNet'))),
    );
  }
}
