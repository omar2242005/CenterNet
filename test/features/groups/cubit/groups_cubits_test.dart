import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/core/state/view_state.dart';
import 'package:center_net/features/groups/cubit/group_enrollment_cubit.dart';
import 'package:center_net/features/groups/cubit/group_form_cubit.dart';
import 'package:center_net/features/groups/cubit/groups_list_cubit.dart';
import 'package:center_net/features/groups/models/group.dart';
import 'package:center_net/features/groups/models/group_input.dart';
import 'package:center_net/features/students/models/student.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../students/helpers/fake_students_repository.dart';
import '../helpers/fake_groups_repository.dart';

void main() {
  group('GroupsListCubit', () {
    late FakeGroupsRepository repo;

    setUp(() {
      repo = FakeGroupsRepository(
        groups: [
          makeGroup('g1', 'الجبر'),
          makeGroup('g2', 'الفيزياء'),
          makeGroup('g3', 'قديمة', archived: true),
        ],
      );
    });

    Future<GroupsListCubit> loaded({bool mine = false}) async {
      final cubit = GroupsListCubit(repo, mineOnly: mine);
      addTearDown(cubit.close);
      await cubit.load();
      return cubit;
    }

    test('بيحمّل ويخفي المؤرشفة افتراضيًا', () async {
      final cubit = await loaded();
      expect(cubit.state.view, isA<ViewSuccess<List<Group>>>());
      expect(cubit.state.visible.map((g) => g.id), ['g1', 'g2']);
    });

    test('إظهار المؤرشفة', () async {
      final cubit = await loaded();
      cubit.setShowArchived(true);
      expect(cubit.state.visible.map((g) => g.id), ['g1', 'g2', 'g3']);
    });

    test('mineOnly بينادي loadMyGroups', () async {
      await loaded(mine: true);
      expect(repo.calls, ['loadMy']);
    });

    test('فشل التحميل بيظهر كحالة خطأ', () async {
      repo.loadFailure = const Failure.network();
      final cubit = await loaded();
      expect(cubit.state.view, isA<ViewFailed<List<Group>>>());
    });

    test('الأرشفة بتحدّث القائمة من غير إعادة تحميل', () async {
      final cubit = await loaded();
      final failure = await cubit.archive(cubit.state.all.first);
      expect(failure, isNull);
      expect(cubit.state.visible.map((g) => g.id), ['g2']);
      expect(repo.calls, ['load', 'archive:g1']);
    });

    test('فشل الأرشفة بيرجّع الخطأ والقائمة زي ما هي', () async {
      final cubit = await loaded();
      repo.writeFailure = const Failure.permission();
      final failure = await cubit.archive(cubit.state.all.first);
      expect(failure, const Failure.permission());
      expect(cubit.state.visible.map((g) => g.id), ['g1', 'g2']);
    });
  });

  group('GroupFormCubit', () {
    test('إنشاء ناجح', () async {
      final repo = FakeGroupsRepository();
      final cubit = GroupFormCubit(repo);
      addTearDown(cubit.close);

      await cubit.submit(const GroupInput(name: 'الجبر', teacherId: 't1'));

      expect(cubit.state.status, GroupFormStatus.success);
      expect(cubit.state.saved?.name, 'الجبر');
      expect(repo.calls, ['create:الجبر']);
    });

    test('تعديل بينادي update على المجموعة الحالية', () async {
      final repo = FakeGroupsRepository();
      final cubit = GroupFormCubit(repo, editing: makeGroup('g1', 'قديم'));
      addTearDown(cubit.close);

      await cubit.submit(const GroupInput(name: 'جديد', teacherId: 't1'));

      expect(cubit.state.status, GroupFormStatus.success);
      expect(repo.calls, ['update:g1:جديد']);
    });

    test('الفشل بيظهر في الحالة', () async {
      final repo = FakeGroupsRepository(
        writeFailure: const Failure.validation('اكتب اسم المجموعة.'),
      );
      final cubit = GroupFormCubit(repo);
      addTearDown(cubit.close);

      await cubit.submit(const GroupInput(name: '', teacherId: 't1'));

      expect(cubit.state.status, GroupFormStatus.failure);
      expect(cubit.state.failure?.message, 'اكتب اسم المجموعة.');
      expect(cubit.state.saved, isNull);
    });
  });

  group('GroupEnrollmentCubit', () {
    late FakeStudentsRepository students;
    late FakeGroupsRepository groups;

    setUp(() {
      students = FakeStudentsRepository(
        students: [
          makeStudent(1, 'أحمد علي').withGroupIds(['g1']),
          makeStudent(2, 'سارة محمد'),
          makeStudent(3, 'منى حسن', archived: true),
          makeStudent(4, 'كريم طارق').withGroupIds(['g1']),
        ],
      );
      groups = FakeGroupsRepository();
    });

    Future<GroupEnrollmentCubit> loaded() async {
      final cubit = GroupEnrollmentCubit(
        students,
        groups,
        makeGroup('g1', 'الجبر', capacity: 2),
      );
      addTearDown(cubit.close);
      await cubit.load();
      return cubit;
    }

    List<int> nos(Iterable<Student> list) =>
        [for (final s in list) s.studentNo];

    test('بيعرض النشطين والمسجّلين، ويخفي المؤرشف غير المسجّل', () async {
      final cubit = await loaded();
      expect(nos(cubit.state.visible), [1, 2, 4]);
      expect(nos(cubit.state.enrolled), [1, 4]);
    });

    test('تحذير السعة لما توصل حدها', () async {
      final cubit = await loaded();
      expect(cubit.state.isFull, isTrue);
    });

    test('البحث بالتطبيع', () async {
      final cubit = await loaded();
      cubit.setQuery('احمد');
      expect(nos(cubit.state.visible), [1]);
    });

    test('تسجيل طالب جديد (والسعة تحذير مش منع)', () async {
      final cubit = await loaded();
      final failure = await cubit.toggle(cubit.state.students[1]);

      expect(failure, isNull);
      expect(groups.calls, ['enroll:g1:s2']);
      expect(nos(cubit.state.enrolled), [1, 2, 4]);
      expect(cubit.state.busyStudentId, isNull);
    });

    test('إلغاء تسجيل طالب مسجّل', () async {
      final cubit = await loaded();
      final failure = await cubit.toggle(cubit.state.students[0]);

      expect(failure, isNull);
      expect(groups.calls, ['unenroll:g1:s1']);
      expect(nos(cubit.state.enrolled), [4]);
      expect(cubit.state.isFull, isFalse);
    });

    test('فشل التسجيل بيرجّع الخطأ ومبيغيّرش الحالة', () async {
      final cubit = await loaded();
      groups.writeFailure = const Failure.permission();

      final failure = await cubit.toggle(cubit.state.students[1]);

      expect(failure, const Failure.permission());
      expect(nos(cubit.state.enrolled), [1, 4]);
      expect(cubit.state.busyStudentId, isNull);
    });

    test('فشل تحميل الطلاب', () async {
      students.loadFailure = const Failure.network();
      final cubit = await loaded();
      expect(cubit.state.view, isA<ViewFailed<List<Student>>>());
    });
  });
}
