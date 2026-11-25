import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/core/state/view_state.dart';
import 'package:center_net/features/assistant/cubit/session_details_cubit.dart';
import 'package:center_net/features/assistant/cubit/session_details_state.dart';
import 'package:center_net/features/assistant/models/scan_setup.dart';
import 'package:center_net/features/assistant/repository/mock_assistant_repository.dart';
import 'package:center_net/features/groups/models/group.dart';
import 'package:center_net/features/sessions/models/session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
      final repository = MockAssistantRepository(
        onSessionById: (sessionId) async {
          expect(sessionId, s.id);
          return s;
        },
        onGroupById: (groupId) async => aGroup(),
      );
      final cubit = SessionDetailsCubit(repository, sessionId: s.id);
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
      final repository = MockAssistantRepository(
        onSessionById: (sessionId) async {
          calls++;
          if (calls == 1) throw const Failure.notFound();
          return s;
        },
        onGroupById: (groupId) async => aGroup(),
      );
      final cubit = SessionDetailsCubit(repository, sessionId: s.id);

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
      final repository = MockAssistantRepository(
        onSessionById: (sessionId) async => s,
        onGroupById: (groupId) async => aGroup(),
        onPrepareScanSetup: (sessionId) async {
          expect(sessionId, s.id);
          return setup;
        },
      );
      final cubit = SessionDetailsCubit(repository, sessionId: s.id);
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
        final repository = MockAssistantRepository(
          onSessionById: (sessionId) async => s,
          onGroupById: (groupId) async => aGroup(),
          onPrepareScanSetup: (sessionId) async =>
              throw const Failure.validation(
                'مفيش طلاب مسجّلين في مجموعة الحصة دي. راجع إدارة السنتر.',
              ),
        );
        final cubit = SessionDetailsCubit(repository, sessionId: s.id);
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
      final repository = MockAssistantRepository(
        onSessionById: (sessionId) async => s,
        onGroupById: (groupId) async => aGroup(),
        onPrepareScanSetup: (sessionId) async {
          prepareCalls++;
          throw UnimplementedError();
        },
      );
      final cubit = SessionDetailsCubit(repository, sessionId: s.id);

      await cubit.prepareScan(); // لسه loading

      expect(prepareCalls, 0);
      expect(cubit.state.preparedSetup, isNull);
      await cubit.close();
    });
  });
}
