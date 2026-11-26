import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/errors/failure.dart';
import '../../../core/firestore_paths.dart';
import '../../auth/models/app_user.dart';
import '../../staff/models/staff_member.dart';
import '../models/home_destination.dart';

/// بيحدد المستخدم الحالي يروح فين: users/{uid} ثم (للأدمن والموظفين)
/// members/{c}/{uid}. الـ Rules بتسمح للعضو يقرا مستنده حتى لو معطّل.
class RoleRepository {
  RoleRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  /// إعادة محاولة تلقائية لأخطاء عابرة (بعد أول دخول لحساب جديد ممكن
  /// التوكن أو مستند المستخدم ما يكونوش ظاهرين لـ Firestore لحظتها).
  /// بيعيد على الشبكة/غير متوقع/لم يُعثر/صلاحية، ومبيعيدش على بيانات تالفة
  /// (`bad-user-doc`) ولا أي نوع تاني. [delay] قابلة للحقن للاختبار.
  static Future<T> retryTransient<T>(
    Future<T> Function() action, {
    int attempts = 3,
    Duration delay = const Duration(milliseconds: 700),
  }) async {
    for (var i = 1; ; i++) {
      try {
        return await action();
      } on Failure catch (f) {
        final transient =
            f.code != 'bad-user-doc' &&
            (f.type == FailureType.network ||
                f.type == FailureType.unknown ||
                f.type == FailureType.notFound ||
                f.type == FailureType.permission);
        if (!transient || i >= attempts) rethrow;
        await Future<void>.delayed(delay * i);
      }
    }
  }

  /// بيحوّل مستند المستخدم لـ [AppUser]. لو شكله غير متوقع (مثلًا accountType
  /// من نسخة أحدث من التطبيق) بيرجّع رسالة واضحة بدل "خطأ غير متوقع" العامة.
  static AppUser parseUser(String uid, Map<String, dynamic> data) {
    try {
      return AppUser.fromMap(uid, data);
    } on FormatException catch (e) {
      throw Failure.unknown(
        message:
            'بيانات حسابك غير مفهومة لهذه النسخة من التطبيق (${e.message}). حدّث التطبيق لآخر نسخة أو تواصل مع مدير السنتر.',
        code: 'bad-user-doc',
      );
    }
  }

  Future<HomeDestination> resolve() {
    return retryTransient(_resolveOnce);
  }

  Future<HomeDestination> _resolveOnce() {
    return ErrorMapper.guard(() async {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw const Failure.permission();

      final userSnap = await _db.doc(FirestorePaths.user(uid)).get();
      final data = userSnap.data();
      if (data == null) {
        throw const Failure.notFound(
          message: 'لم يتم العثور على بيانات حسابك.',
        );
      }

      final user = parseUser(uid, data);

      MembershipInfo? membership;
      final centerId = user.centerId;
      if (centerId != null && user.accountType.isStaffSide) {
        final memberSnap = await _db
            .doc(FirestorePaths.member(centerId, uid))
            .get();
        final memberData = memberSnap.data();
        if (memberData != null) {
          try {
            final m = StaffMember.fromMap(uid, memberData);
            membership = (role: m.role, active: m.active);
          } on FormatException {
            throw const Failure.unknown();
          }
        }
      }

      return decideHome(
        accountType: user.accountType,
        centerId: centerId,
        membership: membership,
      );
    });
  }
}
