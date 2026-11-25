import 'package:center_net/features/assistant/models/attendance.dart';
import 'package:center_net/features/grades/models/exam.dart';
import 'package:center_net/features/grades/models/score.dart';
import 'package:center_net/features/groups/models/group.dart';
import 'package:center_net/features/student_area/models/child_data.dart';
import 'package:flutter_test/flutter_test.dart';

Group makeGroup(String id, String name, List<Map<String, dynamic>> slots,
    {String status = 'active'}) {
  return Group.fromMap(id, <String, dynamic>{
    'centerId': 'c1',
    'name': name,
    'teacherId': 't1',
    'createdBy': 'a1',
    'slots': slots,
    'status': status,
  });
}

Exam exam(String id, double max, {bool published = true, int day = 1}) {
  return Exam.fromMap(id, <String, dynamic>{
    'centerId': 'c1',
    'groupId': 'g1',
    'title': 'امتحان $id',
    'date': DateTime(2026, 11, day),
    'maxScore': max,
    'published': published,
    'createdBy': 'a1',
  });
}

Score score(String examId, String state, {double? value}) {
  return Score.fromMap('${examId}_s1', <String, dynamic>{
    'centerId': 'c1',
    'examId': examId,
    'studentId': 's1',
    'state': state,
    'score': value,
    'comment': '',
    'createdBy': 't1',
  });
}

Attendance att(String sessionId, String status, {bool voided = false}) {
  return Attendance.fromMap('${sessionId}_s1', <String, dynamic>{
    'centerId': 'c1',
    'sessionId': sessionId,
    'studentId': 's1',
    'status': status,
    'method': 'manual',
    'recordedBy': 't1',
    'voided': voided,
  });
}

void main() {
  group('buildSchedule', () {
    test('بيرتب من السبت وبعدين بالوقت، وبيتخطى المؤرشف', () {
      final entries = buildSchedule([
        makeGroup('g1', 'جبر', [
          {'weekday': 1, 'startMinutes': 600, 'durationMinutes': 60}, // اثنين
          {'weekday': 6, 'startMinutes': 900, 'durationMinutes': 60}, // سبت
        ]),
        makeGroup('g2', 'هندسة', [
          {'weekday': 6, 'startMinutes': 600, 'durationMinutes': 60}, // سبت أبكر
        ]),
        makeGroup('g3', 'قديمة', [
          {'weekday': 7, 'startMinutes': 600, 'durationMinutes': 60},
        ], status: 'archived'),
      ]);

      expect(
        entries.map((e) => '${e.group.name}:${e.slot.weekday}:${e.slot.startMinutes}'),
        ['هندسة:6:600', 'جبر:6:900', 'جبر:1:600'],
      );
    });
  });

  group('parseSessionWhen', () {
    test('صيغة سليمة', () {
      expect(parseSessionWhen('g1_20261119_1730'), DateTime(2026, 11, 19, 17, 30));
    });

    test('صيغة غريبة = null', () {
      expect(parseSessionWhen('abc'), isNull);
      expect(parseSessionWhen('g1_2026_1730'), isNull);
      expect(parseSessionWhen('g1_20261119_17xx'), isNull);
    });
  });

  group('buildAttendanceHistory', () {
    test('بيستبعد الملغي ويرتب الأحدث أولًا ويحسب الحضور', () {
      final history = buildAttendanceHistory(
        [
          att('g1_20261101_1700', 'present'),
          att('g1_20261108_1700', 'late'),
          att('g1_20261115_1700', 'excused'),
          att('g1_20261122_1700', 'present', voided: true),
        ],
        {'g1': 'جبر'},
      );

      expect(history.total, 3);
      expect(history.attended, 2); // حاضر + متأخر
      expect(history.rows.first.attendance.sessionId, 'g1_20261115_1700');
      expect(history.rows.first.groupName, 'جبر');
    });
  });

  group('buildResults', () {
    test('المتوسط من الدرجات المحسوبة بس في الامتحانات المنشورة', () {
      final data = buildResults(
        [
          exam('e1', 20, day: 1),
          exam('e2', 10, day: 2),
          exam('e3', 50, published: false, day: 3),
        ],
        [
          score('e1', 'scored', value: 15),
          score('e2', 'absent'),
          score('e3', 'scored', value: 50),
        ],
      );

      expect(data.items.map((r) => r.exam.id), ['e2', 'e1']); // الأحدث أولًا، من غير المسودة
      expect(data.average, closeTo(75, 0.0001)); // 15 من 20
      expect(data.items.first.score?.state, ScoreState.absent);
    });

    test('من غير درجات = متوسط null والامتحان لسه', () {
      final data = buildResults([exam('e1', 20)], const <Score>[]);
      expect(data.average, isNull);
      expect(data.items.single.score, isNull);
    });
  });
}
