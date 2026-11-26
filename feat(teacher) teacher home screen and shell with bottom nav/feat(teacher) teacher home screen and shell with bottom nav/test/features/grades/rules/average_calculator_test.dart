import 'package:center_net/features/grades/models/exam.dart';
import 'package:center_net/features/grades/models/score.dart';
import 'package:center_net/features/grades/rules/average_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Exam exam(String id, double max, {bool published = true}) =>
      Exam.fromMap(id, {
        'centerId': 'c1',
        'groupId': 'g1',
        'title': 'امتحان',
        'createdBy': 'u1',
        'date': DateTime(2026, 11, 1),
        'maxScore': max,
        'published': published,
      });

  Score scored(String examId, double value, {double max = 100}) =>
      Score.create(
        centerId: 'c1',
        examId: examId,
        studentId: 'st1',
        state: ScoreState.scored,
        maxScore: max,
        createdBy: 'u1',
        score: value,
      );

  Score nonScored(String examId, ScoreState state) => Score.create(
        centerId: 'c1',
        examId: examId,
        studentId: 'st1',
        state: state,
        maxScore: 100,
        createdBy: 'u1',
      );

  test('مفيش درجات = null', () {
    expect(AverageCalculator.percentage(scores: [], exams: []), isNull);
  });

  test('درجة واحدة 80 من 100 = 80%', () {
    final r = AverageCalculator.percentage(
      scores: [scored('e1', 80)],
      exams: [exam('e1', 100)],
    );
    expect(r, 80);
  });

  test('امتحانين بدرجات نهائية مختلفة: 10/10 و50/100 = 60/110', () {
    final r = AverageCalculator.percentage(
      scores: [scored('e1', 10, max: 10), scored('e2', 50)],
      exams: [exam('e1', 10), exam('e2', 100)],
    );
    expect(r, closeTo(60 / 110 * 100, 0.0001));
  });

  test('الصفر درجة حقيقية وبتدخل', () {
    final r = AverageCalculator.percentage(
      scores: [scored('e1', 0), scored('e2', 100)],
      exams: [exam('e1', 100), exam('e2', 100)],
    );
    expect(r, 50);
  });

  test('الغائب والمعفى برّه المتوسط', () {
    final r = AverageCalculator.percentage(
      scores: [
        scored('e1', 90),
        nonScored('e2', ScoreState.absent),
        nonScored('e3', ScoreState.excused),
      ],
      exams: [exam('e1', 100), exam('e2', 100), exam('e3', 100)],
    );
    expect(r, 90);
  });

  test('غائب بس = null', () {
    final r = AverageCalculator.percentage(
      scores: [nonScored('e1', ScoreState.absent)],
      exams: [exam('e1', 100)],
    );
    expect(r, isNull);
  });

  test('onlyPublished: الامتحان غير المنشور مش بيدخل', () {
    final r = AverageCalculator.percentage(
      scores: [scored('e1', 100), scored('e2', 0)],
      exams: [exam('e1', 100), exam('e2', 100, published: false)],
      onlyPublished: true,
    );
    expect(r, 100);
  });

  test('درجة امتحانها مش في القايمة بتتجاهل', () {
    final r = AverageCalculator.percentage(
      scores: [scored('e1', 70), scored('zzz', 0)],
      exams: [exam('e1', 100)],
    );
    expect(r, 70);
  });
}