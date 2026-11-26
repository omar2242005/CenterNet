import 'package:center_net/features/teacher/models/exam_summary.dart';
import 'package:center_net/features/teacher/rules/teacher_exams_builder.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_grades_repositories.dart';
import '../helpers/teacher_fixtures.dart';

void main() {
  final now = DateTime(2026, 11, 9, 12);
  final g1 = fakeGroup('g1');
  final g2 = fakeGroup('g2', subject: 'علوم');
  final students = [
    fakeStudent('s1', 1, ['g1']),
    fakeStudent('s2', 2, ['g1']),
    fakeStudent('s3', 3, ['g2']),
  ];

  test('بيبني الملخصات: أرقام الرصد، الأحدث الأول، وبيتجاهل مجموعة مؤرشفة', () {
    final eOld = fakeExam('e1', 'g1', DateTime(2026, 11, 1));
    final eNew = fakeExam('e2', 'g2', DateTime(2026, 11, 8));
    final eArch = fakeExam('e3', 'g3', DateTime(2026, 11, 9));
    final out = buildExamSummaries(
      groups: [
        g1,
        g2,
        fakeGroup('g3', status: 'archived'),
      ],
      students: students,
      exams: [eOld, eNew, eArch],
      scoresByExam: {
        'e1': [fakeScore('e1', 's1', 15), fakeScore('e1', 's2', 10)],
        'e2': [],
      },
    );
    expect(out.map((e) => e.exam.id), ['e2', 'e1']);
    expect(out[1].studentCount, 2);
    expect(out[1].recordedCount, 2);
    expect(out[0].studentCount, 1);
    expect(out[0].recordedCount, 0);
  });

  test('الحالة: قادم / قيد الرصد / تم الرصد', () {
    ExamSummary s(DateTime d, int recorded, int total) => ExamSummary(
      exam: fakeExam('e', 'g1', d),
      group: g1,
      studentCount: total,
      recordedCount: recorded,
    );
    expect(
      s(DateTime(2026, 11, 20), 0, 2).statusAt(now),
      TeacherExamStatus.upcoming,
    );
    expect(
      s(DateTime(2026, 11, 1), 1, 2).statusAt(now),
      TeacherExamStatus.inProgress,
    );
    expect(
      s(DateTime(2026, 11, 1), 2, 2).statusAt(now),
      TeacherExamStatus.graded,
    );
    // مجموعة من غير طلاب مش "تم الرصد".
    expect(
      s(DateTime(2026, 11, 1), 0, 0).statusAt(now),
      TeacherExamStatus.inProgress,
    );
  });

  test('التقسيم حسب المادة بترتيب أول ظهور', () {
    final items = buildExamSummaries(
      groups: [g1, g2],
      students: students,
      exams: [
        fakeExam('a', 'g1', DateTime(2026, 11, 5)),
        fakeExam('b', 'g2', DateTime(2026, 11, 4)),
        fakeExam('c', 'g1', DateTime(2026, 11, 3)),
      ],
      scoresByExam: const {},
    );
    final sections = groupExamsBySubject(items);
    expect(sections.keys.toList(), ['رياضيات', 'علوم']);
    expect(sections['رياضيات']!.length, 2);
  });

  test('المتوسط بيحسب scored بس، وfmtAverage', () {
    expect(averageScore(const []), isNull);
    expect(
      averageScore([
        fakeScore('e', 's1', 18),
        fakeScore('e', 's2', 17),
        fakeScore('e', 's3', null, state: 'absent'),
      ]),
      17.5,
    );
    expect(fmtAverage(18), '18');
    expect(fmtAverage(17.5), '17.5');
    expect(fmtAverage(17.333), '17.3');
  });
}
