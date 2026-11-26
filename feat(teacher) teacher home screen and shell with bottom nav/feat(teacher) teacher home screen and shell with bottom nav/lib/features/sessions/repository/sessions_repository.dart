import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/errors/error_mapper.dart';
import '../../../core/errors/failure.dart';
import '../../../core/firestore_paths.dart';
import '../../groups/models/group.dart';
import '../models/session.dart';
import '../rules/session_generator.dart';

/// نتيجة "إنشاء الأسابيع الجاية": كام حصة اتكتبت وكام كانت موجودة.
typedef GenerateResult = ({int created, int skipped});

/// حصص المجموعات: توليد، قراءة، إلغاء، ومسح الملغاة.
///
/// * الـ ID حتمي (gid_yyyyMMdd_HHmm)، والـ Rules بتمنع أي تعديل على حصة
///   موجودة غير الإلغاء. عشان كده التوليد Transaction: بيقرا الأول
///   ويكتب الناقص بس (إعادة الضغط آمنة، والحصة الملغاة ما بترجعش).
/// * Transaction بتفشل فورًا لو أوفلاين (set عادي كان هيتحفظ محليًا).
class SessionsRepository {
  SessionsRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  static const Duration timeout = Duration(seconds: 20);

  /// بيولّد حصص [weeks] أسابيع من النهارده (بتوقيت القاهرة) لمجموعة.
  Future<GenerateResult> generateUpcoming(
    Group group, {
    int weeks = SessionGenerator.defaultWeeks,
    DateTime? now,
  }) {
    return ErrorMapper.guard(() async {
      final uid = _requireUid();
      if (group.isArchived) {
        throw const Failure.validation('المجموعة مؤرشفة.');
      }
      if (group.slots.isEmpty) {
        throw const Failure.validation('المجموعة ملهاش مواعيد أسبوعية.');
      }

      final cairo = tz.getLocation('Africa/Cairo');
      final today = tz.TZDateTime.from(now ?? DateTime.now(), cairo);
      final sessions = SessionGenerator.generate(
        centerId: group.centerId,
        groupId: group.id,
        slots: [
          for (final s in group.slots)
            WeeklySlot(
              weekday: s.weekday,
              startMinutes: s.startMinutes,
              durationMinutes: s.durationMinutes,
            ),
        ],
        from: today,
        createdBy: uid,
        weeks: weeks,
        location: cairo,
      );

      var created = 0;
      await _db.runTransaction<void>((tx) async {
        created = 0; // الـ Transaction ممكن تتعاد
        final missing = <Session>[];
        for (final s in sessions) {
          final snap = await tx.get(_ref(s.centerId, s.id));
          if (!snap.exists) missing.add(s);
        }
        for (final s in missing) {
          tx.set(_ref(s.centerId, s.id), s.toCreateMap());
        }
        created = missing.length;
      }).timeout(timeout);

      return (created: created, skipped: sessions.length - created);
    });
  }

  /// حصص مجموعة من [from] (الافتراضي: النهارده) مرتبة بالوقت.
  /// محتاجة index: groupId + startAt.
  Future<List<Session>> loadGroupSessions(
    Group group, {
    DateTime? from,
  }) {
    return ErrorMapper.guard(() async {
      _requireUid();
      final cairo = tz.getLocation('Africa/Cairo');
      final start = tz.TZDateTime.from(from ?? DateTime.now(), cairo);
      final dayStart =
          tz.TZDateTime(cairo, start.year, start.month, start.day);
      final snap = await _db
          .collection(FirestorePaths.sessions(group.centerId))
          .where('groupId', isEqualTo: group.id)
          .where('startAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
          .orderBy('startAt')
          .get()
          .timeout(timeout);

      final out = <Session>[];
      for (final doc in snap.docs) {
        try {
          out.add(Session.fromMap(doc.id, doc.data()));
        } on FormatException {
          continue; // مستند تالف: بنتخطاه
        }
      }
      return out;
    });
  }

  /// إلغاء حصة (status بس، من scheduled لـ cancelled). مفيش حذف.
  Future<Session> cancelSession(Session session) {
    return ErrorMapper.guard(() async {
      _requireUid();
      if (session.isCancelled) {
        throw const Failure.validation('الحصة ملغاة بالفعل.');
      }
      final ref = _ref(session.centerId, session.id);
      await ref.update(Session.toCancelMap()).timeout(timeout);
      final snap = await ref.get();
      final data = snap.data();
      if (data == null) throw const Failure.notFound();
      try {
        return Session.fromMap(snap.id, data);
      } on FormatException {
        throw const Failure.unknown();
      }
    });
  }

  /// مسح حصة **ملغاة** نهائيًا. بيرفض لو الحصة مش ملغاة، أو لو عليها حضور
  /// مسجّل (الحضور مبيتمسحش، فمسح الحصة هيسيبه يتيم). الفحص بيتم من السيرفر
  /// مش من الكاش. الـ Rules بتسمح للأدمن بمسح الملغاة بس.
  Future<void> deleteCancelledSession(Session session) {
    return ErrorMapper.guard(() async {
      _requireUid();
      if (!session.isCancelled) {
        throw const Failure.validation('مينفعش تمسح حصة مش ملغاة. الغيها الأول.');
      }
      final attendance = await _db
          .collection(FirestorePaths.attendance(session.centerId))
          .where('sessionId', isEqualTo: session.id)
          .limit(1)
          .get(const GetOptions(source: Source.server))
          .timeout(timeout);
      if (attendance.docs.isNotEmpty) {
        throw const Failure.validation(
          'الحصة دي عليها حضور مسجّل، مينفعش تتمسح.',
        );
      }
      await _ref(session.centerId, session.id).delete().timeout(timeout);
    });
  }

  DocumentReference<Map<String, dynamic>> _ref(String centerId, String id) =>
      _db.doc(FirestorePaths.session(centerId, id));

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const Failure.permission();
    return uid;
  }
}
