import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:center_net/features/grades/models/exam.dart';

void main() {
  final fakeServerTime = Timestamp.fromDate(DateTime.utc(2026, 11, 1));
  final examDate = DateTime.utc(2026, 11, 13, 15);

  Exam make({
    String id = 'e1',
    String centerId = 'c1',
    String groupId = 'g1',
    String title = '  امتحان الجبر  ',
    double maxScore = 30,
    String createdBy = 'teacherA',
  }) =>
      Exam.create(
        id: id,
        centerId: centerId,
        groupId: groupId,
        title: title,
        date: examDate,
        maxScore: maxScore,
        createdBy: createdBy,
      );

  group('create', () {
    test('بيقص العنوان وبيبدأ مسودة (غير منشور)', () {
      final e = make();
      expect(e.title, 'امتحان الجبر');
      expect(e.published, isFalse);
      expect(e.maxScore, 30);
    });

    test('بيرفض id أو centerId أو groupId فيهم _ أو فاضيين', () {
      expect(() => make(id: 'e_1'), throwsArgumentError);
      expect(() => make(id: ''), throwsArgumentError);
      expect(() => make(centerId: 'c_1'), throwsArgumentError);
      expect(() => make(groupId: 'g_1'), throwsArgumentError);
      expect(() => make(groupId: ''), throwsArgumentError);
    });

    test('بيرفض عنوان فاضي أو طويل', () {
      expect(() => make(title: '   '), throwsArgumentError);
      expect(() => make(title: 'ا' * 121), throwsArgumentError);
      expect(make(title: 'ا' * 120).title.length, 120);
    });

    test('الدرجة النهائية لازم أكبر من صفر', () {
      expect(() => make(maxScore: 0), throwsArgumentError);
      expect(() => make(maxScore: -5), throwsArgumentError);
      expect(() => make(maxScore: double.nan), throwsArgumentError);
      expect(() => make(maxScore: double.infinity), throwsArgumentError);
      expect(make(maxScore: 0.5).maxScore, 0.5);
    });

    test('بيرفض createdBy فاضي', () {
      expect(() => make(createdBy: ''), throwsArgumentError);
    });
  });

  group('toCreateMap', () {
    test('بيكتب كل الحقول المطلوبة وpublished=false', () {
      final map = make().toCreateMap(createdAt: fakeServerTime);
      expect(map, <String, dynamic>{
        'centerId': 'c1',
        'groupId': 'g1',
        'title': 'امتحان الجبر',
        'date': Timestamp.fromDate(examDate),
        'maxScore': 30.0,
        'published': false,
        'createdAt': fakeServerTime,
        'createdBy': 'teacherA',
      });
    });

    test('الافتراضي serverTimestamp', () {
      expect(make().toCreateMap()['createdAt'], isA<FieldValue>());
    });
  });

  group('fromMap', () {
    Map<String, dynamic> raw({Map<String, dynamic> over = const {}}) =>
        <String, dynamic>{
          'centerId': 'c1',
          'groupId': 'g1',
          'title': 'امتحان',
          'date': Timestamp.fromDate(examDate),
          'maxScore': 30, // int من Firestore
          'published': true,
          'createdAt': fakeServerTime,
          'createdBy': 'teacherA',
          ...over,
        };

    test('بيقرا مستند سليم ويحوّل int لـ double', () {
      final e = Exam.fromMap('e1', raw());
      expect(e.id, 'e1');
      expect(e.maxScore, 30.0);
      expect(e.published, isTrue);
      // Timestamp.toDate() بترجّع وقت محلي، فبنقارن باللحظة مش بالـ isUtc.
      expect(e.date.isAtSameMomentAs(examDate), isTrue);
      expect(e.createdAt!.isAtSameMomentAs(DateTime.utc(2026, 11, 1)), isTrue);
    });

    test('published الناقص = false', () {
      final map = raw()..remove('published');
      expect(Exam.fromMap('e1', map).published, isFalse);
    });

    test('createdAt الفاضي (كاش) = null', () {
      expect(Exam.fromMap('e1', raw(over: {'createdAt': null})).createdAt,
          isNull);
    });

    test('بيرمي FormatException لو المستند تالف', () {
      for (final key in ['centerId', 'groupId', 'title', 'createdBy', 'date']) {
        final map = raw()..remove(key);
        expect(() => Exam.fromMap('e1', map), throwsFormatException,
            reason: key);
      }
      expect(() => Exam.fromMap('e1', raw(over: {'maxScore': 0})),
          throwsFormatException);
      expect(() => Exam.fromMap('e1', raw(over: {'maxScore': 'x'})),
          throwsFormatException);
      expect(() => Exam.fromMap('e1', raw(over: {'maxScore': null})),
          throwsFormatException);
    });

    test('toCreateMap ثم fromMap بيرجّع نفس الامتحان', () {
      final e = Exam.fromMap(
        'e1',
        make().toCreateMap(createdAt: fakeServerTime),
      );
      expect(e.title, 'امتحان الجبر');
      expect(e.groupId, 'g1');
      expect(e.maxScore, 30.0);
      expect(e.published, isFalse);
    });
  });

  group('النشر', () {
    test('النشر وإلغاؤه بيغيّروا published بس', () {
      expect(Exam.toPublishMap(), {'published': true});
      expect(Exam.toUnpublishMap(), {'published': false});
    });
  });

  group('isScoreInRange', () {
    test('من صفر لحد النهائية', () {
      final e = make();
      expect(e.isScoreInRange(0), isTrue);
      expect(e.isScoreInRange(30), isTrue);
      expect(e.isScoreInRange(30.5), isFalse);
      expect(e.isScoreInRange(31), isFalse);
      expect(e.isScoreInRange(-1), isFalse);
    });
  });
}
