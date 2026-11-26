import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'failure.dart';

/// بيحوّل أي استثناء لـ [Failure] برسالة عربية. مكان واحد مشترك.
///
/// الاستخدام في الـ Repository:
/// ```dart
/// Future<Student> get(String id) => ErrorMapper.guard(() async { ... });
/// ```
class ErrorMapper {
  const ErrorMapper._();

  /// بينفّذ [action] ولو رمى أي استثناء بيرمي [Failure] بداله.
  static Future<T> guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      throw map(e);
    }
  }

  static Failure map(Object error) {
    if (error is Failure) return error;
    // FirebaseAuthException بترث من FirebaseException، فلازم تتفحص الأول.
    if (error is FirebaseAuthException) return _auth(error);
    if (error is FirebaseException) return _firebase(error);
    if (error is TimeoutException) return const Failure.network();
    return const Failure.unknown();
  }

  static Failure _firebase(FirebaseException e) {
    final code = e.code;
    switch (code) {
      case 'permission-denied':
        return Failure.permission(code: code);
      case 'unauthenticated':
        return Failure.permission(
            message: 'انتهت الجلسة. سجّل الدخول مرة أخرى.', code: code);
      case 'not-found':
        return Failure.notFound(code: code);
      case 'already-exists':
        return Failure.alreadyExists(code: code);
      case 'unavailable':
      case 'deadline-exceeded':
        return Failure.network(code: code);
      case 'aborted':
        return Failure.unknown(
            message: 'تعارضت العملية مع تعديل آخر. حاول مرة أخرى.', code: code);
      case 'resource-exhausted':
        return Failure.unknown(
            message: 'تم تجاوز الحد المسموح مؤقتًا. حاول لاحقًا.', code: code);
      case 'invalid-argument':
        return Failure.validation('البيانات المدخلة غير صالحة.', code: code);
      default:
        return Failure.unknown(code: code);
    }
  }

  static Failure _auth(FirebaseAuthException e) {
    final code = e.code;
    switch (code) {
      case 'invalid-email':
        return Failure.validation('البريد الإلكتروني غير صالح.', code: code);
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return Failure.validation(
            'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
            code: code);
      case 'user-disabled':
        return Failure.permission(
            message: 'هذا الحساب معطّل. تواصل مع إدارة المركز.', code: code);
      case 'email-already-in-use':
        return Failure.alreadyExists(
            message: 'هذا البريد الإلكتروني مسجّل بالفعل.', code: code);
      case 'weak-password':
        return Failure.validation(
            'كلمة المرور ضعيفة. استخدم 8 حروف على الأقل.',
            code: code);
      case 'network-request-failed':
        return Failure.network(code: code);
      case 'too-many-requests':
        return Failure.unknown(
            message: 'محاولات كثيرة. انتظر قليلًا ثم حاول مرة أخرى.',
            code: code);
      case 'requires-recent-login':
        return Failure.permission(
            message: 'سجّل الدخول من جديد قبل تنفيذ هذه العملية.', code: code);
      default:
        return Failure.unknown(code: code);
    }
  }
}
