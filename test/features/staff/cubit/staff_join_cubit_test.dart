import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/features/linking/models/invite_code.dart';
import 'package:center_net/features/staff/cubit/staff_join_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_staff_join_repository.dart';

void main() {
  group('StaffJoinCubit', () {
    test('الحالة الأولى: idle', () async {
      final cubit = StaffJoinCubit(FakeStaffJoinRepository());
      expect(cubit.state.status, StaffJoinStatus.idle);
      await cubit.close();
    });

    test('نجاح: بيرجّع السنتر والدور', () async {
      final repo = FakeStaffJoinRepository();
      final cubit = StaffJoinCubit(repo);
      await cubit.submit('ABCD2345');

      expect(cubit.state.status, StaffJoinStatus.success);
      expect(cubit.state.result?.centerId, 'c1');
      expect(cubit.state.result?.centerName, 'مركز النور');
      expect(cubit.state.result?.role, StaffInviteRole.teacher);
      expect(repo.calls, ['accept:ABCD2345']);
      await cubit.close();
    });

    test('فشل: failure برسالة عربية ومفيش نتيجة', () async {
      final cubit = StaffJoinCubit(
        FakeStaffJoinRepository(
          failure: const Failure.validation('هذا الكود مستخدم بالفعل.'),
        ),
      );
      await cubit.submit('ABCD2345');

      expect(cubit.state.status, StaffJoinStatus.failure);
      expect(cubit.state.failure?.message, 'هذا الكود مستخدم بالفعل.');
      expect(cubit.state.result, isNull);
      await cubit.close();
    });

    test('نداء تاني أثناء التنفيذ بيتتجاهل', () async {
      final repo = FakeStaffJoinRepository();
      final cubit = StaffJoinCubit(repo);
      final a = cubit.submit('ABCD2345');
      final b = cubit.submit('ABCD2345');
      await Future.wait([a, b]);

      expect(repo.calls.length, 1);
      await cubit.close();
    });

    test('محاولة جديدة بعد فشل بتنجح', () async {
      final repo = FakeStaffJoinRepository(failure: const Failure.network());
      final cubit = StaffJoinCubit(repo);
      await cubit.submit('ABCD2345');
      expect(cubit.state.status, StaffJoinStatus.failure);

      repo.failure = null;
      await cubit.submit('ABCD2345');
      expect(cubit.state.status, StaffJoinStatus.success);
      await cubit.close();
    });
  });
}
