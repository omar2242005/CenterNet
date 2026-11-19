import 'package:flutter/widgets.dart';

/// المسافات والأنصاف والأحجام الثابتة.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;

  /// أقل حجم لمس مسموح (dp).
  static const double minTouch = 48;

  /// حواف الشاشة.
  static const EdgeInsets screenPadding = EdgeInsets.all(md);
}
