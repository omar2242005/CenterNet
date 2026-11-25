import 'package:center_net/features/assistant/models/attendance.dart';
import 'package:center_net/features/assistant/models/attendance_entry.dart';
import 'package:center_net/features/assistant/models/pending_scan.dart';
import 'package:center_net/features/assistant/rules/attendance_merger.dart';
import 'package:center_net/features/students/models/student.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sessionId = 'g1_20261119_1700';

  Student student(String id, {int no = 1, String name = 'طالب'}) =>
      Student.create(
        id: id,
        centerId: 'c1',
        studentNo: no,
        fullName: name,
        searchKey: name,
        phone: '',
        grade: '',
        createdBy: 'u1',
        groupIds: const ['g1'],
      );

  Attendance record(
    String sid, {
    AttendanceStatus status = AttendanceStatus.present,
    bool voided = false,
  }) {
    final attendance = Attendance.create(
      centerId: 'c1',
      sessionId: sessionId,
      studentId: sid,
      status: status,
      method: AttendanceMethod.qr,
      recordedBy: 'u1',
      scannedAt: DateTime.utc(2026, 11, 19, 15, 5),
    );
    if (!voided) return attendance;
    final map = attendance.toCreateMap(
      recordedAt: DateTime.utc(2026, 11, 19, 15, 6),
    )..addAll(
      Attendance.toVoidMap(
        voidedBy: 'u1',
        reason: 'اتسجل بالغلط',
        voidedAt: DateTime.utc(2026, 11, 19, 15, 7),
      ),
    );
    return Attendance.fromMap(attendance.id, map);
  }

  PendingScan scan(
    String sid, {
    PendingScanStatus status = PendingScanStatus.pending,
    PendingAttendanceStatus attendance = PendingAttendanceStatus.present,
  }) => PendingScan(
    id: '${sessionId}_$sid',
    sessionId: sessionId,
    studentId: sid,
    scannedAt: DateTime.utc(2026, 11, 19, 15, 10),
    status: status,
    centerId: 'c1',
    attendanceStatus: attendance,
  );

  group('الدمج', () {
    test('التكرار بالـ id: السجل موجود مرة واحدة وسجل Firestore يكسب', () {
      final entries = AttendanceMerger.merge(
        sessionId: sessionId,
        records: [record('s1', status: AttendanceStatus.lateArrival)],
        pendingScans: [scan('s1')],
        studentsById: {'s1': student('s1')},
      );
      expect(entries, hasLength(1));
      expect(entries.single.syncState, AttendanceSyncState.synced);
      expect(entries.single.status, AttendanceStatus.lateArrival);
    });

    test('المسحة المعلقة بتظهر بانتظار المزامنة والفاشلة فاشلة', () {
      final entries = AttendanceMerger.merge(
        sessionId: sessionId,
        records: const [],
        pendingScans: [
          scan('s1'),
          scan('s2', status: PendingScanStatus.failed, attendance: PendingAttendanceStatus.late),
        ],
        studentsById: {'s1': student('s1'), 's2': student('s2', no: 2)},
      );
      expect(entries, hasLength(2));
      expect(entries[0].syncState, AttendanceSyncState.waiting);
      expect(entries[1].syncState, AttendanceSyncState.failed);
      expect(entries[1].status, AttendanceStatus.lateArrival);
    });

    test('الملغي مش سطر في القايمة، وبيشيل مسحة محلية بنفس الـ id', () {
      final entries = AttendanceMerger.merge(
        sessionId: sessionId,
        records: [record('s1', voided: true)],
        pendingScans: [scan('s1')],
        studentsById: {'s1': student('s1')},
      );
      expect(entries, isEmpty);
    });

    test('المتزامن محليًا مش بيتدمج (شغل سجل Firestore)', () {
      final entries = AttendanceMerger.merge(
        sessionId: sessionId,
        records: const [],
        pendingScans: [scan('s1', status: PendingScanStatus.synced)],
        studentsById: {'s1': student('s1')},
      );
      expect(entries, isEmpty);
    });

    test('سجلات ومسحات جلسة تانية بتتجاهل', () {
      final other = scan('s1');
      final entries = AttendanceMerger.merge(
        sessionId: sessionId,
        records: const [],
        pendingScans: [
          PendingScan(
            id: 'g2_20261119_1900_s1',
            sessionId: 'g2_20261119_1900',
            studentId: other.studentId,
            scannedAt: other.scannedAt,
            centerId: 'c1',
            attendanceStatus: PendingAttendanceStatus.present,
          ),
        ],
        studentsById: {'s1': student('s1')},
      );
      expect(entries, isEmpty);
    });

    test('الترتيب بوقت المسح تصاعديًا', () {
      final entries = AttendanceMerger.merge(
        sessionId: sessionId,
        records: [record('s1')],
        pendingScans: [scan('s2', attendance: PendingAttendanceStatus.late)],
        studentsById: {'s1': student('s1'), 's2': student('s2', no: 2)},
      );
      expect(entries.map((e) => e.studentId), ['s1', 's2']);
    });
  });

  group('الملخص', () {
    test('عدادات حاضر/متأخر/بانتظار/لم يحضر بعد', () {
      final students = [
        student('s1', name: 'أحمد'),
        student('s2', no: 2, name: 'سارة'),
        student('s3', no: 3, name: 'مريم'),
      ];
      final records = [record('s1')];
      final scans = [scan('s2', attendance: PendingAttendanceStatus.late)];
      final byId = {for (final s in students) s.id: s};
      final entries = AttendanceMerger.merge(
        sessionId: sessionId,
        records: records,
        pendingScans: scans,
        studentsById: byId,
      );
      final summary = AttendanceMerger.summary(
        entries: entries,
        students: students,
        coveredStudentIds: AttendanceMerger.coveredStudentIds(
          sessionId: sessionId,
          records: records,
          entries: entries,
        ),
      );
      expect(summary.presentCount, 1);
      expect(summary.lateCount, 1);
      expect(summary.waitingCount, 1);
      expect(summary.failedCount, 0);
      expect(summary.attendedCount, 2);
      expect(summary.totalStudents, 3);
      expect(summary.notYetAttendedCount, 1);
    });

    test('الملغي مش بيتحسب حضور، والغياب بعذر بيغطي الطالب', () {
      final students = [student('s1'), student('s2', no: 2), student('s3', no: 3)];
      final records = [
        record('s1', voided: true),
        record('s2', status: AttendanceStatus.excused),
      ];
      final entries = AttendanceMerger.merge(
        sessionId: sessionId,
        records: records,
        pendingScans: const [],
        studentsById: {for (final s in students) s.id: s},
      );
      expect(entries, isEmpty);
      final summary = AttendanceMerger.summary(
        entries: entries,
        students: students,
        coveredStudentIds: AttendanceMerger.coveredStudentIds(
          sessionId: sessionId,
          records: records,
          entries: entries,
        ),
      );
      // s1 ملغي (مش مغطى)، s2 بعذر (مغطى)، s3 لسه.
      expect(summary.notYetAttendedCount, 2);
      expect(summary.attendedCount, 0);
    });

    test('المؤرشف مش بيتحسب في إجمالي الطلاب', () {
      final active = student('s1');
      final archived = Student.fromMap('s2', {
        ...student('s2', no: 2).toCreateMap(createdAt: DateTime.utc(2026)),
        'status': 'archived',
      });
      final summary = AttendanceMerger.summary(
        entries: const [],
        students: [active, archived],
        coveredStudentIds: const {},
      );
      expect(summary.totalStudents, 1);
      expect(summary.notYetAttendedCount, 1);
    });
  });
}
