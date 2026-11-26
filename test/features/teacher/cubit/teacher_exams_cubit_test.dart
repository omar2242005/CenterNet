import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/core/state/view_state.dart';
import 'package:center_net/features/teacher/cubit/teacher_exams_cubit.dart';
import 'package:center_net/features/teacher/models/exam_summary.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_grades_repositories.dart';
import '../helpers/teacher_fixtures.dart';

void main() {
  test('فاضي، نجاح، وفشل ثم إعادة محاولة', () async {
    final repo = FakeTeacherExamsRepository(failure: const Failure.network());
    final cubit = TeacherExamsCubit(repo);
    await cubit.load();
    expect(cubit.state.status, isA<ViewFailed<List<ExamSummary>>>());

    repo.failure = null;
    await cubit.load();
    expect(cubit.state.status, isA<ViewEmpty<List<ExamSummary>>>());

    repo.items = [
      ExamSummary(
        exam: fakeExam('e1', 'g1', DateTime(2026, 11, 1)),
        group: fakeGroup('g1'),
        studentCount: 2,
        recordedCount: 1,
      ),
    ];
    await cubit.load();
    expect(cubit.state.status, isA<ViewSuccess<List<ExamSummary>>>());
    expect(repo.loads, 3);
    await cubit.close();
  });
}
