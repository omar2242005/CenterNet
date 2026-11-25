import '../../sessions/models/session.dart';

/// وضع الحصة بالنسبة للوقت الحالي (للعرض في قايمة الحصص).
enum SessionTimeStatus {
  /// لسه هتبدأ.
  upcoming,

  /// شغّالة دلوقتي (بدأت وما خلصتش).
  current,

  /// خلصت.
  ended,

  /// ملغاة (بتتعرض بس مش بتتفتح للمسح).
  cancelled,
}

/// دالة نقية بتتحسب من [Session] والوقت الحالي (سهلة الاختبار).
SessionTimeStatus sessionTimeStatus(Session session, DateTime now) {
  if (session.isCancelled) return SessionTimeStatus.cancelled;
  if (now.isBefore(session.startAt)) return SessionTimeStatus.upcoming;
  if (session.endAt.isAfter(now)) return SessionTimeStatus.current;
  return SessionTimeStatus.ended;
}
