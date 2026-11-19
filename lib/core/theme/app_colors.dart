import 'package:flutter/material.dart';

/// ألوان التطبيق (من الملف الشامل). ممنوع تكتب لون مباشرة في أي widget،
/// استخدم الثوابت دي أو `Theme.of(context)`.
abstract final class AppColors {
  // الأساسية
  static const Color primary = Color(0xFF2563EB);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color background = Color(0xFFF8FAFC);

  // السطوح والنصوص
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color border = Color(0xFFE2E8F0);

  // خلفيات فاتحة ونصوص غامقة للشارات (تباين مقروء)
  static const Color primaryContainer = Color(0xFFDBEAFE);
  static const Color onPrimaryContainer = Color(0xFF1E3A8A);
  static const Color successContainer = Color(0xFFDCFCE7);
  static const Color onSuccessContainer = Color(0xFF14532D);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color onWarningContainer = Color(0xFF78350F);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onErrorContainer = Color(0xFF7F1D1D);
  static const Color neutralContainer = Color(0xFFE2E8F0);
  static const Color onNeutralContainer = Color(0xFF334155);
}
