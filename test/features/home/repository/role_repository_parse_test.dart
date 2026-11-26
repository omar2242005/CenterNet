import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/features/auth/models/account_type.dart';
import 'package:center_net/features/home/repository/role_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('مستند سليم بنوع حساب جديد (assistant) بيتقري', () {
    final u = RoleRepository.parseUser('u1', {
      'name': 'سارة',
      'accountType': 'assistant',
    });
    expect(u.accountType, AccountType.assistant);
    expect(u.centerId, isNull);
  });

  test('نوع حساب غير معروف: رسالة واضحة بالقيمة', () {
    expect(
      () => RoleRepository.parseUser('u1', {'name': 'x', 'accountType': 'zzz'}),
      throwsA(
        isA<Failure>()
            .having((f) => f.code, 'code', 'bad-user-doc')
            .having((f) => f.message, 'message', contains('zzz')),
      ),
    );
  });

  test('مستند من غير name: نفس الرسالة الواضحة', () {
    expect(
      () => RoleRepository.parseUser('u1', {'accountType': 'staff'}),
      throwsA(isA<Failure>().having((f) => f.code, 'code', 'bad-user-doc')),
    );
  });

  group('retryTransient', () {
    const quick = Duration(milliseconds: 1);

    test(
      'فشل عابر مرتين ثم نجاح: بيرجّع النتيجة من غير ما الشاشة تشوف خطأ',
      () async {
        var n = 0;
        final r = await RoleRepository.retryTransient(() async {
          n++;
          if (n < 3) throw const Failure.unknown();
          return 'ok';
        }, delay: quick);
        expect(r, 'ok');
        expect(n, 3);
      },
    );

    test('بعد 3 محاولات فاشلة بيرمي الخطأ الأخير', () async {
      var n = 0;
      await expectLater(
        RoleRepository.retryTransient(() async {
          n++;
          throw const Failure.network();
        }, delay: quick),
        throwsA(isA<Failure>()),
      );
      expect(n, 3);
    });

    test('بيانات تالفة أو خطأ تحقق: مفيش إعادة', () async {
      var n = 0;
      await expectLater(
        RoleRepository.retryTransient(() async {
          n++;
          throw const Failure.unknown(code: 'bad-user-doc');
        }, delay: quick),
        throwsA(isA<Failure>()),
      );
      expect(n, 1);

      n = 0;
      await expectLater(
        RoleRepository.retryTransient(() async {
          n++;
          throw const Failure.validation('x');
        }, delay: quick),
        throwsA(isA<Failure>()),
      );
      expect(n, 1);
    });
  });
}
