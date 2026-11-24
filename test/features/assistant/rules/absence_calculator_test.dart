import 'package:center_net/features/assistant/models/attendance.dart';
import 'package:center_net/features/assistant/rules/absence_calculator.dart';
import 'package:center_net/features/sessions/models/session.dart';
import 'package:center_net/features/students/models/student.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Session session({String status = 'scheduled'}) => Session.fromMap('s1', {
        'centerId': 'c1',
        'groupId': 'g1',
        'createdBy': 'u1',
        'startAt': DateTime(2026, 11, 1, 16),
        'endAt': DateTime(2026, 11, 1, 18),
        'status': status,
      });

  Student student(String id, {List<String> groups = const ['g1']}) =>
      Student.create(
        id: id,
        centerId: 'c1',
        studentNo: 1,
        fullName: 'طالب',
        searchKey: 'طالب',
        phone: '',
        grade: '',
        createdBy: 'u1',
        groupIds: groups,
      );

  Attendance record(
    String studentId, {
    AttendanceStatus status = AttendanceStatus.present,
    bool voided = false,
  }) =>
      Attendance.fromMap('s1_$studentId', {
        'centerId': 'c1',
        'sessionId': 's1',
        'studentId': studentId,
        'recordedBy': 'u1',
        'status': status.wire,
        'method': 'manual',
        'voided': voided,
      });

  final now = DateTime(2026, 11, 2);

  List<String> absent({
    Session? s,
    DateTime? at,
    required List<Student> students,
    List<Attendance> records = const [],
  }) =>
      AbsenceCalculator.absentStudentIds(
        session: s ?? session(),
        now: at ?? now,
        students: students,
        records: records,
      );

  test('طالب محضرش = غايب', () {
    expect(absent(students: [student('a')]), ['a']);
  });

  test('طالب حضر = مش غايب', () {
    expect(absent(students: [student('a')], records: [record('a')]), isEmpty);
  });

  test('طالب متأخر = مش غايب', () {
    final r = record('a', status: AttendanceStatus.lateArrival);
    expect(absent(students: [student('a')], records: [r]), isEmpty);
  });

  test('حضور ملغي = غايب', () {
    final r = record('a', voided: true);
    expect(absent(students: [student('a')], records: [r]), ['a']);
  });

  test('غياب بعذر = مش بيتحسب غياب', () {
    final r = record('a', status: AttendanceStatus.excused);
    expect(absent(students: [student('a')], records: [r]), isEmpty);
  });

  test('حصة ملغاة = محدش غايب', () {
    expect(
      absent(s: session(status: 'cancelled'), students: [student('a')]),
      isEmpty,
    );
  });

  test('حصة لسه ماخلصتش = محدش غايب', () {
    expect(
      absent(at: DateTime(2026, 11, 1, 17), students: [student('a')]),
      isEmpty,
    );
  });

  test('طالب في مجموعة تانية = مش في القايمة', () {
    expect(absent(students: [student('a', groups: ['g2'])]), isEmpty);
  });

  test('absenceCount: حضور ملغي = غياب واحد', () {
    final count = AbsenceCalculator.absenceCount(
      student: student('a'),
      sessions: [session()],
      now: now,
      records: [record('a', voided: true)],
    );
    expect(count, 1);
  });
}