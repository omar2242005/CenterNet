import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/core/state/view_state.dart';
import 'package:center_net/features/assistant/cubit/sessions_cubit.dart';
import 'package:center_net/features/assistant/cubit/sessions_state.dart';
import 'package:center_net/features/assistant/models/session_time_status.dart';
import 'package:center_net/features/assistant/repository/mock_assistant_repository.dart';
import 'package:center_net/features/groups/models/group.dart';
import 'package:center_net/features/sessions/models/session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Session sessionAt(int startHour, int endHour, {String groupId = 'g1'}) =>
      Session.create(
        centerId: 'c1',
        groupId: groupId,
        cairoStart: DateTime(2026, 11, 25, startHour),
        cairoEnd: DateTime(2026, 11, 25, endHour),
        createdBy: 'u1',
      );

  Group aGroup(String id) => Group.create(
    id: id,
    centerId: 'c1',
    name: 'مجموعة $id',
    subject: 'فيزياء',
    grade: 'ثالثة ثانوي',
    teacherId: 't1',
    createdBy: 'u1',
  );

  group('SessionsCubit', () {
    test('البداية تحميل، ومفيش حصص = فارغ', () async {
      final cubit = SessionsCubit(MockAssistantRepository());
      expect(cubit.state.status, isA<ViewLoading<SessionsData>>());

      await cubit.load();

      expect(cubit.state.status, isA<ViewEmpty<SessionsData>>());
      await cubit.close();
    });

    test('نجاح: الحصص مرتبة والمجموعات بتتجاب', () async {
      final repository = MockAssistantRepository(
        onTodaySessions: ({now}) async => [sessionAt(17, 18), sessionAt(19, 20)],
        onGroupById: (groupId) async => aGroup(groupId),
      );
      final cubit = SessionsCubit(repository);

      await cubit.load();

      final status = cubit.state.status;
      expect(status, isA<ViewSuccess<SessionsData>>());
      final data = (status as ViewSuccess<SessionsData>).data;
      expect(data.sessions.length, 2);
      expect(data.groups['g1']?.name, 'مجموعة g1');
      await cubit.close();
    });

    test('فشل مجموعة واحدة مش بيطيّح القايمة', () async {
      final repository = MockAssistantRepository(
        onTodaySessions: ({now}) async => [sessionAt(17, 18)],
        onGroupById: (groupId) async => throw const Failure.notFound(),
      );
      final cubit = SessionsCubit(repository);

      await cubit.load();

      final status = cubit.state.status as ViewSuccess<SessionsData>;
      expect(status.data.sessions.length, 1);
      expect(status.data.groups, isEmpty);
      await cubit.close();
    });

    test('فشل الجلب = خطأ، وإعادة المحاولة بتنجح', () async {
      var calls = 0;
      final repository = MockAssistantRepository(
        onTodaySessions: ({now}) async {
          calls++;
          if (calls == 1) throw const Failure.network();
          return [sessionAt(17, 18)];
        },
        onGroupById: (groupId) async => aGroup(groupId),
      );
      final cubit = SessionsCubit(repository);

      await cubit.load();
      expect(cubit.state.status, isA<ViewFailed<SessionsData>>());

      await cubit.load();
      expect(cubit.state.status, isA<ViewSuccess<SessionsData>>());
      await cubit.close();
    });
  });

  group('sessionTimeStatus', () {
    final now = DateTime(2026, 11, 25, 17, 30);

    test('جارية / قادمة / انتهت', () {
      expect(
        sessionTimeStatus(sessionAt(17, 18), now),
        SessionTimeStatus.current,
      );
      expect(
        sessionTimeStatus(sessionAt(19, 20), now),
        SessionTimeStatus.upcoming,
      );
      expect(
        sessionTimeStatus(sessionAt(15, 16), now),
        SessionTimeStatus.ended,
      );
    });

    test('البداية بالظبط = جارية، والنهاية بالظبط = انتهت', () {
      expect(
        sessionTimeStatus(sessionAt(17, 18), DateTime(2026, 11, 25, 17)),
        SessionTimeStatus.current,
      );
      expect(
        sessionTimeStatus(sessionAt(17, 18), DateTime(2026, 11, 25, 18)),
        SessionTimeStatus.ended,
      );
    });

    test('الملغاة ملغاة حتى لو في وقتها', () {
      final session = sessionAt(17, 18);
      final cancelled = Session.fromMap(session.id, {
        ...session.toCreateMap(createdAt: DateTime(2026, 11, 20)),
        'status': 'cancelled',
      });
      expect(sessionTimeStatus(cancelled, now), SessionTimeStatus.cancelled);
    });
  });
}
