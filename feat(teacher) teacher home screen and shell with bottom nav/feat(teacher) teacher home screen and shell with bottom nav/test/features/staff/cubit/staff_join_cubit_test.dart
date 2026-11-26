import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/features/linking/models/invite_code.dart';
import 'package:center_net/features/staff/cubit/staff_join_cubit.dart';
import 'package:center_net/features/staff/repository/staff_join_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_staff_join_repository.dart';

void main() {
  group('StaffJoinCubit', () {
    test('الحالة الأولى: idle', () async {
      final cubit = StaffJoinCubit(FakeStaffJoinRepository());
      expect(cubit.state.status, StaffJoinStatus.idle);
      await cubit.close();
    });

    test('check: بيعرض المعاينة (الدور) من غير ما ينضم', () async {
      final repo = FakeStaffJoinRepository(role: StaffInviteRole.assistant);
      final cubit = StaffJoinCubit(repo);
      await cubit.check('ABCD2345');

      expect(cubit.state.status, StaffJoinStatus.confirm);
      expect(cubit.state.preview?.role, StaffInviteRole.assistant);
      expect(repo.calls, ['preview:ABCD2345']);
      await cubit.close();
    });

    test('confirm بعد المعاينة: بينضم وبيرجّع السنتر والدور', () async {
      final repo = FakeStaffJoinRepository();
      final cubit = StaffJoinCubit(repo);
      await cubit.check('ABCD2345');
      await cubit.confirm();

      expect(cubit.state.status, StaffJoinStatus.success);
      expect(cubit.state.result?.centerId, 'c1');
      expect(cubit.state.result?.centerName, 'مركز النور');
      expect(cubit.state.result?.role, StaffInviteRole.teacher);
      expect(repo.calls, ['preview:ABCD2345', 'accept:ABCD2345']);
      await cubit.close();
    });

    test('confirm من غير معاينة بيتتجاهل', () async {
      final repo = FakeStaffJoinRepository();
      final cubit = StaffJoinCubit(repo);
      await cubit.confirm();
      expect(repo.calls, isEmpty);
      expect(cubit.state.status, StaffJoinStatus.idle);
      await cubit.close();
    });

    test('عدم تطابق الدور: فشل في المعاينة ومفيش انضمام', () async {
      final repo = FakeStaffJoinRepository(
        previewFailure: const Failure.validation('الكود ده دعوة مساعد'),
      );
      final cubit = StaffJoinCubit(repo);
      await cubit.check('ABCD2345');

      expect(cubit.state.status, StaffJoinStatus.failure);
      expect(cubit.state.failure?.message, 'الكود ده دعوة مساعد');
      await cubit.confirm();
      expect(repo.calls, ['preview:ABCD2345']);
      await cubit.close();
    });

    test('فشل القبول: failure برسالة عربية ومفيش نتيجة', () async {
      final cubit = StaffJoinCubit(
        FakeStaffJoinRepository(
          failure: const Failure.validation('هذا الكود مستخدم بالفعل.'),
        ),
      );
      await cubit.check('ABCD2345');
      await cubit.confirm();

      expect(cubit.state.status, StaffJoinStatus.failure);
      expect(cubit.state.failure?.message, 'هذا الكود مستخدم بالفعل.');
      expect(cubit.state.result, isNull);
      await cubit.close();
    });

    test('back: رجوع من المعاينة للإدخال', () async {
      final cubit = StaffJoinCubit(FakeStaffJoinRepository());
      await cubit.check('ABCD2345');
      cubit.back();
      expect(cubit.state.status, StaffJoinStatus.idle);
      expect(cubit.state.preview, isNull);
      await cubit.close();
    });

    test('نداء تاني أثناء الفحص بيتتجاهل', () async {
      final repo = FakeStaffJoinRepository();
      final cubit = StaffJoinCubit(repo);
      final a = cubit.check('ABCD2345');
      final b = cubit.check('ABCD2345');
      await Future.wait([a, b]);

      expect(repo.calls.length, 1);
      await cubit.close();
    });

    test('محاولة جديدة بعد فشل بتنجح', () async {
      final repo = FakeStaffJoinRepository(
        previewFailure: const Failure.network(),
      );
      final cubit = StaffJoinCubit(repo);
      await cubit.check('ABCD2345');
      expect(cubit.state.status, StaffJoinStatus.failure);

      repo.previewFailure = null;
      await cubit.check('ABCD2345');
      expect(cubit.state.status, StaffJoinStatus.confirm);
      await cubit.close();
    });
  });

  group('تطابق الدور مع نوع الحساب', () {
    test('الدور المتوقع من accountType', () {
      expect(
        StaffJoinRepository.expectedRoleFor('teacher'),
        StaffInviteRole.teacher,
      );
      expect(
        StaffJoinRepository.expectedRoleFor('assistant'),
        StaffInviteRole.assistant,
      );
      expect(StaffJoinRepository.expectedRoleFor('staff'), isNull);
      expect(StaffJoinRepository.expectedRoleFor(null), isNull);
    });

    test('كود مساعد على حساب معلم (والعكس) مرفوض برسالة واضحة', () {
      final a = StaffJoinRepository.roleMismatch(
        StaffInviteRole.teacher,
        StaffInviteRole.assistant,
      );
      final b = StaffJoinRepository.roleMismatch(
        StaffInviteRole.assistant,
        StaffInviteRole.teacher,
      );
      expect(a?.message, contains('دعوة مساعد'));
      expect(a?.message, contains('حسابك حساب معلم'));
      expect(b?.message, contains('دعوة معلم'));
      expect(b?.message, contains('حسابك حساب مساعد'));
    });

    test('متطابق أو حساب قديم: مفيش رفض', () {
      expect(
        StaffJoinRepository.roleMismatch(
          StaffInviteRole.teacher,
          StaffInviteRole.teacher,
        ),
        isNull,
      );
      expect(
        StaffJoinRepository.roleMismatch(null, StaffInviteRole.assistant),
        isNull,
      );
    });
  });
}
