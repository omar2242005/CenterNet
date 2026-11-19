import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/errors/failure.dart';
import '../../../core/firestore_paths.dart';
import '../../../core/utils/digits.dart';
import '../../../core/utils/link_code_generator.dart';
import '../../linking/models/invite_code.dart';
import '../models/staff_join_result.dart';

/// قبول كود دعوة موظف (جانب الموظف).
///
/// القبول عملية واحدة ذرية (Batch): عضوية `members/{uid}` + تعليم الكود
/// مستخدم + `users/{uid}.centerId`. الفحوصات هنا لرسائل خطأ عربية واضحة بس،
/// والـ Rules هي الحكم الحقيقي.
class StaffJoinRepository {
  StaffJoinRepository(
    this._auth,
    this._db, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final DateTime Function() _now;

  static const Duration commitTimeout = Duration(seconds: 20);

  Future<StaffJoinResult> acceptStaffInvite(String rawCode) {
    return ErrorMapper.guard(() async {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw const Failure.permission();

      final code = LinkCodeGenerator.normalize(toLatinDigits(rawCode));
      if (!LinkCodeGenerator.isWellFormed(code)) {
        throw const Failure.validation(
          'الكود غير صحيح. الكود يتكون من 8 رموز.',
        );
      }

      final userRef = _db.doc(FirestorePaths.user(uid));
      final userData = (await userRef.get()).data();
      if (userData == null) throw const Failure.notFound();
      if (userData['centerId'] is String) {
        throw const Failure.alreadyExists(
          message: 'أنت عضو في سنتر بالفعل.',
        );
      }

      // get واحد على الكود من السيرفر (مفيش بحث).
      final codeRef = _db.doc(FirestorePaths.inviteCode(code));
      final codeSnap =
          await codeRef.get(const GetOptions(source: Source.server));
      final codeData = codeSnap.data();
      if (codeData == null) {
        throw const Failure.notFound(
          message: 'الكود غير موجود. تأكد من كتابته بشكل صحيح.',
        );
      }

      final invite = _parse(codeSnap.id, codeData);
      if (invite.kind != InviteKind.staff) {
        throw const Failure.validation('هذا الكود ليس كود دعوة موظف.');
      }
      if (invite.isUsed) {
        throw const Failure.validation('هذا الكود مستخدم بالفعل.');
      }
      if (invite.isExpired(_now())) {
        throw const Failure.validation(
          'انتهت صلاحية هذا الكود. اطلب كودًا جديدًا من مدير السنتر.',
        );
      }

      final role = invite.role;
      if (role == null) throw const Failure.validation('هذا الكود غير صالح.');

      final ownName = (userData['name'] as String?)?.trim() ?? '';
      final memberName = ownName.isNotEmpty ? ownName : (invite.name ?? '');

      final batch = _db.batch();
      batch.set(
        _db.doc(FirestorePaths.member(invite.centerId, uid)),
        <String, dynamic>{
          'role': role.wire,
          'name': memberName,
          'active': true,
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': uid,
          'inviteCode': invite.id,
        },
      );
      batch.update(codeRef, <String, dynamic>{'usedBy': uid});
      batch.update(userRef, <String, dynamic>{
        'centerId': invite.centerId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      try {
        await batch.commit().timeout(commitTimeout);
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          throw Failure.permission(
            message:
                'تعذر قبول الكود. ربما استُخدم الآن أو انتهت صلاحيته أو أُلغي.',
            code: e.code,
          );
        }
        rethrow;
      }

      // بعد الانضمام بقى عضو، فيقدر يقرا السنتر. لو فشلت القراءة الانضمام نجح.
      var centerName = '';
      try {
        final center = await _db.doc(FirestorePaths.center(invite.centerId)).get();
        centerName = (center.data()?['name'] as String?) ?? '';
      } catch (_) {}

      return StaffJoinResult(
        centerId: invite.centerId,
        centerName: centerName,
        role: role,
      );
    });
  }

  static InviteCode _parse(String id, Map<String, dynamic> data) {
    try {
      return InviteCode.fromMap(id, data);
    } on FormatException {
      throw const Failure.validation('هذا الكود غير صالح.');
    }
  }
}
