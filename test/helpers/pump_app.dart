import 'package:center_net/core/theme/app_theme.dart';
import 'package:center_net/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// يشغّل [child] جوه تطبيق عربي RTL بالثيم الحقيقي وملف الـ arb.
extension PumpApp on WidgetTester {
  Future<void> pumpApp(Widget child) {
    return pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(body: child),
      ),
    );
  }
}

/// نصوص arb للاختبارات (من غير widget).
AppLocalizations get arL10n => lookupAppLocalizations(const Locale('ar'));
