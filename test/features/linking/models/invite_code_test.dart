import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:center_net/features/linking/models/invite_code.dart';

void main() {
  final now = DateTime.utc(2026, 11, 19, 10);
  final fakeServerTime = Timestamp.fromDate(now);

  InviteCode staff() => InviteCode.staff(
        id: 'K7M2QXAB',
        centerId: 'c1',
        createdBy: 'adminA',
        role: StaffInviteRole.assistant,
        name: '  منى  ',
        now: now,
      );

  InviteCode student() => InviteCode.student(
        id: 'STUD2345',
        centerId: 'c1',
        createdBy: 'adminA',
        studentId: 's7',
        now: now,
      );

  InviteCode guardian() => InviteCode.guardian(
        id: 'GUARD234',
        centerId: 'c1',
        createdBy: 'adminA',
        studentId: 's7',
        relation: 'أب',
        now: now,
      );

  group('toCreateMap', () {
    test('كود موظف: الحقول المتوقعة بالظبط', () {
      final m = staff().toCreateMap(createdAt: fakeServerTime);
      expect(m.keys.toSet(), {
        'centerId', 'kind', 'role', 'name', 'expiresAt',
        'usedBy', 'createdAt', 'createdBy',
      });
      expect(m['kind'], 'staff');
      expect(m['role'], 'assistant');
      expect(m['name'], 'منى'); // اتقصّ
    });

    test('usedBy موجود في الـ map وقيمته null (الـ Rules محتاجاه)', () {
      for (final c in [staff(), student(), guardian()]) {
        final m = c.toCreateMap(createdAt: fakeServerTime);
        expect(m.containsKey('usedBy'), isTrue);
        expect(m['usedBy'], isNull);
      }
    });

    test('كود الطالب: من غير role/name/relation', () {
      final m = student().toCreateMap(createdAt: fakeServerTime);
      expect(m['kind'], 'student');
      expect(m['studentId'], 's7');
      expect(m.containsKey('role'), isFalse);
      expect(m.containsKey('name'), isFalse);
      expect(m.containsKey('relation'), isFalse);
    });

    test('كود ولي الأمر: فيه studentId وrelation', () {
      final m = guardian().toCreateMap(createdAt: fakeServerTime);
      expect(m['kind'], 'guardian');
      expect(m['studentId'], 's7');
      expect(m['relation'], 'أب');
      expect(m.containsKey('role'), isFalse);
    });

    test('expiresAt = الآن + 7 أيام بالظبط', () {
      final m = staff().toCreateMap(createdAt: fakeServerTime);
      final exp = (m['expiresAt'] as Timestamp).toDate().toUtc();
      expect(exp, now.add(const Duration(days: 7)));
    });

    test('createdAt الافتراضي serverTimestamp', () {
      final m = staff().toCreateMap();
      expect(m['createdAt'], isA<FieldValue>());
    });
  });

  group('fromMap', () {
    test('round-trip لكود موظف', () {
      final src = staff().toCreateMap(createdAt: fakeServerTime);
      final c = InviteCode.fromMap('K7M2QXAB', src);
      expect(c.id, 'K7M2QXAB');
      expect(c.kind, InviteKind.staff);
      expect(c.role, StaffInviteRole.assistant);
      expect(c.name, 'منى');
      expect(c.usedBy, isNull);
      expect(c.createdBy, 'adminA');
      expect(c.createdAt, isNotNull);
    });

    test('round-trip لكود ولي أمر', () {
      final c = InviteCode.fromMap(
          'GUARD234', guardian().toCreateMap(createdAt: fakeServerTime));
      expect(c.kind, InviteKind.guardian);
      expect(c.studentId, 's7');
      expect(c.relation, 'أب');
      expect(c.role, isNull);
    });

    test('usedBy مكتوب = كود مستخدم', () {
      final src = staff().toCreateMap(createdAt: fakeServerTime)
        ..['usedBy'] = 'u9';
      final c = InviteCode.fromMap('K7M2QXAB', src);
      expect(c.isUsed, isTrue);
      expect(c.usedBy, 'u9');
    });

    test('createdAt لسه null (كتابة محلية) مش بيرمي', () {
      final src = staff().toCreateMap(createdAt: fakeServerTime)
        ..['createdAt'] = null;
      expect(InviteCode.fromMap('K7M2QXAB', src).createdAt, isNull);
    });

    test('نوع مجهول يرمي FormatException', () {
      final src = staff().toCreateMap(createdAt: fakeServerTime)
        ..['kind'] = 'admin';
      expect(() => InviteCode.fromMap('X', src), throwsFormatException);
    });

    test('كود موظف بدور admin يرمي FormatException', () {
      final src = staff().toCreateMap(createdAt: fakeServerTime)
        ..['role'] = 'admin';
      expect(() => InviteCode.fromMap('X', src), throwsFormatException);
    });

    test('من غير expiresAt يرمي FormatException', () {
      final src = staff().toCreateMap(createdAt: fakeServerTime)
        ..remove('expiresAt');
      expect(() => InviteCode.fromMap('X', src), throwsFormatException);
    });
  });

  group('statusAt', () {
    test('صالح قبل الانتهاء', () {
      expect(staff().statusAt(now.add(const Duration(days: 6))),
          InviteCodeStatus.valid);
    });

    test('منتهي عند وقت الانتهاء بالظبط وبعده', () {
      final end = now.add(const Duration(days: 7));
      expect(staff().statusAt(end), InviteCodeStatus.expired);
      expect(staff().statusAt(end.add(const Duration(seconds: 1))),
          InviteCodeStatus.expired);
    });

    test('المستخدم يغلب المنتهي', () {
      final src = staff().toCreateMap(createdAt: fakeServerTime)
        ..['usedBy'] = 'u9';
      final c = InviteCode.fromMap('K7M2QXAB', src);
      expect(c.statusAt(now.add(const Duration(days: 30))),
          InviteCodeStatus.used);
    });
  });

  group('التحقق في الـ factories', () {
    test('اسم موظف فاضي أو مسافات يرمي', () {
      expect(
        () => InviteCode.staff(
          id: 'K7M2QXAB', centerId: 'c1', createdBy: 'a',
          role: StaffInviteRole.teacher, name: '   ', now: now,
        ),
        throwsArgumentError,
      );
    });

    test('ولي أمر من غير صلة قرابة يرمي', () {
      expect(
        () => InviteCode.guardian(
          id: 'G', centerId: 'c1', createdBy: 'a',
          studentId: 's7', relation: ' ', now: now,
        ),
        throwsArgumentError,
      );
    });

    test('studentId فاضي يرمي', () {
      expect(
        () => InviteCode.student(
          id: 'S', centerId: 'c1', createdBy: 'a', studentId: '', now: now,
        ),
        throwsArgumentError,
      );
    });
  });
}
