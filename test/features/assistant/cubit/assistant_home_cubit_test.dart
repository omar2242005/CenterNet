import 'dart:async';

import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/core/state/view_state.dart';
import 'package:center_net/features/assistant/cubit/home_cubit.dart';
import 'package:center_net/features/assistant/cubit/home_state.dart';
import 'package:center_net/features/assistant/models/scan_setup.dart';
import 'package:center_net/features/assistant/repository/mock_assistant_repository.dart';
import 'package:center_net/features/assistant/services/connectivity_monitor.dart';
import 'package:center_net/features/auth/models/account_type.dart';
import 'package:center_net/features/auth/models/app_user.dart';
import 'package:center_net/features/groups/models/group.dart';
import 'package:center_net/features/sessions/models/session.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeConnectivity implements ConnectivityMonitor {
  bool online = true;
  final StreamController<bool> _changes = StreamController<bool>.broadcast();

  @override
  Future<bool> get isOnline async => online;

  @override
  Stream<bool> get onOnlineChanged => _changes.stream;

  void change(bool value) {
    online = value;
    _changes.add(value);
  }

  Future<void> dispose() => _changes.close();
}

void main() {
  final now = DateTime(2026, 11, 25, 17, 30);

  AppUser profile() => AppUser(
    uid: 'u1',
    name: 'منى',
    email: '',
    phone: '',
    accountType: AccountType.staff,
    centerId: 'c1',
  );

  Session sessionAt(int startHour, int endHour) => Session.create(
    centerId: 'c1',
    groupId: 'g1',
    cairoStart: DateTime(2026, 11, 25, startHour),
    cairoEnd: DateTime(2026, 11, 25, endHour),
    createdBy: 'u1',
  );

  Group aGroup() => Group.create(
    id: 'g1',
    centerId: 'c1',
    subject: 'فيزياء',
    grade: 'ثالثة ثانوي',
    name: 'مجموعة الفيزياء',
    teacherId: 't1',
    createdBy: 'u1',
    room: 'قاعة 2',
  );

  late _FakeConnectivity connectivity;

  setUp(() {
    connectivity = _FakeConnectivity();
  });

  tearDown(() => connectivity.dispose());

  AssistantHomeCubit build(MockAssistantRepository repository) =>
      AssistantHomeCubit(repository, connectivity, clock: () => now);

  group('AssistantHomeCubit.load', () {
    test('البداية تحميل، وبعد الجلب بيانات مع الحصة الجارية ومجموعتها', () async {
      final repository = MockAssistantRepository(
        onMyProfile: () async => profile(),
        onTodaySessions: ({now}) async => [
          sessionAt(17, 18), // جارية
          sessionAt(19, 20), // قادمة
        ],
        onGroupById: (groupId) async => aGroup(),
      );
      final cubit = build(repository);
      expect(cubit.state.status, isA<ViewLoading<AssistantHomeData>>());

      await cubit.load();

      final status = cubit.state.status;
      expect(status, isA<ViewSuccess<AssistantHomeData>>());
      final data = (status as ViewSuccess<AssistantHomeData>).data;
      expect(data.assistantName, 'منى');
      expect(data.centerId, 'c1');
      expect(data.todaySessions.length, 2);
      expect(data.currentSession?.id, 'g1_20261125_1700');
      expect(data.currentGroup?.name, 'مجموعة الفيزياء');
      await cubit.close();
    });

    test('مفيش حصص النهارده: نجاح بقايمة فاضية ومفيش حصة جارية', () async {
      final repository = MockAssistantRepository(
        onMyProfile: () async => profile(),
      );
      final cubit = build(repository);

      await cubit.load();

      final status = cubit.state.status as ViewSuccess<AssistantHomeData>;
      expect(status.data.todaySessions, isEmpty);
      expect(status.data.currentSession, isNull);
      await cubit.close();
    });

    test('فشل الجلب بينقل لحالة الخطأ، وإعادة المحاولة بتنجح', () async {
      var calls = 0;
      final repository = MockAssistantRepository(
        onMyProfile: () async => profile(),
        onTodaySessions: ({now}) async {
          calls++;
          if (calls == 1) throw const Failure.network();
          return [sessionAt(17, 18)];
        },
        onGroupById: (groupId) async => aGroup(),
      );
      final cubit = build(repository);

      await cubit.load();
      expect(cubit.state.status, isA<ViewFailed<AssistantHomeData>>());

      await cubit.load();
      expect(cubit.state.status, isA<ViewSuccess<AssistantHomeData>>());
      await cubit.close();
    });

    test('حساب من غير سنتر = خطأ', () async {
      final repository = MockAssistantRepository(
        onMyProfile: () async => AppUser(
          uid: 'u1',
          name: 'منى',
          email: '',
          phone: '',
          accountType: AccountType.staff,
        ),
      );
      final cubit = build(repository);

      await cubit.load();
      expect(cubit.state.status, isA<ViewFailed<AssistantHomeData>>());
      await cubit.close();
    });

    test('تغيّر الاتصال بيحدّث المؤشر', () async {
      final repository = MockAssistantRepository(
        onMyProfile: () async => profile(),
      );
      final cubit = build(repository);
      await cubit.load();
      expect(cubit.state.online, isTrue);

      connectivity.change(false);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.online, isFalse);
      await cubit.close();
    });
  });

  group('AssistantHomeCubit.prepareScan', () {
    test('النجاح بيحط preparedSetup للتنقّل، وconsume بتمسحه', () async {
      final setup = ScanSetup.forSession(
        session: sessionAt(17, 18),
        groupStudentIds: {'s1'},
      );
      final repository = MockAssistantRepository(
        onMyProfile: () async => profile(),
        onTodaySessions: ({now}) async => [sessionAt(17, 18)],
        onGroupById: (groupId) async => aGroup(),
        onPrepareScanSetup: (sessionId) async {
          expect(sessionId, 'g1_20261125_1700');
          return setup;
        },
      );
      final cubit = build(repository);
      await cubit.load();

      await cubit.prepareScan();

      expect(cubit.state.preparing, isFalse);
      expect(cubit.state.preparedSetup, same(setup));
      expect(cubit.state.prepareFailure, isNull);

      cubit.consumePreparedSetup();
      expect(cubit.state.preparedSetup, isNull);
      await cubit.close();
    });

    test('الفشل بيحط prepareFailure ومفيش preparedSetup (مفيش تنقّل)', () async {
      final repository = MockAssistantRepository(
        onMyProfile: () async => profile(),
        onTodaySessions: ({now}) async => [sessionAt(17, 18)],
        onGroupById: (groupId) async => aGroup(),
        onPrepareScanSetup: (sessionId) async => throw const Failure.network(),
      );
      final cubit = build(repository);
      await cubit.load();

      await cubit.prepareScan();

      expect(cubit.state.preparing, isFalse);
      expect(cubit.state.preparedSetup, isNull);
      expect(cubit.state.prepareFailure, isA<Failure>());
      await cubit.close();
    });

    test('مفيش حصة جارية = الزر مفيش منه تحضير', () async {
      var prepareCalls = 0;
      final repository = MockAssistantRepository(
        onMyProfile: () async => profile(),
        onTodaySessions: ({now}) async => [sessionAt(19, 20)], // قادمة بس
        onPrepareScanSetup: (sessionId) async {
          prepareCalls++;
          throw UnimplementedError();
        },
      );
      final cubit = build(repository);
      await cubit.load();

      await cubit.prepareScan();

      expect(prepareCalls, 0);
      expect(cubit.state.preparedSetup, isNull);
      expect(cubit.state.prepareFailure, isNull);
      await cubit.close();
    });
  });
}
