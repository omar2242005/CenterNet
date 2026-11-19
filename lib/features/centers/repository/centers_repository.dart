import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/errors/failure.dart';
import '../../../core/firestore_paths.dart';
import '../models/center_info.dart';

/// إنشاء السنتر وقراءته وتعديل إعداداته.
class CentersRepository {
  CentersRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  /// أقصى مدة انتظار للإنشاء. الإنشاء محتاج نت، فبدل ما الشاشة تفضل
  /// معلّقة (الكتابة بتتحفظ محليًا لو أوفلاين) بنرجّع خطأ شبكة.
  static const Duration createTimeout = Duration(seconds: 20);

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const Failure.permission();
    return uid;
  }

  /// إنشاء سنتر جديد بعملية ذرية (Batch واحد):
  /// `centers/{id}` + `centers/{id}/members/{uid}` بدور admin + `users/{uid}.centerId`.
  /// بيرجّع الـ id الجديد.
  Future<String> createCenter({required String name, required int year}) {
    return ErrorMapper.guard(() async {
      final uid = _uid;
      final userRef = _db.doc(FirestorePaths.user(uid));
      final userSnap = await userRef.get();
      final userData = userSnap.data();
      if (userData == null) throw const Failure.notFound();
      if (userData['centerId'] is String) {
        throw const Failure.alreadyExists(
          message: 'لديك سنتر بالفعل.',
        );
      }

      // معرّف تلقائي: حروف وأرقام بس، فمناسب لـ FirestorePaths.
      final id = _db.collection(FirestorePaths.centers).doc().id;
      final batch = _db.batch();
      batch.set(
        _db.doc(FirestorePaths.center(id)),
        CenterInfo.toCreateMap(name: name, year: year, createdBy: uid),
      );
      batch.set(_db.doc(FirestorePaths.member(id, uid)), <String, dynamic>{
        'role': 'admin',
        'name': (userData['name'] as String?) ?? '',
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': uid,
      });
      batch.update(userRef, <String, dynamic>{
        'centerId': id,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit().timeout(createTimeout);
      return id;
    });
  }

  /// سنتر المستخدم الحالي، أو null لو لسه معندوش سنتر.
  Future<CenterInfo?> loadMyCenter() {
    return ErrorMapper.guard(() async {
      final userSnap = await _db.doc(FirestorePaths.user(_uid)).get();
      final centerId = userSnap.data()?['centerId'];
      if (centerId is! String) return null;
      final snap = await _db.doc(FirestorePaths.center(centerId)).get();
      final data = snap.data();
      if (data == null) return null;
      return CenterInfo.fromMap(snap.id, data);
    });
  }

  /// تعديل الإعدادات (أدمن فقط، والـ Rules هي الحكم).
  Future<void> updateSettings({
    required String centerId,
    required String name,
    required int year,
    required int lateAfterMinutes,
  }) {
    return ErrorMapper.guard(() async {
      await _db.doc(FirestorePaths.center(centerId)).update(
            CenterInfo.toSettingsMap(
              name: name,
              year: year,
              lateAfterMinutes: lateAfterMinutes,
            ),
          );
    });
  }
}
