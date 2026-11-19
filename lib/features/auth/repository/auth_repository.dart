import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/errors/failure.dart';
import '../../../core/firestore_paths.dart';
import '../models/account_type.dart';
import '../models/app_user.dart';

/// كل كلام Firebase Auth و`users/{uid}`. أي استثناء بيتحوّل لـ [Failure]
/// برسالة عربية جوه الدوال دي، فالـ Cubit والشاشة مبيشوفوش Firebase.
class AuthRepository {
  AuthRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  /// المستخدم الحالي (متزامن). null = مفيش تسجيل دخول.
  User? get currentUser => _auth.currentUser;

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  Future<void> signIn({required String email, required String password}) {
    return ErrorMapper.guard(() async {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    });
  }

  /// إنشاء حساب: Auth ثم `users/{uid}` ثم إيميل التحقق.
  /// لو كتابة `users/{uid}` فشلت بنمسح حساب Auth الجديد (best effort)
  /// عشان مفيش حساب من غير مستند.
  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required AccountType accountType,
  }) {
    return ErrorMapper.guard(() async {
      await _auth.setLanguageCode('ar');
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user;
      if (user == null) throw const Failure.unknown();

      try {
        await _db.doc(FirestorePaths.user(user.uid)).set(
              AppUser.toCreateMap(
                uid: user.uid,
                name: name,
                email: email,
                phone: phone,
                accountType: accountType,
              ),
            );
      } catch (_) {
        try {
          await user.delete();
        } catch (_) {
          // لو المسح فشل، المستخدم هيسجّل دخول وهنكمل له مستنده لاحقًا.
        }
        rethrow;
      }

      try {
        await user.sendEmailVerification();
      } catch (_) {
        // مش حرج: الشاشة التالية فيها زر "إعادة إرسال".
      }
    });
  }

  Future<void> sendPasswordReset(String email) {
    return ErrorMapper.guard(() async {
      await _auth.setLanguageCode('ar');
      await _auth.sendPasswordResetEmail(email: email.trim());
    });
  }

  Future<void> resendVerificationEmail() {
    return ErrorMapper.guard(() async {
      final user = _auth.currentUser;
      if (user == null) throw const Failure.permission();
      await _auth.setLanguageCode('ar');
      await user.sendEmailVerification();
    });
  }

  /// بيحدّث المستخدم من السيرفر ويرجّع هل الإيميل اتأكد.
  Future<bool> reloadAndCheckVerified() {
    return ErrorMapper.guard(() async {
      final user = _auth.currentUser;
      if (user == null) throw const Failure.permission();
      await user.reload();
      return _auth.currentUser?.emailVerified ?? false;
    });
  }

  /// مستند المستخدم الحالي، أو null لو مش موجود أو مفيش تسجيل دخول.
  Future<AppUser?> loadProfile() {
    return ErrorMapper.guard(() async {
      final user = _auth.currentUser;
      if (user == null) return null;
      final snap = await _db.doc(FirestorePaths.user(user.uid)).get();
      final data = snap.data();
      if (data == null) return null;
      return AppUser.fromMap(user.uid, data);
    });
  }

  Future<void> signOut() => ErrorMapper.guard(() => _auth.signOut());
}
