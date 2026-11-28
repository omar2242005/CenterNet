import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/core/services/local_store.dart';
import 'package:center_net/core/services/pending_ops_guard.dart';
import 'package:center_net/core/state/view_state.dart';
import 'package:center_net/features/attendance/cubit/attendance_cubit.dart';
import 'package:center_net/features/attendance/cubit/attendance_state.dart';
import 'package:center_net/features/attendance/models/attendance.dart';
import 'package:center_net/features/attendance/models/attendance_entry.dart';
import 'package:center_net/features/scan/models/pending_scan.dart';
import 'package:center_net/features/attendance/repository/mock_attendance_repository.dart';
import 'package:center_net/features/scan/services/pending_scan_store.dart';
import 'package:center_net/features/sessions/models/session.dart';
import 'package:center_net/features/students/models/student.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late PendingOpsGuard guard;
  late PendingScanStore store;

  const sessionId = 'g1_20261125_1700';


  Session session() => Session.create(
    centerId: 'c1',
    groupId: 'g1',
    cairoStart: DateTime(2026, 11, 25, 17),
    cairoEnd: DateTime(2026, 11, 25, 18),
    createdBy: 'u1',
  );

  Student student(String id, int no, String name) => Student.create(
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

  Attendance record(String sid) => Attendance.create(
    centerId: 'c1',
    sessionId: sessionId,
    studentId: sid,
    status: AttendanceStatus.present,
    method: AttendanceMethod.qr,
    recordedBy: 'u1',
    scannedAt: DateTime.utc(2026, 11, 25, 15, 5),
  );

  PendingScan scan(String sid, {PendingAttendanceStatus? attendance}) =>
      PendingScan(
        id: '${sessionId}_$sid',
        sessionId: sessionId,
        studentId: sid,
        scannedAt: DateTime.utc(2026, 11, 25, 15, 10),
        centerId: 'c1',
        attendanceStatus: attendance ?? PendingAttendanceStatus.present,
      );

  MockAttendanceRepository repository({
    List<Student>? students,
    List<Attendance>? records,
    Object? attendanceError,
  }) => MockAttendanceRepository(
    onCurrentCenterId: () async => 'c1',
    onSessionById: (id) async => session(),
    onGroupStudents: (centerId, groupId) async => students ?? const [],
    onSessionAttendance: (centerId, sid) async =>
        attendanceError != null ? throw attendanceError : (records ?? const []),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    guard = PendingOpsGuard();
    store = PendingScanStore(await LocalStore.open(), guard);
  });

  group('AttendanceCubit', () {
    test('البداية تحميل، وبعد الجلب السطور المدموجة والملخص', () async {
      await store.add(scan('s2', attendance: PendingAttendanceStatus.late));
      final cubit = AttendanceCubit(
        repository(students: [student('s1', 1, 'أحمد'), student('s2', 2, 'سارة')],
            records: [record('s1')]),
        store,
        guard,
        sessionId: sessionId,
      );
      expect(cubit.state.status, isA<ViewLoading<List<AttendanceEntry>>>());

      await cubit.load();

      final status = cubit.state.status;
      expect(status, isA<ViewSuccess<List<AttendanceEntry>>>());
      final entries = (status as ViewSuccess<List<AttendanceEntry>>).data;
      expect(entries, hasLength(2));
      expect(entries[0].syncState, AttendanceSyncState.synced);
      expect(entries[1].syncState, AttendanceSyncState.waiting);
      expect(cubit.state.summary?.attendedCount, 2);
      expect(cubit.state.summary?.waitingCount, 1);
      await cubit.close();
    });

    test('مفيش حضور = حالة فاضية', () async {
      final cubit = AttendanceCubit(
        repository(students: [student('s1', 1, 'أحمد')]),
        store,
        guard,
        sessionId: sessionId,
      );
      await cubit.load();
      expect(cubit.state.status, isA<ViewEmpty<List<AttendanceEntry>>>());
      await cubit.close();
    });

    test('فشل القراءة = خطأ، وإعادة المحاولة بتنجح', () async {
      var fail = true;
      final repo = MockAttendanceRepository(
        onCurrentCenterId: () async => 'c1',
        onSessionById: (id) async => session(),
        onGroupStudents: (c, g) async => [student('s1', 1, 'أحمد')],
        onSessionAttendance: (c, s) async {
          if (fail) throw const Failure.network();
          return [record('s1')];
        },
      );
      final cubit = AttendanceCubit(repo, store, guard, sessionId: sessionId);
      await cubit.load();
      expect(cubit.state.status, isA<ViewFailed<List<AttendanceEntry>>>());

      fail = false;
      await cubit.load();
      expect(cubit.state.status, isA<ViewSuccess<List<AttendanceEntry>>>());
      await cubit.close();
    });

    test('بحث بلا نتائج = نجاح بقايمة فاضية مع query محفوظ', () async {
      final cubit = AttendanceCubit(
        repository(students: [student('s1', 1, 'أحمد')], records: [record('s1')]),
        store,
        guard,
        sessionId: sessionId,
      );
      await cubit.load();

      cubit.search('xyz');
      final status = cubit.state.status;
      expect(status, isA<ViewSuccess<List<AttendanceEntry>>>());
      expect((status as ViewSuccess<List<AttendanceEntry>>).data, isEmpty);
      expect(cubit.state.query, 'xyz');
      await cubit.close();
    });

    test('البحث بالاسم المطبّع وبالكود', () async {
      final cubit = AttendanceCubit(
        repository(
          students: [student('s1', 1, 'أحمد علي'), student('s2', 2, 'سارة')],
          records: [record('s1'), record('s2')],
        ),
        store,
        guard,
        sessionId: sessionId,
      );
      await cubit.load();

      cubit.search('احمد'); // بدون همزة: التطبيع بيطابق
      var status = cubit.state.status as ViewSuccess<List<AttendanceEntry>>;
      expect(status.data.single.studentId, 's1');

      cubit.search('2');
      status = cubit.state.status as ViewSuccess<List<AttendanceEntry>>;
      expect(status.data.single.studentId, 's2');
      await cubit.close();
    });

    test('الفلترة ببانتظار المزامنة', () async {
      await store.add(scan('s2'));
      final cubit = AttendanceCubit(
        repository(students: [student('s1', 1, 'أحمد'), student('s2', 2, 'سارة')],
            records: [record('s1')]),
        store,
        guard,
        sessionId: sessionId,
      );
      await cubit.load();

      cubit.setFilter(AttendanceFilter.waiting);
      final status = cubit.state.status as ViewSuccess<List<AttendanceEntry>>;
      expect(status.data.single.studentId, 's2');
      expect(status.data.single.syncState, AttendanceSyncState.waiting);
      await cubit.close();
    });

    test('مسحة جديدة بتوصل من غير إعادة تحميل (تحديث هادي بالحارس)', () async {
      final cubit = AttendanceCubit(
        repository(students: [student('s1', 1, 'أحمد'), student('s2', 2, 'سارة')],
            records: [record('s1')]),
        store,
        guard,
        sessionId: sessionId,
      );
      await cubit.load();
      var status = cubit.state.status as ViewSuccess<List<AttendanceEntry>>;
      expect(status.data, hasLength(1));

      // مسحة جديدة من الماسح: الحارس بيتغير والكيوبت بيحدّث لوحده.
      await store.add(scan('s2'));
      await Future<void>.delayed(Duration.zero);

      status = cubit.state.status as ViewSuccess<List<AttendanceEntry>>;
      expect(status.data, hasLength(2));
      expect(cubit.state.summary?.waitingCount, 1);
      await cubit.close();
    });
  });
}
