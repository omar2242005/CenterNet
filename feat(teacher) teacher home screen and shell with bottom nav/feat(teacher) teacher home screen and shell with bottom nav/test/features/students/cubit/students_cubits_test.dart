import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/core/state/view_state.dart';
import 'package:center_net/features/students/cubit/student_detail_cubit.dart';
import 'package:center_net/features/students/cubit/student_form_cubit.dart';
import 'package:center_net/features/students/cubit/students_list_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_students_repository.dart';

void main() {
  group('StudentsListCubit', () {
    late FakeStudentsRepository repo;

    setUp(() {
      repo = FakeStudentsRepository(
        students: [
          makeStudent(1, 'أحمد علي', phone: '01011112222'),
          makeStudent(2, 'سارة محمد', phone: '01099998888'),
          makeStudent(3, 'منى حسن', archived: true),
        ],
      );
    });

    Future<StudentsListCubit> loaded() async {
      final cubit = StudentsListCubit(repo);
      addTearDown(cubit.close);
      await cubit.load();
      return cubit;
    }

    test('بيحمّل ويخفي المؤرشفين افتراضيًا', () async {
      final cubit = await loaded();
      expect(cubit.state.view, isA<ViewSuccess<List<dynamic>>>());
      expect(cubit.state.visible.map((s) => s.studentNo), [1, 2]);
    });

    test('إظهار المؤرشفين', () async {
      final cubit = await loaded();
      cubit.setShowArchived(true);
      expect(cubit.state.visible.map((s) => s.studentNo), [1, 2, 3]);
    });

    test('البحث بالتطبيع: "احمد" يلاقي "أحمد"', () async {
      final cubit = await loaded();
      cubit.setQuery('احمد');
      expect(cubit.state.visible.map((s) => s.fullName), ['أحمد علي']);
    });

    test('البحث بالرقم التسلسلي وبالموبايل', () async {
      final cubit = await loaded();
      cubit.setQuery('2');
      expect(cubit.state.visible.map((s) => s.studentNo), [2]);
      cubit.setQuery('0109999');
      expect(cubit.state.visible.map((s) => s.studentNo), [2]);
    });

    test('بحث من غير نتايج = فارغ', () async {
      final cubit = await loaded();
      cubit.setQuery('xyz');
      expect(cubit.state.view, isA<ViewEmpty<List<dynamic>>>());
    });

    test('فشل التحميل بيظهر كخطأ', () async {
      repo.loadFailure = const Failure.network();
      final cubit = await loaded();
      expect(cubit.state.view, isA<ViewFailed<List<dynamic>>>());
    });

    test('سنتر من غير طلاب = فارغ', () async {
      repo.students.clear();
      final cubit = await loaded();
      expect(cubit.state.view, isA<ViewEmpty<List<dynamic>>>());
    });
  });

  group('StudentFormCubit', () {
    test('إضافة طالب جديد', () async {
      final repo = FakeStudentsRepository();
      final cubit = StudentFormCubit(repo);
      addTearDown(cubit.close);

      await cubit.submit(
        fullName: 'أحمد علي',
        phone: '01012345678',
        grade: 'الصف الأول',
      );

      expect(cubit.state.status, StudentFormStatus.success);
      expect(cubit.state.saved?.studentNo, 1);
      expect(repo.calls, ['add:أحمد علي:01012345678:الصف الأول']);
    });

    test('تعديل طالب موجود', () async {
      final repo = FakeStudentsRepository();
      final cubit = StudentFormCubit(repo, editing: makeStudent(4, 'أحمد'));
      addTearDown(cubit.close);

      await cubit.submit(
        fullName: 'أحمد محمد',
        phone: '01112345678',
        grade: '',
      );

      expect(cubit.state.status, StudentFormStatus.success);
      expect(cubit.state.saved?.fullName, 'أحمد محمد');
      expect(repo.calls.single, startsWith('update:s4:'));
    });

    test('الفشل بيظهر برسالته ومش بيعتبر نجاح', () async {
      final repo = FakeStudentsRepository(
        writeFailure: const Failure.permission(),
      );
      final cubit = StudentFormCubit(repo);
      addTearDown(cubit.close);

      await cubit.submit(
        fullName: 'أحمد علي',
        phone: '01012345678',
        grade: '',
      );

      expect(cubit.state.status, StudentFormStatus.failure);
      expect(cubit.state.failure, const Failure.permission());
      expect(cubit.state.saved, isNull);
    });
  });

  group('StudentDetailCubit', () {
    test('أرشفة ثم استرجاع', () async {
      final repo = FakeStudentsRepository();
      final cubit = StudentDetailCubit(repo, makeStudent(1, 'أحمد علي'));
      addTearDown(cubit.close);

      await cubit.setArchived(true);
      expect(cubit.state.student.isArchived, isTrue);
      expect(cubit.state.busy, isFalse);

      await cubit.setArchived(false);
      expect(cubit.state.student.isArchived, isFalse);
      expect(repo.calls, ['archive:s1:true', 'archive:s1:false']);
    });

    test('فشل الأرشفة بيسيب الطالب زي ما هو ومعاه الفشل', () async {
      final repo = FakeStudentsRepository(
        writeFailure: const Failure.network(),
      );
      final cubit = StudentDetailCubit(repo, makeStudent(1, 'أحمد علي'));
      addTearDown(cubit.close);

      await cubit.setArchived(true);

      expect(cubit.state.student.isArchived, isFalse);
      expect(cubit.state.failure, const Failure.network());
    });

    test('نفس الحالة الحالية مبتعملش كتابة', () async {
      final repo = FakeStudentsRepository();
      final cubit = StudentDetailCubit(repo, makeStudent(1, 'أحمد علي'));
      addTearDown(cubit.close);

      await cubit.setArchived(false);

      expect(repo.calls, isEmpty);
    });
  });
}
