import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/core/state/view_state.dart';
import 'package:center_net/features/teacher/cubit/teacher_home_cubit.dart';
import 'package:center_net/features/teacher/models/teacher_home_data.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_teacher_home_repository.dart';

TeacherHomeData _data(int groups) => TeacherHomeData(
  name: 'سارة',
  groupsCount: groups,
  studentsCount: 10,
  subjects: const ['رياضيات'],
  academicYearStart: 2026,
  now: DateTime(2026, 11, 9),
);

void main() {
  test('نجاح: بيعرض البيانات', () async {
    final cubit = TeacherHomeCubit(FakeTeacherHomeRepository(data: _data(2)));
    await cubit.load();
    expect(cubit.state.status, isA<ViewSuccess<TeacherHomeData>>());
    await cubit.close();
  });

  test('من غير مجموعات: حالة فاضية', () async {
    final cubit = TeacherHomeCubit(FakeTeacherHomeRepository(data: _data(0)));
    await cubit.load();
    expect(cubit.state.status, isA<ViewEmpty<TeacherHomeData>>());
    await cubit.close();
  });

  test('فشل: بيعرض الخطأ، وإعادة المحاولة بتنجح', () async {
    final repo = FakeTeacherHomeRepository(
      data: _data(1),
      failure: const Failure.network(),
    );
    final cubit = TeacherHomeCubit(repo);
    await cubit.load();
    expect(cubit.state.status, isA<ViewFailed<TeacherHomeData>>());
    repo.failure = null;
    await cubit.load();
    expect(cubit.state.status, isA<ViewSuccess<TeacherHomeData>>());
    expect(repo.loads, 2);
    await cubit.close();
  });
}
