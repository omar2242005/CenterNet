import 'models/student_link.dart';

/// أسماء مسارات الربط في مكان واحد.
abstract final class LinkRoutes {
  /// شاشة إدخال كود الربط (للطالب وولي الأمر). بياخد `extra: LinkKind`.
  static const String enter = '/link/enter';

  /// طلب ربط للأدمن (للطالب وولي الأمر). بياخد `extra: LinkKind`.
  static const String request = '/link/request';

  /// (أدمن) طلبات الربط المعلّقة.
  static const String requests = '/link/requests';
}

/// نوع الربط المطلوب لو الـ extra مش مبعوت (الافتراضي ولي الأمر).
LinkKind linkKindFromExtra(Object? extra) =>
    extra is LinkKind ? extra : LinkKind.guardian;
