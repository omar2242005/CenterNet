import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/core/state/view_state.dart';
import 'package:center_net/features/linking/models/invite_code.dart';
import 'package:center_net/features/staff/cubit/staff_list_cubit.dart';
import 'package:center_net/features/staff/models/staff_member.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_staff_repository.dart';

const _admin = StaffMember(
  uid: 'a1',
  name: 'مدير السنتر',
  role: StaffMemberRole.admin,
  active: true,
);
const _sara = StaffMember(
  uid: 't1',
  name: 'سارة',
  role: StaffMemberRole.teacher,
  active: true,
);
const _karim = StaffMember(
  uid: 's1',
  name: 'كريم',
  role: StaffMemberRole.assistant,
  active: true,
);

List<StaffMember> _members(StaffListCubit cubit) {
  final view = cubit.state.view;
  expect(view, isA<ViewSuccess<List<StaffMember>>>());
  return (view as ViewSuccess<List<StaffMember>>).data;
}

StaffMember _byUid(StaffListCubit cubit, String uid) =>
    _members(cubit).firstWhere((m) => m.uid == uid);

void main() {
  group('StaffListCubit', () {
    test('الحالة الأولى: تحميل', () async {
      final cubit = StaffListCubit(FakeStaffRepository());
      expect(cubit.state.view, isA<ViewLoading<List<StaffMember>>>());
      expect(cubit.state.busyUid, isNull);
      await cubit.close();
    });

    test('load نجاح: بيعرض الأعضاء', () async {
      final repo = FakeStaffRepository(members: [_admin, _sara, _karim]);
      final cubit = StaffListCubit(repo);
      await cubit.load();

      expect(_members(cubit).map((m) => m.uid).toList(), ['a1', 't1', 's1']);
      expect(repo.calls, ['load']);
      await cubit.close();
    });

    test('load من غير أعضاء: حالة فارغة', () async {
      final cubit = StaffListCubit(FakeStaffRepository());
      await cubit.load();

      expect(cubit.state.view, isA<ViewEmpty<List<StaffMember>>>());
      await cubit.close();
    });

    test('load فشل: حالة خطأ، وإعادة المحاولة بتنجح', () async {
      final repo = FakeStaffRepository(
        members: [_admin, _sara],
        loadFailure: const Failure.network(),
      );
      final cubit = StaffListCubit(repo);
      await cubit.load();

      expect(
        cubit.state.view,
        const ViewFailed<List<StaffMember>>(Failure.network()),
      );

      repo.loadFailure = null;
      await cubit.load();
      expect(_members(cubit).length, 2);
      await cubit.close();
    });

    test('changeRole نجاح: بيكتب ويحدّث القائمة', () async {
      final repo = FakeStaffRepository(members: [_admin, _sara, _karim]);
      final cubit = StaffListCubit(repo);
      await cubit.load();

      await cubit.changeRole(_sara, StaffInviteRole.assistant);

      expect(repo.calls.last, 'role:c1:t1:assistant');
      expect(_byUid(cubit, 't1').role, StaffMemberRole.assistant);
      expect(_byUid(cubit, 's1').role, StaffMemberRole.assistant);
      expect(cubit.state.busyUid, isNull);
      expect(cubit.state.actionFailure, isNull);
      await cubit.close();
    });

    test('changeRole لنفس الدور بيتتجاهل', () async {
      final repo = FakeStaffRepository(members: [_admin, _sara]);
      final cubit = StaffListCubit(repo);
      await cubit.load();

      await cubit.changeRole(_sara, StaffInviteRole.teacher);

      expect(repo.calls, ['load']);
      await cubit.close();
    });

    test('setActive(false): بيعطّل الموظف', () async {
      final repo = FakeStaffRepository(members: [_admin, _sara]);
      final cubit = StaffListCubit(repo);
      await cubit.load();

      await cubit.setActive(_sara, false);

      expect(repo.calls.last, 'active:c1:t1:false');
      expect(_byUid(cubit, 't1').active, isFalse);
      expect(_byUid(cubit, 'a1').active, isTrue);
      await cubit.close();
    });

    test('setActive(true): بيرجّع تفعيل موظف معطّل', () async {
      final disabled = _sara.copyWith(active: false);
      final repo = FakeStaffRepository(members: [_admin, disabled]);
      final cubit = StaffListCubit(repo);
      await cubit.load();

      await cubit.setActive(disabled, true);

      expect(repo.calls.last, 'active:c1:t1:true');
      expect(_byUid(cubit, 't1').active, isTrue);
      await cubit.close();
    });

    test('setActive بنفس الحالة بيتتجاهل', () async {
      final repo = FakeStaffRepository(members: [_admin, _sara]);
      final cubit = StaffListCubit(repo);
      await cubit.load();

      await cubit.setActive(_sara, true);

      expect(repo.calls, ['load']);
      await cubit.close();
    });

    test('فشل الكتابة: القائمة زي ما هي وبيظهر الخطأ', () async {
      final repo = FakeStaffRepository(members: [_admin, _sara]);
      final cubit = StaffListCubit(repo);
      await cubit.load();

      repo.writeFailure = const Failure.permission();
      await cubit.setActive(_sara, false);

      expect(_byUid(cubit, 't1').active, isTrue);
      expect(cubit.state.actionFailure, const Failure.permission());
      expect(cubit.state.busyUid, isNull);
      await cubit.close();
    });

    test('محاولة جديدة بعد فشل بتصفّر الخطأ وبتنجح', () async {
      final repo = FakeStaffRepository(members: [_admin, _sara]);
      final cubit = StaffListCubit(repo);
      await cubit.load();

      repo.writeFailure = const Failure.network();
      await cubit.setActive(_sara, false);
      expect(cubit.state.actionFailure, isNotNull);

      repo.writeFailure = null;
      await cubit.setActive(_sara, false);
      expect(cubit.state.actionFailure, isNull);
      expect(_byUid(cubit, 't1').active, isFalse);
      await cubit.close();
    });

    test('الأدمن مبيتعدّلش أبدًا', () async {
      final repo = FakeStaffRepository(members: [_admin, _sara]);
      final cubit = StaffListCubit(repo);
      await cubit.load();

      await cubit.setActive(_admin, false);
      await cubit.changeRole(_admin, StaffInviteRole.assistant);

      expect(repo.calls, ['load']);
      expect(_byUid(cubit, 'a1').role, StaffMemberRole.admin);
      expect(_byUid(cubit, 'a1').active, isTrue);
      await cubit.close();
    });

    test('تعديل تاني أثناء تعديل شغال بيتتجاهل', () async {
      final repo = FakeStaffRepository(members: [_admin, _sara, _karim]);
      final cubit = StaffListCubit(repo);
      await cubit.load();

      final a = cubit.setActive(_sara, false);
      final b = cubit.setActive(_karim, false);
      await Future.wait([a, b]);

      expect(repo.calls.where((c) => c.startsWith('active:')).length, 1);
      expect(_byUid(cubit, 't1').active, isFalse);
      expect(_byUid(cubit, 's1').active, isTrue);
      await cubit.close();
    });

    test('تعديل قبل ما القائمة تتحمّل بيتتجاهل', () async {
      final repo = FakeStaffRepository(members: [_admin, _sara]);
      final cubit = StaffListCubit(repo);

      await cubit.setActive(_sara, false);

      expect(repo.calls, isEmpty);
      await cubit.close();
    });
  });
}
