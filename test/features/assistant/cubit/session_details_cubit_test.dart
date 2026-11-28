import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/core/services/local_store.dart';
import 'package:center_net/core/services/pending_ops_guard.dart';
import 'package:center_net/core/state/view_state.dart';
import 'package:center_net/features/assistant/cubit/session_details_cubit.dart';
import 'package:center_net/features/assistant/cubit/session_details_state.dart';
import 'package:center_net/features/scan/models/scan_setup.dart';
import 'package:center_net/features/attendance/models/attendance.dart';
import 'package:center_net/features/scan/models/pending_scan.dart';
import 'package:center_net/features/auth/models/account_type.dart';
import 'package:center_net/features/auth/models/app_user.dart';
import 'package:center_net/features/assistant/repository/assistant_repository.dart';
import 'package:center_net/features/assistant/repository/mock_assistant_repository.dart';
import 'package:center_net/features/attendance/repository/attendance_repository.dart';
import 'package:center_net/features/attendance/repository/mock_attendance_repository.dart';
import 'package:center_net/features/scan/repository/mock_scan_repository.dart';
import 'package:center_net/features/scan/repository/scan_repository.dart';
import 'package:center_net/features/scan/services/pending_scan_store.dart';
import 'package:center_net/features/students/models/student.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:center_net/features/groups/models/group.dart';
import 'package:center_net/features/sessions/models/session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PendingOpsGuard guard;
  late PendingScanStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    guard = PendingOpsGuard();
    store = PendingScanStore(await LocalStore.open(), guard);
  });

  /// الكيوبت بقى بياخد ثلاث repositories (دور المساعد + الحضور + المسح).
  /// الهيلبر بتبني الثلاثة من نفس الـ callbacks اللي كانت في الاختبار.
  ({
    AssistantRepository assistant,
    AttendanceRepository attendance,
    ScanRepository scan,
  })
  mocksFor({
    Future<Session> Function(String sessionId)? onSessionById,
    Future<Group> Function(String groupId)? onGroupById,
    Future<AppUser> Function()? onMyProfile,
    Future<List<Student>> Function(String centerId, String groupId)?
    onGroupStudents,
    Future<List<Attendance>> Function(String centerId, String sessionId)?
    onSessionAttendance,
    Future<ScanSetup> Function(String sessionId)? onPrepareScanSetup,
  }) => (
    assistant: MockAssistantRepository(
      onGroupById: onGroupById,
      onMyProfile: onMyProfile,
    ),
    attendance: MockAttendanceRepository(
      onSessionById: onSessionById,
      onGroupStudents: onGroupStudents,
      onSessionAttendance: onSessionAttendance,
    ),
    scan: MockScanRepository(onPrepareScanSetup: onPrepareScanSetup),
  );

  AppUser profile() => AppUser(
    uid: 'u1',
    name: 'منى',
    email: '',
    phone: '',
    accountType: AccountType.staff,
    centerId: 'c1',
  );

  Session session() => Session.create(
    centerId: 'c1',
    groupId: 'g1',
    cairoStart: DateTime(2026, 11, 25, 17),
    cairoEnd: DateTime(2026, 11, 25, 18),
    createdBy: 'u1',
  );

  Group aGroup() => Group.create(
    id: 'g1',
    centerId: 'c1',
    name: 'مجموعة الفيزياء',
    subject: 'فيزياء',
    grade: 'ثالثة ثانوي',
    teacherId: 't1',
    createdBy: 'u1',
    room: 'قاعة 2',
  );

  group('SessionDetailsCubit.load', () {
    test('البداية تحميل، وبعد الجلب الجلسة والمجموعة', () async {
      final s = session();
      final mocks = mocksFor(
        onSessionById: (sessionId) async {
          expect(sessionId, s.id);
          return s;
        },
        onGroupById: (groupId) async => aGroup(),
      );
      final cubit = SessionDetailsCubit(mocks.assistant, mocks.attendance, mocks.scan, store, guard, sessionId: s.id);
      expect(cubit.state.status, isA<ViewLoading<SessionDetailsData>>());

      await cubit.load();

      final status = cubit.state.status;
      expect(status, isA<ViewSuccess<SessionDetailsData>>());
      final data = (status as ViewSuccess<SessionDetailsData>).data;
      expect(data.session.id, s.id);
      expect(data.group.name, 'مجموعة الفيزياء');
      await cubit.close();
    });

    test('جلسة مش موجودة = خطأ، وإعادة المحاولة بتنجح', () async {
      var calls = 0;
      final s = session();
      final mocks = mocksFor(
        onSessionById: (sessionId) async {
          calls++;
          if (calls == 1) throw const Failure.notFound();
          return s;
        },
        onGroupById: (groupId) async => aGroup(),
      );
      final cubit = SessionDetailsCubit(mocks.assistant, mocks.attendance, mocks.scan, store, guard, sessionId: s.id);

      await cubit.load();
      expect(cubit.state.status, isA<ViewFailed<SessionDetailsData>>());

      await cubit.load();
      expect(cubit.state.status, isA<ViewSuccess<SessionDetailsData>>());
      await cubit.close();
    });
  });

  group('SessionDetailsCubit.prepareScan', () {
    test('النجاح بيحط preparedSetup للتنقّل، وconsume بتمسحه', () async {
      final s = session();
      final setup = ScanSetup.forSession(
        session: s,
        groupStudentIds: {'s1', 's2'},
      );
      final mocks = mocksFor(
        onSessionById: (sessionId) async => s,
        onGroupById: (groupId) async => aGroup(),
        onPrepareScanSetup: (sessionId) async {
          expect(sessionId, s.id);
          return setup;
        },
      );
      final cubit = SessionDetailsCubit(mocks.assistant, mocks.attendance, mocks.scan, store, guard, sessionId: s.id);
      await cubit.load();

      await cubit.prepareScan();

      expect(cubit.state.preparing, isFalse);
      expect(cubit.state.preparedSetup, same(setup));
      expect(cubit.state.prepareFailure, isNull);

      cubit.consumePreparedSetup();
      expect(cubit.state.preparedSetup, isNull);
      await cubit.close();
    });

    test(
      'فشل التحضير (أوفلاين/مجموعة فاضية) بيظهر خطأ ومفيش تنقّل',
      () async {
        final s = session();
        final mocks = mocksFor(
          onSessionById: (sessionId) async => s,
          onGroupById: (groupId) async => aGroup(),
          onPrepareScanSetup: (sessionId) async =>
              throw const Failure.validation(
                'مفيش طلاب مسجّلين في مجموعة الحصة دي. راجع إدارة السنتر.',
              ),
        );
        final cubit = SessionDetailsCubit(mocks.assistant, mocks.attendance, mocks.scan, store, guard, sessionId: s.id);
        await cubit.load();

        await cubit.prepareScan();

        expect(cubit.state.preparing, isFalse);
        // مفيش preparedSetup = الشاشة مش هتتنقل للماسح.
        expect(cubit.state.preparedSetup, isNull);
        expect(
          cubit.state.prepareFailure,
          isA<Failure>().having(
            (f) => f.type,
            'type',
            FailureType.validation,
          ),
        );
        // البيانات نفسها فضلت معروضة (الخطأ على الزر مش بدل الشاشة).
        expect(cubit.state.status, isA<ViewSuccess<SessionDetailsData>>());
        await cubit.close();
      },
    );

    test('التحضير ممنوع قبل اكتمال التحميل', () async {
      var prepareCalls = 0;
      final s = session();
      final mocks = mocksFor(
        onSessionById: (sessionId) async => s,
        onGroupById: (groupId) async => aGroup(),
        onPrepareScanSetup: (sessionId) async {
          prepareCalls++;
          throw UnimplementedError();
        },
      );
      final cubit = SessionDetailsCubit(mocks.assistant, mocks.attendance, mocks.scan, store, guard, sessionId: s.id);

      await cubit.prepareScan(); // لسه loading

      expect(prepareCalls, 0);
      expect(cubit.state.preparedSetup, isNull);
      await cubit.close();
    });
  });

  group('SessionDetailsCubit summary', () {
    Student student(String id, int no) => Student.create(
      id: id,
      centerId: 'c1',
      studentNo: no,
      fullName: 'طالب $no',
      searchKey: 'طالب $no',
      phone: '',
      grade: '',
      createdBy: 'u1',
      groupIds: const ['g1'],
    );

    Attendance record(String sid, String sessionId) => Attendance.create(
      centerId: 'c1',
      sessionId: sessionId,
      studentId: sid,
      status: AttendanceStatus.present,
      method: AttendanceMethod.qr,
      recordedBy: 'u1',
      scannedAt: DateTime.utc(2026, 11, 25, 15, 5),
    );

    test('الملخص وآخر المسحات بيتحسبوا من البيانات المدموجة', () async {
      final s = session();
      final mocks = mocksFor(
        onSessionById: (sessionId) async => s,
        onGroupById: (groupId) async => aGroup(),
        onMyProfile: () async => profile(),
        onGroupStudents: (c, g) async => [student('s1', 1), student('s2', 2)],
        onSessionAttendance: (c, sid) async => [record('s1', s.id)],
      );
      final cubit = SessionDetailsCubit(mocks.assistant, mocks.attendance, mocks.scan, store, guard, sessionId: s.id);
      await cubit.load();

      final status = cubit.state.status;
      expect(status, isA<ViewSuccess<SessionDetailsData>>());
      final data = (status as ViewSuccess<SessionDetailsData>).data;
      expect(data.summary?.attendedCount, 1);
      expect(data.summary?.totalStudents, 2);
      expect(data.summary?.notYetAttendedCount, 1);
      expect(data.lastScans.single.studentId, 's1');
      expect(cubit.state.summaryFailure, isNull);
      await cubit.close();
    });

    test('فشل قراءة الحضور مش بيسقط الشاشة: summaryFailure مع إعادة', () async {
      var fail = true;
      final s = session();
      final mocks = mocksFor(
        onSessionById: (sessionId) async => s,
        onGroupById: (groupId) async => aGroup(),
        onMyProfile: () async => profile(),
        onGroupStudents: (c, g) async => [student('s1', 1)],
        onSessionAttendance: (c, sid) async {
          if (fail) throw const Failure.permission();
          return [record('s1', s.id)];
        },
      );
      final cubit = SessionDetailsCubit(mocks.assistant, mocks.attendance, mocks.scan, store, guard, sessionId: s.id);
      await cubit.load();

      expect(cubit.state.status, isA<ViewSuccess<SessionDetailsData>>());
      expect(cubit.state.summaryFailure, isA<Failure>());

      fail = false;
      await cubit.load();
      expect(cubit.state.summaryFailure, isNull);
      final status = cubit.state.status as ViewSuccess<SessionDetailsData>;
      expect(status.data.summary?.attendedCount, 1);
      await cubit.close();
    });

    test('مسحة محلية جديدة بتحدّث الملخص لوحدها (الحارس)', () async {
      final s = session();
      final mocks = mocksFor(
        onSessionById: (sessionId) async => s,
        onGroupById: (groupId) async => aGroup(),
        onMyProfile: () async => profile(),
        onGroupStudents: (c, g) async => [student('s1', 1), student('s2', 2)],
        onSessionAttendance: (c, sid) async => [record('s1', s.id)],
      );
      final cubit = SessionDetailsCubit(mocks.assistant, mocks.attendance, mocks.scan, store, guard, sessionId: s.id);
      await cubit.load();

      await store.add(
        PendingScan(
          id: '${s.id}_s2',
          sessionId: s.id,
          studentId: 's2',
          scannedAt: DateTime.utc(2026, 11, 25, 15, 10),
          centerId: 'c1',
          attendanceStatus: PendingAttendanceStatus.late,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final status = cubit.state.status as ViewSuccess<SessionDetailsData>;
      expect(status.data.summary?.attendedCount, 2);
      expect(status.data.summary?.waitingCount, 1);
      expect(status.data.summary?.notYetAttendedCount, 0);
      await cubit.close();
    });
  });
}
