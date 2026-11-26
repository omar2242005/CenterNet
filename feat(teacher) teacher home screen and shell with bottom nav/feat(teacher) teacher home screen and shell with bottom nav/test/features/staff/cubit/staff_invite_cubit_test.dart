import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/features/linking/models/invite_code.dart';
import 'package:center_net/features/staff/cubit/staff_invite_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_staff_repository.dart';

void main() {
  group('StaffInviteCubit', () {
    test('الحالة الأولى: idle', () async {
      final cubit = StaffInviteCubit(FakeStaffRepository());
      expect(cubit.state.status, StaffInviteStatus.idle);
      expect(cubit.state.issued, isNull);
      await cubit.close();
    });

    test('نجاح: بيرجّع الكود واسم السنتر', () async {
      final repo = FakeStaffRepository();
      final cubit = StaffInviteCubit(repo);
      await cubit.create(name: ' سارة ', role: StaffInviteRole.assistant);

      expect(cubit.state.status, StaffInviteStatus.success);
      expect(cubit.state.issued?.invite.id, FakeStaffRepository.code);
      expect(cubit.state.issued?.invite.role, StaffInviteRole.assistant);
      expect(cubit.state.issued?.centerName, 'مركز النور');
      expect(repo.calls, ['invite:سارة:assistant']);
      await cubit.close();
    });

    test('فشل: failure برسالة عربية ومفيش كود', () async {
      final cubit = StaffInviteCubit(
        FakeStaffRepository(failure: const Failure.permission()),
      );
      await cubit.create(name: 'سارة', role: StaffInviteRole.teacher);

      expect(cubit.state.status, StaffInviteStatus.failure);
      expect(cubit.state.failure, const Failure.permission());
      expect(cubit.state.issued, isNull);
      await cubit.close();
    });

    test('نداء تاني أثناء التنفيذ بيتتجاهل', () async {
      final repo = FakeStaffRepository();
      final cubit = StaffInviteCubit(repo);
      final a = cubit.create(name: 'سارة', role: StaffInviteRole.teacher);
      final b = cubit.create(name: 'سارة', role: StaffInviteRole.teacher);
      await Future.wait([a, b]);

      expect(repo.calls.length, 1);
      await cubit.close();
    });

    test('reset: بيرجّع idle بعد النجاح', () async {
      final cubit = StaffInviteCubit(FakeStaffRepository());
      await cubit.create(name: 'سارة', role: StaffInviteRole.teacher);
      expect(cubit.state.status, StaffInviteStatus.success);

      cubit.reset();
      expect(cubit.state.status, StaffInviteStatus.idle);
      expect(cubit.state.issued, isNull);
      await cubit.close();
    });

    test('محاولة جديدة بعد فشل بتنجح', () async {
      final repo = FakeStaffRepository(failure: const Failure.network());
      final cubit = StaffInviteCubit(repo);
      await cubit.create(name: 'سارة', role: StaffInviteRole.teacher);
      expect(cubit.state.status, StaffInviteStatus.failure);

      repo.failure = null;
      await cubit.create(name: 'سارة', role: StaffInviteRole.teacher);
      expect(cubit.state.status, StaffInviteStatus.success);
      await cubit.close();
    });
  });
}
