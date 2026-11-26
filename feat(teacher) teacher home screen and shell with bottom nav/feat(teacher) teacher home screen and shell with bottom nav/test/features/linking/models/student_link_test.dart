import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:center_net/features/linking/models/student_link.dart';

void main() {
  final fakeServerTime = Timestamp.fromDate(DateTime.utc(2026, 11, 1));

  StudentLink guardian() => StudentLink.create(
        centerId: 'c1',
        uid: 'u9',
        studentId: 's7',
        kind: LinkKind.guardian,
        relation: ' أب ',
      );

  StudentLink student() => StudentLink.create(
        centerId: 'c1',
        uid: 'u8',
        studentId: 's7',
        kind: LinkKind.student,
      );

  group('create', () {
    test('الـ id حتمي بصيغة uid_sid', () {
      expect(guardian().id, 'u9_s7');
      expect(student().id, 'u8_s7');
    });

    test('بيبدأ active وcreatedBy هو صاحب الحساب', () {
      final l = guardian();
      expect(l.status, LinkStatus.active);
      expect(l.isActive, isTrue);
      expect(l.createdBy, 'u9');
    });

    test('ولي الأمر لازم صلة قرابة، والطالب مايبقاش عنده', () {
      expect(
        () => StudentLink.create(
          centerId: 'c1',
          uid: 'u9',
          studentId: 's7',
          kind: LinkKind.guardian,
        ),
        throwsArgumentError,
      );
      expect(
        () => StudentLink.create(
          centerId: 'c1',
          uid: 'u9',
          studentId: 's7',
          kind: LinkKind.guardian,
          relation: '  ',
        ),
        throwsArgumentError,
      );
      expect(
        () => StudentLink.create(
          centerId: 'c1',
          uid: 'u8',
          studentId: 's7',
          kind: LinkKind.student,
          relation: 'أب',
        ),
        throwsArgumentError,
      );
    });

    test('بيرفض أجزاء فيها _ أو فاضية', () {
      expect(
        () => StudentLink.create(
          centerId: 'c1',
          uid: 'u_9',
          studentId: 's7',
          kind: LinkKind.student,
        ),
        throwsArgumentError,
      );
      expect(
        () => StudentLink.create(
          centerId: 'c1',
          uid: 'u9',
          studentId: '',
          kind: LinkKind.student,
        ),
        throwsArgumentError,
      );
    });
  });

  group('toCreateMap / fromMap', () {
    test('ولي الأمر: الحقول المتوقعة وبيقص الصلة', () {
      final m = guardian().toCreateMap(createdAt: fakeServerTime);
      expect(m.keys.toSet(), {
        'centerId', 'uid', 'studentId', 'kind', 'status', 'relation',
        'createdAt', 'createdBy',
      });
      expect(m['kind'], 'guardian');
      expect(m['relation'], 'أب');
    });

    test('الطالب: من غير relation في الـ map', () {
      final m = student().toCreateMap(createdAt: fakeServerTime);
      expect(m.containsKey('relation'), isFalse);
      expect(m['kind'], 'student');
    });

    test('round trip', () {
      final original = guardian();
      final back = StudentLink.fromMap(
        original.id,
        original.toCreateMap(createdAt: fakeServerTime),
      );
      expect(back.id, 'u9_s7');
      expect(back.centerId, 'c1');
      expect(back.uid, 'u9');
      expect(back.studentId, 's7');
      expect(back.kind, LinkKind.guardian);
      expect(back.relation, 'أب');
      expect(back.status, LinkStatus.active);
      expect(back.createdBy, 'u9');
      expect(back.createdAt, isNotNull);
    });

    test('createdAt = null لو السيرفر لسه ماكتبش الوقت', () {
      final m = guardian().toCreateMap(createdAt: fakeServerTime)
        ..['createdAt'] = null;
      expect(StudentLink.fromMap('u9_s7', m).createdAt, isNull);
    });

    test('fromMap بترمي FormatException لو ناقص حقل أو قيمة غريبة', () {
      final good = guardian().toCreateMap(createdAt: fakeServerTime);
      for (final k in ['centerId', 'uid', 'studentId', 'createdBy']) {
        expect(
          () => StudentLink.fromMap('u9_s7', {...good}..remove(k)),
          throwsFormatException,
          reason: k,
        );
      }
      expect(
        () => StudentLink.fromMap('u9_s7', {...good, 'kind': 'weird'}),
        throwsFormatException,
      );
      expect(
        () => StudentLink.fromMap('u9_s7', {...good, 'status': 'weird'}),
        throwsFormatException,
      );
    });
  });

  test('فك الربط بيغيّر الحالة بس', () {
    expect(StudentLink.toUnlinkMap(), {'status': 'unlinked'});
    final unlinked = StudentLink.fromMap(
      'u9_s7',
      {
        ...guardian().toCreateMap(createdAt: fakeServerTime),
        'status': 'unlinked',
      },
    );
    expect(unlinked.isActive, isFalse);
  });
}
