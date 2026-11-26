import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/features/auth/models/account_type.dart';
import 'package:center_net/features/auth/models/app_user.dart';
import 'package:center_net/features/auth/repository/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Repository مزيف للاختبارات: بيسجّل النداءات، ولو [failure] اتحدد بيرميه.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.failure, this.verified = false});

  Failure? failure;
  bool verified;

  /// البروفايل اللي [loadProfile] بترجّعه.
  AppUser? profile;

  final List<String> calls = <String>[];

  void _maybeFail() {
    final f = failure;
    if (f != null) throw f;
  }

  @override
  User? get currentUser => null;

  @override
  bool get isEmailVerified => verified;

  @override
  Future<void> signIn({required String email, required String password}) async {
    calls.add('signIn:$email');
    _maybeFail();
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required AccountType accountType,
  }) async {
    calls.add('register:$email:${accountType.wire}');
    _maybeFail();
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    calls.add('reset:$email');
    _maybeFail();
  }

  @override
  Future<void> resendVerificationEmail() async {
    calls.add('resend');
    _maybeFail();
  }

  @override
  Future<bool> reloadAndCheckVerified() async {
    calls.add('check');
    _maybeFail();
    return verified;
  }

  @override
  Future<AppUser?> loadProfile() async {
    calls.add('profile');
    _maybeFail();
    return profile;
  }

  @override
  Future<void> signOut() async {
    calls.add('signOut');
  }
}
