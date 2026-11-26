import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/features/teacher/cubit/exam_scores_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../students/helpers/fake_students_repository.dart';
import '../helpers/fake_grades_repositories.dart';
import '../helpers/teacher_fixtures.dart';

void main() {
  late FakeScoresRepository scores;
  late ExamScoresCubit cubit;
  final exam = fakeExam('e1', 'g1', DateTime(2026, 11, 1));

  setUp(() {
    scores = FakeScoresRepository(scores: [fakeScore('e1', 's1', 10)]);
    cubit = ExamScoresCubit(
      FakeStudentsRepository(
        students: [
          fakeStudent('s1', 1, ['g1']),
          fakeStudent('s2', 2, ['g1']),
          fakeStudent('s3', 3, ['g1']),
          fakeStudent('s4', 4, ['g2']),
          fakeStudent('s5', 5, ['g1'], status: 'archived'),
        ],
      ),
      scores,
      FakeExamsRepository(),
      fakeGroup('g1'),
      exam,
    );
  });

  tearDown(() => cubit.close());

  test('بيحمّل طلاب المجموعة النشطين بالترتيب ودرجاتهم', () async {
    await cubit.load();
    expect(cubit.state.students.map((s) => s.id), ['s1', 's2', 's3']);
    expect(cubit.state.recordedCount, 1);
  });

  test(
    'saveAll: بيحفظ الصح، بيتخطى الفاضي وغير المتغيّر، وبيرجّع أخطاء الباقي',
    () async {
      await cubit.load();
      final result = await cubit.saveAll({
        's1': '10', // مفيش تغيير
        's2': '25', // أكبر من النهائية (20)
        's3': '', // فاضي: مش صفر
      });
      expect(result.saved, 0);
      expect(result.errors.keys, ['s2']);
      expect(scores.saved, isEmpty);

      final ok = await cubit.saveAll({'s2': '17.5', 's3': '٢٠'});
      expect(ok.saved, 2);
      expect(ok.hasErrors, isFalse);
      expect(scores.saved, ['s2:17.5', 's3:20.0']);
      expect(cubit.state.recordedCount, 3);
    },
  );

  test('خطأ حفظ طالب مايوقفش الباقي', () async {
    scores.saveFailureFor['s2'] = const Failure.network();
    await cubit.load();
    final r = await cubit.saveAll({'s2': '5', 's3': '6'});
    expect(r.saved, 1);
    expect(r.errors.keys, ['s2']);
  });

  test('نص نص: خطوة 0.5 بس', () async {
    await cubit.load();
    final r = await cubit.saveAll({'s2': '5.3'});
    expect(r.saved, 0);
    expect(r.errors.containsKey('s2'), isTrue);
  });

  test('النشر بيغيّر حالة الامتحان', () async {
    await cubit.load();
    expect(cubit.state.exam.published, isFalse);
    expect(await cubit.setPublished(true), isNull);
    expect(cubit.state.exam.published, isTrue);
  });

  test('فشل تحميل الطلاب بيظهر', () async {
    final failing = ExamScoresCubit(
      FakeStudentsRepository(loadFailure: const Failure.network()),
      scores,
      FakeExamsRepository(),
      fakeGroup('g1'),
      exam,
    );
    await failing.load();
    expect(failing.state.failure, isNotNull);
    await failing.close();
  });
}
