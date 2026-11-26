import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:center_net/features/sessions/rules/session_generator.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  late tz.Location cairo;
  setUp(() => cairo = tz.getLocation('Africa/Cairo'));

  List<String> ids(DateTime from, List<WeeklySlot> slots, {int weeks = 4}) =>
      SessionGenerator.generate(
        centerId: 'c1',
        groupId: 'g1',
        slots: slots,
        from: from,
        createdBy: 'adminA',
        weeks: weeks,
      ).map((s) => s.id).toList();

  // 2026-11-19 يوم خميس.
  final thursday1700 = WeeklySlot(
    weekday: DateTime.thursday,
    startMinutes: 17 * 60,
    durationMinutes: 90,
  );

  test('أسبوع عادي: ميعاد واحد × 4 أسابيع', () {
    final out = ids(tz.TZDateTime(cairo, 2026, 11, 19), [thursday1700]);
    expect(out, [
      'g1_20261119_1700',
      'g1_20261126_1700',
      'g1_20261203_1700',
      'g1_20261210_1700',
    ]);
  });

  test('أكتر من ميعاد في الأسبوع بيترتبوا زمنيًا', () {
    final out = ids(
      tz.TZDateTime(cairo, 2026, 11, 19),
      [
        WeeklySlot(
            weekday: DateTime.saturday, startMinutes: 600, durationMinutes: 60),
        thursday1700,
      ],
      weeks: 1,
    );
    expect(out, ['g1_20261119_1700', 'g1_20261121_1000']);
  });

  test('إعادة التوليد بتطلع نفس الـ ids (من غير تكرار)', () {
    final from = tz.TZDateTime(cairo, 2026, 11, 19);
    expect(ids(from, [thursday1700]), ids(from, [thursday1700]));
  });

  test('تغيّر التوقيت الصيفي: الساعة 17:00 ثابتة والـ UTC بيتغير', () {
    final out = SessionGenerator.generate(
      centerId: 'c1',
      groupId: 'g1',
      slots: [thursday1700],
      from: tz.TZDateTime(cairo, 2026, 10, 22),
      createdBy: 'adminA',
      weeks: 3,
    );
    expect(out.map((s) => s.id), [
      'g1_20261022_1700',
      'g1_20261029_1700',
      'g1_20261105_1700',
    ]);
    // 22 و29 أكتوبر لسه صيفي (+3)، و5 نوفمبر شتوي (+2).
    expect(out[0].startAt.toUtc().hour, 14);
    expect(out[2].startAt.toUtc().hour, 15);
  });

  test('النهاية = البداية + المدة بوقت الحائط', () {
    final s = SessionGenerator.generate(
      centerId: 'c1',
      groupId: 'g1',
      slots: [thursday1700],
      from: tz.TZDateTime(cairo, 2026, 11, 19),
      createdBy: 'adminA',
      weeks: 1,
    ).single;
    expect(s.endAt.difference(s.startAt), const Duration(minutes: 90));
  });

  test('مدخلات غلط بترمي ArgumentError', () {
    expect(() => WeeklySlot(weekday: 0, startMinutes: 0, durationMinutes: 60),
        throwsArgumentError);
    expect(() => WeeklySlot(weekday: 1, startMinutes: 1440, durationMinutes: 60),
        throwsArgumentError);
    expect(() => WeeklySlot(weekday: 1, startMinutes: 0, durationMinutes: 0),
        throwsArgumentError);
    expect(() => ids(tz.TZDateTime(cairo, 2026, 11, 19), [thursday1700], weeks: 0),
        throwsArgumentError);
  });
}
