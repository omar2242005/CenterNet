import 'package:center_net/features/teacher/rules/teacher_home_builder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../helpers/teacher_fixtures.dart';

void main() {
  tzdata.initializeTimeZones();

  final cairo = tz.getLocation('Africa/Cairo');
  final now = tz.TZDateTime(cairo, 2026, 11, 9, 15);

  test('بيعد المجموعات النشطة والطلاب من غير تكرار ويتجاهل المؤرشف', () {
    final data = buildTeacherHomeData(
      name: 'سارة',
      groups: [
        fakeGroup('g1'),
        fakeGroup('g2', subject: 'علوم'),
        fakeGroup('g3', status: 'archived'),
      ],
      students: [
        fakeStudent('s1', 1, ['g1', 'g2']),
        fakeStudent('s2', 2, ['g1']),
        fakeStudent('s3', 3, ['g3']),
        fakeStudent('s4', 4, ['g1'], status: 'archived'),
        fakeStudent('s5', 5, []),
      ],
      sessions: const [],
      now: now,
    );
    expect(data.groupsCount, 2);
    expect(data.studentsCount, 2);
    expect(data.subjects, ['رياضيات', 'علوم']);
    expect(data.nextSession, isNull);
  });

  test(
    'الحصة القادمة: أقرب حصة مش ملغاة ومخلصتش، ومعاها عدد طلاب مجموعتها',
    () {
      final g1 = fakeGroup('g1', room: '3001');
      final data = buildTeacherHomeData(
        name: 'سارة',
        groups: [g1, fakeGroup('g2')],
        students: [
          fakeStudent('s1', 1, ['g1']),
          fakeStudent('s2', 2, ['g1']),
          fakeStudent('s3', 3, ['g2']),
        ],
        sessions: [
          fakeSession('g1', tz.TZDateTime(cairo, 2026, 11, 9, 9)), // خلصت
          fakeSession(
            'g2',
            tz.TZDateTime(cairo, 2026, 11, 9, 16),
            cancelled: true,
          ),
          fakeSession('g2', tz.TZDateTime(cairo, 2026, 11, 11, 16)),
          fakeSession('g1', tz.TZDateTime(cairo, 2026, 11, 10, 16)),
        ],
        now: now,
      );
      final next = data.nextSession!;
      expect(next.group.id, 'g1');
      expect(next.session.startAt, tz.TZDateTime(cairo, 2026, 11, 10, 16));
      expect(next.studentCount, 2);
    },
  );

  test('حصة شغالة دلوقتي بتتحسب هي القادمة', () {
    final data = buildTeacherHomeData(
      name: 'سارة',
      groups: [fakeGroup('g1')],
      students: const [],
      sessions: [fakeSession('g1', tz.TZDateTime(cairo, 2026, 11, 9, 14, 30))],
      now: now,
    );
    expect(data.nextSession, isNotNull);
  });

  test('حصة مجموعة مؤرشفة أو مش بتاعته مش بتظهر', () {
    final data = buildTeacherHomeData(
      name: 'سارة',
      groups: [
        fakeGroup('g1'),
        fakeGroup('g2', status: 'archived'),
      ],
      students: const [],
      sessions: [
        fakeSession('g2', tz.TZDateTime(cairo, 2026, 11, 10, 16)),
        fakeSession('other', tz.TZDateTime(cairo, 2026, 11, 10, 17)),
      ],
      now: now,
    );
    expect(data.nextSession, isNull);
  });

  test('العام الدراسي: من سبتمبر', () {
    expect(academicYearStartOf(tz.TZDateTime(cairo, 2026, 11, 9)), 2026);
    expect(academicYearStartOf(tz.TZDateTime(cairo, 2026, 9, 1)), 2026);
    expect(academicYearStartOf(tz.TZDateTime(cairo, 2027, 3, 1)), 2026);
    expect(academicYearStartOf(tz.TZDateTime(cairo, 2026, 8, 31)), 2025);
  });
}
