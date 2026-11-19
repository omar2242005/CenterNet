import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failure.dart';
import '../models/account_type.dart';
import '../models/register_draft.dart';
import '../repository/auth_repository.dart';

enum AuthFormStatus { idle, submitting, success, failure }

/// آخر عملية اتنفذت، عشان الشاشة تعرض الرسالة الصح.
enum AuthFormAction {
  none,
  login,
  register,
  resetPassword,
  resendVerification,
  checkVerified,
}

class AuthFormState {
  const AuthFormState({
    this.status = AuthFormStatus.idle,
    this.action = AuthFormAction.none,
    this.failure,
    this.emailVerified,
  });

  final AuthFormStatus status;
  final AuthFormAction action;
  final Failure? failure;

  /// بيتملي بعد login / register / checkVerified.
  final bool? emailVerified;

  bool get isSubmitting => status == AuthFormStatus.submitting;
}

/// عمليات شاشات الدخول والتسجيل ونسيت كلمة السر وتحقق الإيميل.
class AuthFormCubit extends Cubit<AuthFormState> {
  AuthFormCubit(this._repo) : super(const AuthFormState());

  final AuthRepository _repo;

  Future<void> login({required String email, required String password}) {
    return _run(AuthFormAction.login, () async {
      await _repo.signIn(email: email, password: password);
      return _repo.isEmailVerified;
    });
  }

  Future<void> register({
    required RegisterDraft draft,
    required AccountType accountType,
  }) {
    return _run(AuthFormAction.register, () async {
      await _repo.register(
        name: draft.name,
        email: draft.email,
        phone: draft.phone,
        password: draft.password,
        accountType: accountType,
      );
      return _repo.isEmailVerified;
    });
  }

  Future<void> resetPassword(String email) {
    return _run(AuthFormAction.resetPassword, () async {
      await _repo.sendPasswordReset(email);
      return null;
    });
  }

  Future<void> resendVerification() {
    return _run(AuthFormAction.resendVerification, () async {
      await _repo.resendVerificationEmail();
      return null;
    });
  }

  Future<void> checkVerified() {
    return _run(
      AuthFormAction.checkVerified,
      () => _repo.reloadAndCheckVerified(),
    );
  }

  Future<void> _run(
    AuthFormAction action,
    Future<bool?> Function() body,
  ) async {
    if (state.isSubmitting) return;
    emit(AuthFormState(status: AuthFormStatus.submitting, action: action));
    try {
      final verified = await body();
      if (isClosed) return;
      emit(AuthFormState(
        status: AuthFormStatus.success,
        action: action,
        emailVerified: verified,
      ));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(AuthFormState(
        status: AuthFormStatus.failure,
        action: action,
        failure: f,
      ));
    }
  }
}
