import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/errors/failure.dart';
import '../../../core/firestore_paths.dart';
import '../../auth/models/account_type.dart';
import '../../auth/models/app_user.dart';
import '../../staff/models/staff_member.dart';
import '../models/home_destination.dart';

/// بيحدد المستخدم الحالي يروح فين: users/{uid} ثم (للأدمن والموظفين)
/// members/{c}/{uid}. الـ Rules بتسمح للعضو يقرا مستنده حتى لو معطّل.
class RoleRepository {
  RoleRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Future<HomeDestination> resolve() {
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

      final AppUser user;
      try {
        user = AppUser.fromMap(uid, data);
      } on FormatException {
        throw const Failure.unknown();
      }

      MembershipInfo? membership;
      final centerId = user.centerId;
      final isStaffSide = user.accountType == AccountType.admin ||
          user.accountType == AccountType.staff;
      if (centerId != null && isStaffSide) {
        final memberSnap =
            await _db.doc(FirestorePaths.member(centerId, uid)).get();
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
