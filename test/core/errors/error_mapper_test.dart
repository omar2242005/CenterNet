import 'dart:async';

import 'package:center_net/core/errors/error_mapper.dart';
import 'package:center_net/core/errors/failure.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

FirebaseException fs(String code) =>
    FirebaseException(plugin: 'cloud_firestore', code: code, message: 'raw $code');

FirebaseAuthException au(String code) =>
    FirebaseAuthException(code: code, message: 'raw $code');

final _arabic = RegExp(r'[\u0600-\u06FF]');

void main() {
  group('Firestore', () {
    test('permission-denied يتحول لرسالة عربية مش تقنية', () {
      final f = ErrorMapper.map(fs('permission-denied'));
      expect(f.type, FailureType.permission);
      expect(f.message, matches(_arabic));
      expect(f.message.toLowerCase(), isNot(contains('permission')));
      expect(f.code, 'permission-denied');
    });

    final table = <String, FailureType>{
      'unauthenticated': FailureType.permission,
      'not-found': FailureType.notFound,
      'already-exists': FailureType.alreadyExists,
      'unavailable': FailureType.network,
      'deadline-exceeded': FailureType.network,
      'aborted': FailureType.unknown,
      'resource-exhausted': FailureType.unknown,
      'invalid-argument': FailureType.validation,
      'some-new-code': FailureType.unknown,
    };
    table.forEach((code, type) {
      test('$code → $type برسالة عربية', () {
        final f = ErrorMapper.map(fs(code));
        expect(f.type, type);
        expect(f.message, matches(_arabic));
        expect(f.message, isNot(contains('raw')));
      });
    });
  });

  group('Auth', () {
    final table = <String, FailureType>{
      'invalid-email': FailureType.validation,
      'user-not-found': FailureType.validation,
      'wrong-password': FailureType.validation,
      'invalid-credential': FailureType.validation,
      'user-disabled': FailureType.permission,
      'email-already-in-use': FailureType.alreadyExists,
      'weak-password': FailureType.validation,
      'network-request-failed': FailureType.network,
      'too-many-requests': FailureType.unknown,
      'requires-recent-login': FailureType.permission,
      'some-new-code': FailureType.unknown,
    };
    table.forEach((code, type) {
      test('$code → $type برسالة عربية', () {
        final f = ErrorMapper.map(au(code));
        expect(f.type, type);
        expect(f.message, matches(_arabic));
        expect(f.message, isNot(contains('raw')));
      });
    });

    test('بيانات الدخول الغلط مبتكشفش هل الإيميل موجود', () {
      final a = ErrorMapper.map(au('user-not-found')).message;
      final b = ErrorMapper.map(au('wrong-password')).message;
      expect(a, b);
    });
  });

  group('غير Firebase', () {
    test('TimeoutException → شبكة', () {
      expect(ErrorMapper.map(TimeoutException('x')).type, FailureType.network);
    });

    test('استثناء مجهول → unknown من غير تسريب نصه', () {
      final f = ErrorMapper.map(StateError('تفاصيل داخلية'));
      expect(f.type, FailureType.unknown);
      expect(f.message, isNot(contains('داخلية')));
    });

    test('Failure جاهز بيعدي زي ما هو', () {
      const original = Failure.validation('اسم قصير');
      expect(identical(ErrorMapper.map(original), original), isTrue);
    });
  });

  group('guard', () {
    test('بيرجّع القيمة لو نجح', () async {
      expect(await ErrorMapper.guard(() async => 7), 7);
    });

    test('بيرمي Failure بدل FirebaseException', () async {
      await expectLater(
        ErrorMapper.guard<int>(() async => throw fs('permission-denied')),
        throwsA(isA<Failure>()
            .having((f) => f.type, 'type', FailureType.permission)),
      );
    });
  });
}
