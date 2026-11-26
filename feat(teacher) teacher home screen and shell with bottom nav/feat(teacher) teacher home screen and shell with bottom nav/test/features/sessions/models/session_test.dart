import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:center_net/features/sessions/models/session.dart';

void main() {
  final start = DateTime(2026, 11, 19, 17); // وقت حائط (مش UTC)
  final end = DateTime(2026, 11, 19, 18, 30);
  final fakeServerTime = Timestamp.fromDate(DateTime.utc(2026, 11, 1));

  Session make() => Session.create(
        centerId: 'c1',
        groupId: 'g1',
        cairoStart: start,
        cairoEnd: end,
        createdBy: 'adminA',
      );

  group('create', () {
    test('الـ id حتمي بصيغة gid_yyyyMMdd_HHmm', () {
      expect(make().id, 'g1_20261119_1700');
    });

    test('الحالة الابتدائية scheduled', () {
      expect(make().status, SessionStatus.scheduled);
    });

    test('بترفض UTC', () {
      expect(
        () => Session.create(
          centerId: 'c1',
          groupId: 'g1',
          cairoStart: DateTime.utc(2026, 11, 19, 15),
          cairoEnd: DateTime.utc(2026, 11, 19, 16),
          createdBy: 'adminA',
        ),
        throwsArgumentError,
      );
    });

    test('بترفض نهاية قبل أو تساوي البداية', () {
      expect(
        () => Session.create(
          centerId: 'c1',
          groupId: 'g1',
          cairoStart: start,
          cairoEnd: start,
          createdBy: 'adminA',
        ),
        throwsArgumentError,
      );
    });

    test('بترفض groupId فيه _', () {
      expect(
        () => Session.create(
          centerId: 'c1',
          groupId: 'g_1',
          cairoStart: start,
          cairoEnd: end,
          createdBy: 'adminA',
        ),
        throwsArgumentError,
      );
    });
  });

  group('toCreateMap / fromMap', () {
    test('الحقول المتوقعة بالظبط', () {
      final m = make().toCreateMap(createdAt: fakeServerTime);
      expect(m.keys.toSet(), {
        'centerId', 'groupId', 'startAt', 'endAt',
        'status', 'createdAt', 'createdBy',
      });
      expect(m['status'], 'scheduled');
      expect(m['startAt'], isA<Timestamp>());
    });

    test('round trip', () {
      final original = make();
      final back = Session.fromMap(
        original.id,
        original.toCreateMap(createdAt: fakeServerTime),
      );
      expect(back.id, original.id);
      expect(back.centerId, 'c1');
      expect(back.groupId, 'g1');
      expect(back.startAt.isAtSameMomentAs(start), isTrue);
      expect(back.endAt.isAtSameMomentAs(end), isTrue);
      expect(back.status, SessionStatus.scheduled);
      expect(back.createdBy, 'adminA');
      expect(back.createdAt, isNotNull);
    });

    test('createdAt = null لو السيرفر لسه ماكتبش الوقت', () {
      final m = make().toCreateMap(createdAt: fakeServerTime)
        ..['createdAt'] = null;
      expect(Session.fromMap('g1_20261119_1700', m).createdAt, isNull);
    });

    test('fromMap بترمي FormatException لو ناقص حقل أو الحالة غريبة', () {
      final good = make().toCreateMap(createdAt: fakeServerTime);
      expect(
        () => Session.fromMap('x', {...good}..remove('groupId')),
        throwsFormatException,
      );
      expect(
        () => Session.fromMap('x', {...good}..remove('startAt')),
        throwsFormatException,
      );
      expect(
        () => Session.fromMap('x', {...good, 'status': 'weird'}),
        throwsFormatException,
      );
    });
  });

  group('الإلغاء والاحتساب', () {
    test('toCancelMap بيغيّر الحالة بس', () {
      expect(Session.toCancelMap(), {'status': 'cancelled'});
    });

    test('isCountedAt: لازم تنتهي وماتكونش ملغاة', () {
      final s = make();
      expect(s.isCountedAt(DateTime(2026, 11, 19, 18)), isFalse); // لسه شغالة
      expect(s.isCountedAt(end), isTrue); // لحظة الانتهاء
      expect(s.isCountedAt(DateTime(2026, 11, 20)), isTrue);

      final cancelled = Session.fromMap(
        s.id,
        {...s.toCreateMap(createdAt: fakeServerTime), 'status': 'cancelled'},
      );
      expect(cancelled.isCancelled, isTrue);
      expect(cancelled.isCountedAt(DateTime(2026, 11, 20)), isFalse);
    });
  });
}
