import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/errors/failure.dart';
import '../../../core/firestore_paths.dart';
import '../../../core/utils/link_code_generator.dart';
import '../../students/models/student.dart';
import '../models/invite_code.dart';
import '../models/link_request.dart';
import '../models/linked_student.dart';
import '../models/student_link.dart';

/// ربط حسابات الطالب وولي الأمر بالطلاب.
///
/// * الربط Batch واحد: استهلاك الكود + إنشاء/تفعيل `studentLinks` + عدّادات
///   `linkedUsers` و`guardianCounts` (الـ Rules بتتحقق من الأربعة مع بعض).
/// * فك الربط Batch واحد: status = unlinked + إنقاص العدّادات.
/// * الـ Rules هي الحكم: رفضها بيتحوّل لرسالة مفهومة.
class LinkingRepository {
  LinkingRepository(
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

  static const Duration timeout = Duration(seconds: 20);
  static const int maxCodeAttempts = 5;

  /// بيربط الحساب الحالي بالطالب اللي في الكود. [expected] نوع الحساب (طالب/ولي أمر).
  Future<void> redeem(String raw, {required LinkKind expected}) {
    return ErrorMapper.guard(() async {
      final uid = _requireUid();
      final id = LinkCodeGenerator.normalize(raw);
      if (!LinkCodeGenerator.isWellFormed(id)) {
        throw const Failure.validation(
          'الكود غير صحيح. الكود 8 رموز من حروف وأرقام.',
        );
      }

      final codeRef = _db.doc(FirestorePaths.inviteCode(id));
      final codeSnap = await codeRef
          .get(const GetOptions(source: Source.server))
          .timeout(timeout);
      final data = codeSnap.data();
      if (data == null) {
        throw const Failure.notFound(message: 'الكود غير موجود. تأكد منه.');
      }
      final InviteCode code;
      try {
        code = InviteCode.fromMap(codeSnap.id, data);
      } on FormatException {
        throw const Failure.unknown();
      }

      final wanted = expected == LinkKind.student
          ? InviteKind.student
          : InviteKind.guardian;
      if (code.kind != wanted) {
        throw Failure.validation(
          expected == LinkKind.student
              ? 'ده مش كود طالب. اطلب من السنتر كود ربط للطالب.'
              : 'ده مش كود ولي أمر. اطلب من السنتر كود ربط لولي الأمر.',
        );
      }
      switch (code.statusAt(_now())) {
        case InviteCodeStatus.used:
          throw const Failure.validation('الكود ده اتستخدم قبل كده.');
        case InviteCodeStatus.expired:
          throw const Failure.validation('الكود انتهت صلاحيته. اطلب كود جديد.');
        case InviteCodeStatus.valid:
          break;
      }
      final studentId = code.studentId;
      if (studentId == null) throw const Failure.unknown();

      final userRef = _db.doc(FirestorePaths.user(uid));
      final userSnap = await userRef.get().timeout(timeout);
      final currentCenter = userSnap.data()?['centerId'];
      if (currentCenter is String && currentCenter != code.centerId) {
        throw const Failure.validation('حسابك مربوط بسنتر آخر.');
      }

      final linkRef = _db.doc(
        FirestorePaths.studentLink(code.centerId, uid, studentId),
      );
      final existing = await linkRef.get().timeout(timeout);

      final isGuardian = expected == LinkKind.guardian;
      final batch = _db.batch();
      batch.update(codeRef, <String, dynamic>{'usedBy': uid});

      final existingData = existing.data();
      if (existingData != null) {
        final StudentLink current;
        try {
          current = StudentLink.fromMap(existing.id, existingData);
        } on FormatException {
          throw const Failure.unknown();
        }
        if (current.isActive) {
          throw const Failure.alreadyExists(
            message: 'حسابك مربوط بالطالب ده بالفعل.',
          );
        }
        // إعادة ربط بعد فك: نفس الـ id، بكود جديد.
        batch.update(linkRef, <String, dynamic>{
          'status': LinkStatus.active.wire,
          'inviteCode': id,
          if (isGuardian) 'relation': code.relation,
        });
      } else {
        final StudentLink link;
        try {
          link = StudentLink.create(
            centerId: code.centerId,
            uid: uid,
            studentId: studentId,
            kind: expected,
            relation: isGuardian ? code.relation : null,
            inviteCode: id,
          );
        } on ArgumentError {
          throw const Failure.validation('بيانات الكود ناقصة. اطلب كود جديد.');
        }
        batch.set(linkRef, link.toCreateMap());
      }

      batch.set(
        _db.doc(FirestorePaths.linkedUser(code.centerId, uid)),
        <String, dynamic>{'count': FieldValue.increment(1), 'sid': studentId},
        SetOptions(merge: true),
      );
      if (isGuardian) {
        batch.set(
          _db.doc(FirestorePaths.guardianCount(code.centerId, studentId)),
          <String, dynamic>{'count': FieldValue.increment(1)},
          SetOptions(merge: true),
        );
      }
      if (currentCenter == null) {
        batch.update(userRef, <String, dynamic>{
          'centerId': code.centerId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      try {
        await batch.commit().timeout(timeout);
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          throw Failure.validation(
            isGuardian
                ? 'تعذّر الربط. ممكن الطالب وصل لـ ${InviteCode.maxGuardiansPerStudent} '
                    'أولياء أمور، أو الكود اتستخدم.'
                : 'تعذّر الربط. ممكن الكود اتستخدم.',
            code: e.code,
          );
        }
        rethrow;
      }
    });
  }

  /// الطلاب المربوطين (ربط نشط) بالحساب الحالي، مرتبين بالرقم.
  Future<List<LinkedStudent>> loadMyStudents() {
    return ErrorMapper.guard(() async {
      final uid = _requireUid();
      final userSnap =
          await _db.doc(FirestorePaths.user(uid)).get().timeout(timeout);
      final centerId = userSnap.data()?['centerId'];
      if (centerId is! String) return const <LinkedStudent>[];

      final snap = await _db
          .collection(FirestorePaths.studentLinks(centerId))
          .where('uid', isEqualTo: uid)
          .get(const GetOptions(source: Source.server))
          .timeout(timeout);

      final links = <StudentLink>[];
      for (final doc in snap.docs) {
        try {
          final link = StudentLink.fromMap(doc.id, doc.data());
          if (link.isActive) links.add(link);
        } on FormatException {
          continue; // مستند تالف: بنتخطاه
        }
      }

      final loaded = await Future.wait(
        links.map((link) async {
          final s = await _db
              .doc(FirestorePaths.student(centerId, link.studentId))
              .get()
              .timeout(timeout);
          final data = s.data();
          if (data == null) return null;
          try {
            return LinkedStudent(
              link: link,
              student: Student.fromMap(s.id, data),
            );
          } on FormatException {
            return null;
          }
        }),
      );
      final out = loaded.whereType<LinkedStudent>().toList()
        ..sort((a, b) => a.student.studentNo.compareTo(b.student.studentNo));
      return out;
    });
  }

  /// فك الربط (ولي الأمر أو الطالب لنفسه).
  Future<void> unlink(StudentLink link) {
    return ErrorMapper.guard(() async {
      _requireUid();
      final batch = _db.batch();
      batch.update(
        _db.doc(
          FirestorePaths.studentLink(link.centerId, link.uid, link.studentId),
        ),
        StudentLink.toUnlinkMap(),
      );
      batch.set(
        _db.doc(FirestorePaths.linkedUser(link.centerId, link.uid)),
        <String, dynamic>{
          'count': FieldValue.increment(-1),
          'sid': link.studentId,
        },
        SetOptions(merge: true),
      );
      if (link.kind == LinkKind.guardian) {
        batch.set(
          _db.doc(FirestorePaths.guardianCount(link.centerId, link.studentId)),
          <String, dynamic>{'count': FieldValue.increment(-1)},
          SetOptions(merge: true),
        );
      }
      await batch.commit().timeout(timeout);
    });
  }

  /// (أدمن) بيطلّع كود ربط لطالب، أو لولي أمر لو [relation] مبعوتة.
  Future<InviteCode> issueCode(Student student, {String? relation}) {
    return ErrorMapper.guard(() async {
      final uid = _requireUid();
      final rel = relation?.trim();
      if (relation != null && (rel == null || rel.isEmpty)) {
        throw const Failure.validation('اختار صلة القرابة.');
      }
      for (var attempt = 0; attempt < maxCodeAttempts; attempt++) {
        final id = _generateCode();
        final ref = _db.doc(FirestorePaths.inviteCode(id));
        final existing = await ref.get(const GetOptions(source: Source.server));
        if (existing.exists) continue;

        final invite = rel != null
            ? InviteCode.guardian(
                id: id,
                centerId: student.centerId,
                createdBy: uid,
                studentId: student.id,
                relation: rel,
                now: _now(),
              )
            : InviteCode.student(
                id: id,
                centerId: student.centerId,
                createdBy: uid,
                studentId: student.id,
                now: _now(),
              );
        await ref.set(invite.toCreateMap()).timeout(timeout);
        return invite;
      }
      throw const Failure.unknown();
    });
  }

  // ------------------------------------------------------------------
  // طلبات الربط: الطالب/ولي الأمر يطلب، والأدمن يوافق (بيطلّع كود ربط عادي).
  // ------------------------------------------------------------------

  /// بيبعت طلب ربط للأدمن. لو الطلب موجود قبل كده بيرجّعه من غير تكرار.
  Future<LinkRequest> sendRequest({
    required String centerId,
    required int studentNo,
    required LinkKind kind,
    String? relation,
  }) {
    return ErrorMapper.guard(() async {
      final uid = _requireUid();
      final ref = _db.doc(FirestorePaths.linkRequest(centerId, uid, studentNo));
      final old = await ref.get().timeout(timeout);
      final oldData = old.data();
      if (oldData != null) return LinkRequest.fromMap(old.id, oldData);

      final userSnap =
          await _db.doc(FirestorePaths.user(uid)).get().timeout(timeout);
      final name = (userSnap.data()?['name'] as String?) ?? '';
      try {
        await ref
            .set(
              LinkRequest.toCreateMap(
                centerId: centerId,
                uid: uid,
                name: name,
                studentNo: studentNo,
                kind: kind,
                relation: relation,
              ),
            )
            .timeout(timeout);
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          throw const Failure.validation('تعذّر إرسال الطلب. تأكد من كود السنتر.');
        }
        rethrow;
      }
      final fresh = await ref.get().timeout(timeout);
      return LinkRequest.fromMap(fresh.id, fresh.data()!);
    });
  }

  /// آخر حالة للطلب (للتحديث).
  Future<LinkRequest> loadRequest(LinkRequest r) {
    return ErrorMapper.guard(() async {
      final snap = await _db
          .doc(FirestorePaths.linkRequest(r.centerId, r.uid, r.studentNo))
          .get(const GetOptions(source: Source.server))
          .timeout(timeout);
      final data = snap.data();
      if (data == null) throw const Failure.notFound(message: 'الطلب غير موجود.');
      return LinkRequest.fromMap(snap.id, data);
    });
  }

  /// مسح الطلب (إعادة المحاولة بعد الرفض أو إلغاء الطلب).
  Future<void> cancelRequest(LinkRequest r) {
    return ErrorMapper.guard(() async {
      await _db
          .doc(FirestorePaths.linkRequest(r.centerId, r.uid, r.studentNo))
          .delete()
          .timeout(timeout);
    });
  }

  /// بعد موافقة الأدمن: الربط بالكود اللي في الطلب، وبعدها مسح الطلب.
  Future<void> completeRequest(LinkRequest r) async {
    final code = r.code;
    if (r.status != LinkRequestStatus.approved || code == null) {
      throw const Failure.validation('الطلب لسه متوافقش عليه.');
    }
    await redeem(code, expected: r.kind);
    try {
      await cancelRequest(r);
    } on Failure {
      // الربط تم فعلًا، ومسح الطلب مش مهم.
    }
  }

  /// (أدمن) الطلبات اللي لسه مستنية رد.
  Future<List<LinkRequest>> loadPendingRequests() {
    return ErrorMapper.guard(() async {
      final uid = _requireUid();
      final userSnap =
          await _db.doc(FirestorePaths.user(uid)).get().timeout(timeout);
      final centerId = userSnap.data()?['centerId'];
      if (centerId is! String) return const <LinkRequest>[];
      final snap = await _db
          .collection(FirestorePaths.linkRequests(centerId))
          .where('status', isEqualTo: LinkRequestStatus.pending.wire)
          .get()
          .timeout(timeout);
      final out = <LinkRequest>[];
      for (final doc in snap.docs) {
        try {
          out.add(LinkRequest.fromMap(doc.id, doc.data()));
        } on FormatException {
          continue;
        }
      }
      out.sort((a, b) => a.studentNo.compareTo(b.studentNo));
      return out;
    });
  }

  /// (أدمن) موافقة: بيطلّع كود ربط للطالب صاحب الرقم ويكتبه في الطلب.
  Future<void> approveRequest(LinkRequest r) {
    return ErrorMapper.guard(() async {
      final snap = await _db
          .collection(FirestorePaths.students(r.centerId))
          .where('studentNo', isEqualTo: r.studentNo)
          .limit(1)
          .get()
          .timeout(timeout);
      if (snap.docs.isEmpty) {
        throw const Failure.notFound(message: 'مفيش طالب بالرقم ده. ارفض الطلب.');
      }
      final student = Student.fromMap(snap.docs.first.id, snap.docs.first.data());
      final invite = await issueCode(
        student,
        relation: r.kind == LinkKind.guardian ? r.relation : null,
      );
      await _db
          .doc(FirestorePaths.linkRequest(r.centerId, r.uid, r.studentNo))
          .update(<String, dynamic>{
        'status': LinkRequestStatus.approved.wire,
        'code': invite.id,
      }).timeout(timeout);
    });
  }

  /// (أدمن) رفض الطلب.
  Future<void> rejectRequest(LinkRequest r) {
    return ErrorMapper.guard(() async {
      await _db
          .doc(FirestorePaths.linkRequest(r.centerId, r.uid, r.studentNo))
          .update(<String, dynamic>{'status': LinkRequestStatus.rejected.wire})
          .timeout(timeout);
    });
  }

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const Failure.permission();
    return uid;
  }
}
