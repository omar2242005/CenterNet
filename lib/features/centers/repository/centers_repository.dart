import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/errors/failure.dart';
import '../../../core/firestore_paths.dart';
import '../../auth/models/app_user.dart';
import '../models/center_info.dart';
import '../models/center_member.dart';

/// كل كلام Firestore الخاص بالسنتر (`centers/{c}` و `members/{uid}`) وربطه
/// بـ `users/{uid}.centerId`. أي استثناء بيتحوّل لـ [Failure] برسالة عربية.
class CentersRepository {
  CentersRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const Failure.permission();
    return uid;
  }

  /// إنشاء سنتر جديد. **Batch واحد** (كله أو لا شيء):
  ///  1. `centers/{id}`
  ///  2. `centers/{id}/members/{uid}` بدور admin
  ///  3. `users/{uid}.centerId`
  ///
  /// الـ Rules بتتحقق من الـ 3 مع بعض (existsAfter / getAfter)، فمينفعش
  /// نكتبهم في عمليات منفصلة.
  ///
  /// ملحوظة أوفلاين: Firestore بيحط الـ Batch في الطابور ومبيخلّصش غير لما
  /// الاتصال يرجع، ومفيش timeout هنا عن قصد (إعادة المحاولة كانت هتعمل
  /// سنتر تاني). الشاشة بتعرض مؤشر تحميل لحد ما يخلص.
  Future<CenterInfo> createCenter({required String name, required int year}) {
    return ErrorMapper.guard(() async {
      final uid = _requireUid();

      final userSnap = await _db.doc(FirestorePaths.user(uid)).get();
      final userData = userSnap.data();
      if (userData == null) {
        throw const Failure.notFound(
          message:
              'بيانات حسابك غير موجودة. سجّل الخروج ثم الدخول وحاول مرة أخرى.',
        );
      }
      final user = AppUser.fromMap(uid, userData);
      if (user.centerId != null) {
        throw const Failure.alreadyExists(
          message: 'لديك مركز بالفعل ولا يمكنك إنشاء مركز آخر.',
        );
      }

      // ID عشوائي (حروف وأرقام) من Firestore، جاهز قبل الكتابة.
      final centerRef = _db.collection(FirestorePaths.centers).doc();
      final centerId = centerRef.id;

      final batch = _db.batch();
      batch.set(
        centerRef,
        CenterInfo.toCreateMap(uid: uid, name: name, year: year),
      );
      batch.set(
        _db.doc(FirestorePaths.member(centerId, uid)),
        CenterMember.toAdminCreateMap(uid: uid, name: user.name),
      );
      batch.update(_db.doc(FirestorePaths.user(uid)), <String, dynamic>{
        'centerId': centerId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();

      return CenterInfo(id: centerId, name: name, year: year);
    });
  }

  /// سنتر المستخدم الحالي وعضويته فيه، أو null لو مالوش سنتر.
  ///
  /// الـ centerId بييجي من `users/{uid}` (للتوجيه فقط)، لكن الصلاحية الحقيقية
  /// من مستند العضو: لو مفيش عضوية بنرجّع null بدل ما نثق في الـ centerId.
  Future<CenterContext?> loadMine() {
    return ErrorMapper.guard(() async {
      final uid = _requireUid();
      final userSnap = await _db.doc(FirestorePaths.user(uid)).get();
      final userData = userSnap.data();
      if (userData == null) return null;
      final centerId = AppUser.fromMap(uid, userData).centerId;
      if (centerId == null) return null;

      final memberSnap = await _db
          .doc(FirestorePaths.member(centerId, uid))
          .get();
      final memberData = memberSnap.data();
      if (memberData == null) return null;

      final centerSnap = await _db.doc(FirestorePaths.center(centerId)).get();
      final centerData = centerSnap.data();
      if (centerData == null) return null;

      return CenterContext(
        center: CenterInfo.fromMap(centerId, centerData),
        membership: CenterMember.fromMap(uid, memberData),
      );
    });
  }

  /// تعديل إعدادات السنتر (الأدمن فقط، والـ Rules هي الحكم).
  /// بيكتب الحقول المسموحة بس: name و year و lateAfterMinutes.
  Future<void> updateSettings({
    required String centerId,
    required String name,
    required int year,
    required int lateAfterMinutes,
  }) {
    return ErrorMapper.guard(() async {
      _requireUid();
      await _db
          .doc(FirestorePaths.center(centerId))
          .update(
            CenterInfo.toSettingsMap(
              name: name,
              year: year,
              lateAfterMinutes: lateAfterMinutes,
            ),
          );
    });
  }
}
