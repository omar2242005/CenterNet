import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/errors/failure.dart';
import '../../../core/firestore_paths.dart';
import '../../linking/models/student_link.dart';
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

  /// حذف الحساب الحالي نهائيًا (بيانات + حساب Auth).
  ///
  /// الترتيب: منع الأدمن (السنتر ملوش حذف فهيتيتّم) ثم إعادة تحقق بكلمة السر
  /// ثم فك الربط النشط (عشان العدّادات) ثم مسح العضوية ومستند المستخدم
  /// ثم مسح حساب Auth نفسه. تاريخ الحضور والحصص بيفضل لأنه تابع للطالب.
  Future<void> deleteAccount({required String password}) {
    return ErrorMapper.guard(() async {
      final user = _auth.currentUser;
      final email = user?.email;
      if (user == null || email == null) throw const Failure.permission();
      final uid = user.uid;

      final userRef = _db.doc(FirestorePaths.user(uid));
      final userSnap = await userRef.get();
      final centerId = userSnap.data()?['centerId'];

      DocumentReference<Map<String, dynamic>>? memberRef;
      if (centerId is String) {
        final ref = _db.doc(FirestorePaths.member(centerId, uid));
        final m = await ref.get();
        if (m.exists) {
          if (m.data()?['role'] == 'admin') {
            throw const Failure.validation(
              'مينفعش تحذف حساب أدمن سنتر شغال. السنتر هيفضل من غير أدمن.',
            );
          }
          memberRef = ref;
        }
      }

      try {
        await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: email, password: password),
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password' ||
            e.code == 'invalid-credential' ||
            e.code == 'invalid-login-credentials') {
          throw const Failure.validation('كلمة السر غير صحيحة.');
        }
        rethrow;
      }

      if (centerId is String) {
        final snap = await _db
            .collection(FirestorePaths.studentLinks(centerId))
            .where('uid', isEqualTo: uid)
            .get(const GetOptions(source: Source.server));
        for (final doc in snap.docs) {
          final StudentLink link;
          try {
            link = StudentLink.fromMap(doc.id, doc.data());
          } on FormatException {
            continue;
          }
          if (!link.isActive) continue;
          final batch = _db.batch();
          batch.update(doc.reference, StudentLink.toUnlinkMap());
          batch.set(
            _db.doc(FirestorePaths.linkedUser(centerId, uid)),
            <String, dynamic>{
              'count': FieldValue.increment(-1),
              'sid': link.studentId,
            },
            SetOptions(merge: true),
          );
          if (link.kind == LinkKind.guardian) {
            batch.set(
              _db.doc(FirestorePaths.guardianCount(centerId, link.studentId)),
              <String, dynamic>{'count': FieldValue.increment(-1)},
              SetOptions(merge: true),
            );
          }
          await batch.commit();
        }
      }

      final del = _db.batch();
      if (memberRef != null) del.delete(memberRef);
      del.delete(userRef);
      await del.commit();

      await user.delete();
    });
  }
}
