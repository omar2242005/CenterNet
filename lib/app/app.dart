import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'router.dart';

/// جذر التطبيق: عربي وRTL. مفيش أي اعتماد على Firebase هنا عشان
/// يفضل قابل للاختبار من غير تهيئة (التهيئة في main.dart).
class CenterNetApp extends StatefulWidget {
  const CenterNetApp({super.key, this.router});

  /// للاختبار. الافتراضي: الـ router الحقيقي.
  final GoRouter? router;

  @override
  State<CenterNetApp> createState() => _CenterNetAppState();
}

class _CenterNetAppState extends State<CenterNetApp> {
  static const _locale = Locale('ar');

  late final GoRouter _router = widget.router ?? buildRouter();

  @override
  void dispose() {
    if (widget.router == null) _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CenterNet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      locale: _locale,
      supportedLocales: const [_locale],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: _router,
    );
  }
}
