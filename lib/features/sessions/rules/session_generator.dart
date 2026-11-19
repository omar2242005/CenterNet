import 'package:timezone/timezone.dart' as tz;

import '../models/session.dart';

/// ميعاد أسبوعي ثابت للمجموعة.
///
/// [weekday] بنفس ترقيم Dart: `DateTime.monday` (1) .. `DateTime.sunday` (7).
/// الوقت بالدقايق من بداية اليوم بتوقيت القاهرة (17:00 = 1020).
///
/// ملحوظة لـ C (groups): شكل `slots[]` في مستند المجموعة لازم يتحوّل لـ
/// WeeklySlot ده. اتفقوا على الحقول: weekday / startMinutes / durationMinutes.
class WeeklySlot {
  final int weekday;
  final int startMinutes;
  final int durationMinutes;

  WeeklySlot({
    required this.weekday,
    required this.startMinutes,
    required this.durationMinutes,
  }) {
    if (weekday < DateTime.monday || weekday > DateTime.sunday) {
      throw ArgumentError.value(weekday, 'weekday', 'اليوم من 1 لـ 7');
    }
    if (startMinutes < 0 || startMinutes >= 24 * 60) {
      throw ArgumentError.value(startMinutes, 'startMinutes', 'وقت غير صالح');
    }
    if (durationMinutes <= 0) {
      throw ArgumentError.value(durationMinutes, 'durationMinutes', 'مدة غير صالحة');
    }
  }
}

/// مولّد الجلسات (كالس نقي، من غير Firebase).
///
/// بيطلّع جلسات [weeks] أسابيع (الافتراضي 4) ابتداءً من يوم [from] (شامل)،
/// كل جلسة بوقت حائط القاهرة مع التوقيت الصيفي. الـ id حتمي (gid_yyyyMMdd_HHmm)
/// فلو الـ Repository كتبهم بـ set على نفس الـ id، إعادة الضغط ما تكررش.
abstract final class SessionGenerator {
  static const int defaultWeeks = 4;

  /// [from] لازم TZDateTime (بتاريخ بس بيتقرا منه: سنة/شهر/يوم).
  /// [location] الافتراضي Africa/Cairo (لازم tz.initializeTimeZones() اتنادت).
  static List<Session> generate({
    required String centerId,
    required String groupId,
    required List<WeeklySlot> slots,
    required DateTime from,
    required String createdBy,
    int weeks = defaultWeeks,
    tz.Location? location,
  }) {
    if (weeks <= 0) {
      throw ArgumentError.value(weeks, 'weeks', 'عدد الأسابيع لازم يكون موجب');
    }
    final loc = location ?? tz.getLocation('Africa/Cairo');
    final result = <Session>[];

    for (var i = 0; i < weeks * 7; i++) {
      final day = tz.TZDateTime(loc, from.year, from.month, from.day + i);
      for (final slot in slots) {
        if (slot.weekday != day.weekday) continue;
        final start = tz.TZDateTime(loc, day.year, day.month, day.day, 0,
            slot.startMinutes);
        // النهاية بوقت الحائط عشان تعدّي تغيير التوقيت الصيفي صح.
        final end = tz.TZDateTime(loc, day.year, day.month, day.day, 0,
            slot.startMinutes + slot.durationMinutes);
        result.add(Session.create(
          centerId: centerId,
          groupId: groupId,
          cairoStart: start,
          cairoEnd: end,
          createdBy: createdBy,
        ));
      }
    }
    result.sort((a, b) => a.startAt.compareTo(b.startAt));
    return result;
  }
}
