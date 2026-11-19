import 'package:center_net/features/auth/models/account_type.dart';
import 'package:center_net/features/auth/models/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AccountType', () {
    test('parse بيرجّع النوع الصح', () {
      for (final t in AccountType.values) {
        expect(AccountType.parse(t.wire), t);
      }
    });

    test('parse بيرمي FormatException لقيمة غريبة', () {
      expect(() => AccountType.parse('owner'), throwsFormatException);
      expect(() => AccountType.parse(null), throwsFormatException);
    });
  });

  group('AppUser', () {
    test('toCreateMap: الحقول اللي الـ Rules بتسمح بيها بس، من غير centerId', () {
      final map = AppUser.toCreateMap(
        uid: 'u1',
        name: '  أحمد علي ',
        email: ' a@b.com ',
        phone: '01012345678',
        accountType: AccountType.guardian,
        createdAt: 'TS',
      );
      expect(map, {
        'name': 'أحمد علي',
        'email': 'a@b.com',
        'phone': '01012345678',
        'accountType': 'guardian',
        'createdAt': 'TS',
        'createdBy': 'u1',
      });
      expect(map.containsKey('centerId'), isFalse);
      expect(map.containsKey('password'), isFalse);
    });

    test('fromMap بيقرا الحقول و centerId الاختياري', () {
      final u = AppUser.fromMap('u1', {
        'name': 'سارة',
        'email': 's@x.com',
        'phone': '01112345678',
        'accountType': 'staff',
        'centerId': 'c1',
      });
      expect(u.uid, 'u1');
      expect(u.accountType, AccountType.staff);
      expect(u.centerId, 'c1');

      final noCenter = AppUser.fromMap('u2', {
        'name': 'سارة',
        'accountType': 'admin',
      });
      expect(noCenter.centerId, isNull);
      expect(noCenter.email, '');
    });

    test('fromMap بيرمي FormatException لو name ناقص', () {
      expect(
        () => AppUser.fromMap('u1', {'accountType': 'admin'}),
        throwsFormatException,
      );
    });
  });
}
