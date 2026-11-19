import 'package:flutter/foundation.dart';

/// حارس "مفيش خروج مع عمليات معلّقة".
///
/// B (صاحب قائمة المسحات المحلية) بيحدّث [pending] كل ما القائمة تتغير.
/// شاشة "حسابي" (A) بتسأل [canLeave] قبل تسجيل الخروج أو حذف الحساب،
/// وبتعرض [blockReason] لو ممنوع.
class PendingOpsGuard {
  final ValueNotifier<int> pending = ValueNotifier<int>(0);

  bool get canLeave => pending.value == 0;

  void setPending(int count) {
    if (count < 0) {
      throw ArgumentError.value(count, 'count', 'مينفعش يكون سالب');
    }
    pending.value = count;
  }

  /// null لو الخروج مسموح، وإلا رسالة عربية جاهزة للعرض.
  String? get blockReason => canLeave
      ? null
      : 'عندك ${pending.value} عملية بانتظار المزامنة. '
          'انتظر لحد ما تخلص قبل الخروج من الحساب.';

  void dispose() => pending.dispose();
}
