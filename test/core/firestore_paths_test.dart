import 'package:center_net/core/firestore_paths.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirestoreIds — أمثلة ثابتة', () {
    test('جلسة: gid_yyyyMMdd_HHmm', () {
      expect(
        FirestoreIds.session('g1', DateTime(2026, 11, 19, 17, 0)),
        'g1_20261119_1700',
      );
    });

    test('جلسة: الأرقام الصغيرة بتتحط عليها أصفار', () {
      expect(
        FirestoreIds.session('g1', DateTime(2026, 1, 5, 9, 5)),
        'g1_20260105_0905',
      );
    });

    test('جلسة: نفس المدخلات = نفس الـ ID (إعادة التوليد مبتكررش)', () {
      final a = FirestoreIds.session('g1', DateTime(2026, 11, 19, 17, 0));
      final b = FirestoreIds.session('g1', DateTime(2026, 11, 19, 17, 0));
      expect(a, b);
    });

    test('جلسة: وقت UTC مرفوض (الـ ID بتوقيت القاهرة)', () {
      expect(
        () => FirestoreIds.session('g1', DateTime.utc(2026, 11, 19, 15, 0)),
        throwsArgumentError,
      );
    });

    test('حضور: sessionId_sid', () {
      expect(
        FirestoreIds.attendance('g1_20261119_1700', 's7'),
        'g1_20261119_1700_s7',
      );
    });

    test('درجة: examId_sid', () {
      expect(FirestoreIds.score('e1', 's7'), 'e1_s7');
    });

    test('ربط: uid_sid', () {
      expect(FirestoreIds.studentLink('u9', 's7'), 'u9_s7');
    });

    test('دفع (P1): sid_gid_yyyyMM', () {
      expect(FirestoreIds.payment('s7', 'g1', 2026, 11), 's7_g1_202611');
      expect(FirestoreIds.payment('s7', 'g1', 2026, 3), 's7_g1_202603');
    });

    test('دفع (P1): شهر غلط مرفوض', () {
      expect(() => FirestoreIds.payment('s7', 'g1', 2026, 13), throwsArgumentError);
      expect(() => FirestoreIds.payment('s7', 'g1', 2026, 0), throwsArgumentError);
    });
  });

  group('FirestoreIds — حماية الفاصل', () {
    test('أي جزء فيه _ أو : أو مسافة أو فاضي أو عربي مرفوض', () {
      for (final bad in ['a_b', 'a:b', 'a b', '', 'أحمد', 'a/b']) {
        expect(() => FirestoreIds.score(bad, 's7'), throwsArgumentError,
            reason: 'examId="$bad"');
        expect(() => FirestoreIds.score('e1', bad), throwsArgumentError,
            reason: 'studentId="$bad"');
        expect(() => FirestoreIds.session(bad, DateTime(2026, 11, 19, 17)),
            throwsArgumentError,
            reason: 'groupId="$bad"');
      }
    });

    test('مفيش تعارض: (a, b_c) و (a_b, c) مش ممكن يطلعوا نفس الـ ID', () {
      // لو الفاصل اتسمح بيه جوه الأجزاء كان الاتنين هيدّوا a_b_c.
      expect(() => FirestoreIds.score('a', 'b_c'), throwsArgumentError);
      expect(() => FirestoreIds.score('a_b', 'c'), throwsArgumentError);
    });
  });

  group('QR: centerId:studentId', () {
    test('بناء', () {
      expect(FirestoreIds.qr('c1', 's7'), 'c1:s7');
    });

    test('قراءة صحيحة (رجوع لنفس القيم)', () {
      final r = FirestoreIds.tryParseQr(FirestoreIds.qr('centerA', 's7'));
      expect(r, isNotNull);
      expect(r!.centerId, 'centerA');
      expect(r.studentId, 's7');
    });

    test('نصوص مش بالصيغة = null (حالة "رمز غير صالح")', () {
      for (final bad in [
        '',
        'c1',
        'c1:',
        ':s7',
        'c1:s7:x',
        ' c1:s7',
        'c1:s7\n',
        'c1 : s7',
        'c1:س7',
        'https://example.com',
      ]) {
        expect(FirestoreIds.tryParseQr(bad), isNull, reason: '"$bad"');
      }
    });
  });

  group('FirestorePaths', () {
    test('الجذر', () {
      expect(FirestorePaths.user('u1'), 'users/u1');
      expect(FirestorePaths.inviteCode('ABCD2345'), 'inviteCodes/ABCD2345');
      expect(FirestorePaths.center('c1'), 'centers/c1');
    });

    test('تحت السنتر (نفس اللي الـ firestore.rules مفترضاه)', () {
      expect(FirestorePaths.member('c1', 'u1'), 'centers/c1/members/u1');
      expect(FirestorePaths.members('c1'), 'centers/c1/members');
      expect(FirestorePaths.student('c1', 's7'), 'centers/c1/students/s7');
      expect(FirestorePaths.group('c1', 'g1'), 'centers/c1/groups/g1');
    });

    test('studentLinks تحت السنتر بـ ID هو uid_sid', () {
      expect(
        FirestorePaths.studentLink('c1', 'u9', 's7'),
        'centers/c1/studentLinks/u9_s7',
      );
    });

    test('جلسة وحضور ودرجة بالـ IDs الحتمية', () {
      final sid = FirestoreIds.session('g1', DateTime(2026, 11, 19, 17, 0));
      expect(FirestorePaths.session('c1', sid), 'centers/c1/sessions/g1_20261119_1700');
      expect(
        FirestorePaths.attendanceDoc('c1', FirestoreIds.attendance(sid, 's7')),
        'centers/c1/attendance/g1_20261119_1700_s7',
      );
      expect(
        FirestorePaths.score('c1', FirestoreIds.score('e1', 's7')),
        'centers/c1/scores/e1_s7',
      );
    });

    test('أي مسار بـ ID فيه / أو فراغ مرفوض', () {
      expect(() => FirestorePaths.center('c1/evil'), throwsArgumentError);
      expect(() => FirestorePaths.student('c1', 's7 '), throwsArgumentError);
      expect(() => FirestorePaths.session('c1', 'a/b'), throwsArgumentError);
    });
  });
}
