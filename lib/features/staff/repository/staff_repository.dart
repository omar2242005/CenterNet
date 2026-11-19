import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/errors/failure.dart';
import '../../../core/firestore_paths.dart';
import '../../../core/utils/link_code_generator.dart';
import '../../linking/models/invite_code.dart';
import '../models/staff_invite_issued.dart';

/// دعوة الموظفين بكود (جانب الأدمن): إنشاء كود موظف.
///
/// الـ Rules هي الحكم: لو المستخدم مش أدمن في السنتر الكتابة بتترفض
/// ويتحوّل الرفض لـ [Failure.permission].
class StaffRepository {
  StaffRepository(
    this._auth,
    this._db, {
    DateTime Function()? now,
    String Function()? generateCode,
  })  : _now = now ?? DateTime.now,
        _generateCode = generateCode ?? (() => LinkCodeGenerator.generate());

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final DateTime Function() _now;
  final String Function() _generateCode;

  /// أقصى مدة انتظار للكتابة (الإنشاء محتاج نت، زي إنشاء السنتر).
  static const Duration createTimeout = Duration(seconds: 20);

  /// عدد محاولات توليد كود جديد لو الكود طلع متكرر (احتمال شبه معدوم).
  static const int maxCodeAttempts = 5;

  /// بينشئ كود دعوة موظف (معلم أو مساعد) لسنتر الأدمن الحالي.
  ///
  /// الخطوات: يقرا `users/{uid}.centerId` (للتوجيه بس) ← يقرا اسم السنتر ←
  /// يولّد كود ويتأكد إنه مش موجود (من السيرفر) ← يكتب `inviteCodes/{code}`.
  Future<StaffInviteIssued> createStaffInvite({
    required String name,
    required StaffInviteRole role,
  }) {
    return ErrorMapper.guard(() async {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw const Failure.permission();

      if (name.trim().isEmpty) {
        throw const Failure.validation('اكتب اسم الموظف.');
      }

      final userSnap = await _db.doc(FirestorePaths.user(uid)).get();
      final centerId = userSnap.data()?['centerId'];
      if (centerId is! String) {
        throw const Failure.notFound(
          message: 'أنشئ سنتر أولًا قبل دعوة موظفين.',
        );
      }

      final centerSnap = await _db.doc(FirestorePaths.center(centerId)).get();
      final centerName = (centerSnap.data()?['name'] as String?) ?? '';

      for (var attempt = 0; attempt < maxCodeAttempts; attempt++) {
        final id = _generateCode();
        final ref = _db.doc(FirestorePaths.inviteCode(id));

        // من السيرفر مباشرة: لو أوفلاين بيفشل فورًا بدل ما يتعلق.
        final existing = await ref.get(const GetOptions(source: Source.server));
        if (existing.exists) continue;

        final invite = InviteCode.staff(
          id: id,
          centerId: centerId,
          createdBy: uid,
          role: role,
          name: name,
          now: _now(),
        );
        await ref.set(invite.toCreateMap()).timeout(createTimeout);
        return StaffInviteIssued(invite: invite, centerName: centerName);
      }
      throw const Failure.unknown();
    });
  }
}
