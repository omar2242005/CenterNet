import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:center_net/features/grades/models/score.dart';

void main() {
  final fakeServerTime = Timestamp.fromDate(DateTime.utc(2026, 11, 1));

  Score make({
    String centerId = 'c1',
    String examId = 'e1',
    String studentId = 's7',
    ScoreState state = ScoreState.scored,
    double? score = 27,
    double maxScore = 30,
    String comment = '',
    String createdBy = 'teacherA',
  }) =>
      Score.create(
        centerId: centerId,
        examId: examId,
        studentId: studentId,
        state: state,
        score: score,
        maxScore: maxScore,
        comment: comment,
        createdBy: createdBy,
      );

  group('ScoreState', () {
    test('wire والـ parse', () {
      expect(ScoreState.scored.wire, 'scored');
      expect(ScoreState.absent.wire, 'absent');
      expect(ScoreState.excused.wire, 'excused');
      for (final s in ScoreState.values) {
        expect(ScoreState.parse(s.wire), s);
      }
      expect(() => ScoreState.parse('x'), throwsFormatException);
      expect(() => ScoreState.parse(null), throwsFormatException);
    });
  });

  group('create — الدرجة', () {
    test('الـ id حتمي examId_sid', () {
      expect(make().id, 'e1_s7');
    });

    test('درجة عادية وبنص درجة', () {
      expect(make(score: 27).score, 27);
      expect(make(score: 22.5).score, 22.5);
    });

    test('الصفر درجة حقيقية', () {
      final s = make(score: 0);
      expect(s.score, 0);
      expect(s.isCounted, isTrue);
    });

    test('الدرجة النهائية مقبولة، وأكتر منها مرفوض (31 على 30)', () {
      expect(make(score: 30).score, 30);
      expect(() => make(score: 31), throwsArgumentError);
      expect(() => make(score: 30.5), throwsArgumentError);
    });

    test('الدرجة السالبة مرفوضة (-1)', () {
      expect(() => make(score: -1), throwsArgumentError);
      expect(() => make(score: -0.5), throwsArgumentError);
    });

    test('بيرفض خطوة غير 0.5', () {
      expect(() => make(score: 22.3), throwsArgumentError);
      expect(() => make(score: 0.25), throwsArgumentError);
    });

    test('بيرفض NaN وinfinity', () {
      expect(() => make(score: double.nan), throwsArgumentError);
      expect(() => make(score: double.infinity), throwsArgumentError);
    });

    test('الخانة الفاضية مش صفر: scored من غير درجة مرفوض', () {
      expect(() => make(score: null), throwsArgumentError);
    });
  });

  group('create — غائب / معفى', () {
    test('غائب ومعفى من غير درجة', () {
      for (final st in [ScoreState.absent, ScoreState.excused]) {
        final s = make(state: st, score: null);
        expect(s.score, isNull);
        expect(s.isCounted, isFalse);
      }
    });

    test('غائب أو معفى ومعاه درجة مرفوض', () {
      expect(() => make(state: ScoreState.absent, score: 0),
          throwsArgumentError);
      expect(() => make(state: ScoreState.excused, score: 10),
          throwsArgumentError);
    });
  });

  group('create — باقي الحقول', () {
    test('بيقص التعليق وبيرفض الطويل', () {
      expect(make(comment: '  شاطر  ').comment, 'شاطر');
      expect(() => make(comment: 'ا' * 301), throwsArgumentError);
      expect(make(comment: 'ا' * 300).comment.length, 300);
    });

    test('بيرفض ids فيها _ أو فاضية', () {
      expect(() => make(centerId: 'c_1'), throwsArgumentError);
      expect(() => make(examId: 'e_1'), throwsArgumentError);
      expect(() => make(studentId: 's_7'), throwsArgumentError);
      expect(() => make(examId: ''), throwsArgumentError);
      expect(() => make(studentId: ''), throwsArgumentError);
    });

    test('بيرفض createdBy فاضي', () {
      expect(() => make(createdBy: ''), throwsArgumentError);
    });
  });

  group('toCreateMap', () {
    test('درجة مرصودة', () {
      final map = make(comment: 'تمام').toCreateMap(createdAt: fakeServerTime);
      expect(map, <String, dynamic>{
        'centerId': 'c1',
        'examId': 'e1',
        'studentId': 's7',
        'state': 'scored',
        'score': 27.0,
        'comment': 'تمام',
        'createdAt': fakeServerTime,
        'createdBy': 'teacherA',
      });
    });

    test('غائب: score صريحة null (مش ناقصة)', () {
      final map = make(state: ScoreState.absent, score: null).toCreateMap();
      expect(map.containsKey('score'), isTrue);
      expect(map['score'], isNull);
      expect(map['state'], 'absent');
      expect(map['createdAt'], isA<FieldValue>());
    });
  });

  group('fromMap', () {
    Map<String, dynamic> raw({Map<String, dynamic> over = const {}}) =>
        <String, dynamic>{
          'centerId': 'c1',
          'examId': 'e1',
          'studentId': 's7',
          'state': 'scored',
          'score': 22, // int من Firestore
          'comment': 'كويس',
          'createdAt': fakeServerTime,
          'createdBy': 'teacherA',
          ...over,
        };

    test('بيقرا مستند سليم ويحوّل int لـ double', () {
      final s = Score.fromMap('e1_s7', raw());
      expect(s.id, 'e1_s7');
      expect(s.score, 22.0);
      expect(s.state, ScoreState.scored);
      expect(s.comment, 'كويس');
      expect(s.isCounted, isTrue);
      expect(s.createdAt!.isAtSameMomentAs(DateTime.utc(2026, 11, 1)), isTrue);
    });

    test('الصفر بيتقرا صفر مش null', () {
      expect(Score.fromMap('e1_s7', raw(over: {'score': 0})).score, 0.0);
    });

    test('غائب ومعفى بدرجة null', () {
      final s = Score.fromMap(
          'e1_s7', raw(over: {'state': 'absent', 'score': null}));
      expect(s.state, ScoreState.absent);
      expect(s.score, isNull);
      expect(s.isCounted, isFalse);
    });

    test('التعليق الناقص = نص فاضي', () {
      final map = raw()..remove('comment');
      expect(Score.fromMap('e1_s7', map).comment, '');
    });

    test('بيرمي FormatException لو المستند تالف', () {
      for (final key in [
        'centerId',
        'examId',
        'studentId',
        'createdBy',
        'state',
      ]) {
        final map = raw()..remove(key);
        expect(() => Score.fromMap('e1_s7', map), throwsFormatException,
            reason: key);
      }
      // scored من غير درجة / بدرجة سالبة / نص
      expect(() => Score.fromMap('e1_s7', raw(over: {'score': null})),
          throwsFormatException);
      expect(() => Score.fromMap('e1_s7', raw(over: {'score': -1})),
          throwsFormatException);
      expect(() => Score.fromMap('e1_s7', raw(over: {'score': 'x'})),
          throwsFormatException);
      // غائب وليه درجة
      expect(
          () => Score.fromMap(
              'e1_s7', raw(over: {'state': 'absent', 'score': 5})),
          throwsFormatException);
      expect(() => Score.fromMap('e1_s7', raw(over: {'state': 'late'})),
          throwsFormatException);
    });

    test('toCreateMap ثم fromMap بيرجّع نفس الرصد', () {
      final s = Score.fromMap(
        'e1_s7',
        make(score: 22.5, comment: 'تمام').toCreateMap(createdAt: fakeServerTime),
      );
      expect(s.score, 22.5);
      expect(s.comment, 'تمام');
      expect(s.state, ScoreState.scored);
    });
  });
}
