import 'package:center_net/features/assistant/models/attendance.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/errors/failure.dart';
import '../../../core/firestore_paths.dart';
import '../../groups/models/group.dart';
import '../../sessions/models/session.dart';

/// حصص مجموعة فاتت + سجلات حضورها (للحساب الغياب).
typedef GroupAttendanceData = ({
  List<Session> sessions,
  List<Attendance> records,
});

/// قراءة بس. الـ Rules بتسمح للمعلم/المساعد بقراءة حصص وحضور مجموعتهم.
///
/// * الحضور بيتقرا باستعلام لكل حصة (sessionId ==)، لأن الـ Rules بتحتاج
///   الاستعلام يكون مقيّد بحصة واحدة.
/// * بياخد آخر [maxSessions] حصة فاتت بس.
class GroupAttendanceRepository {
  GroupAttendanceRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  static const Duration timeout = Duration(seconds: 20);
  static const int maxSessions = 20;

  Future<GroupAttendanceData> load(Group group, {DateTime? now}) {
    return ErrorMapper.guard(() async {
      if (_auth.currentUser == null) throw const Failure.permission();

      // محتاجة index: groupId + startAt (موجود، نفس index الحصص).
      final snap = await _db
          .collection(FirestorePaths.sessions(group.centerId))
          .where('groupId', isEqualTo: group.id)
          .where(
            'startAt',
            isLessThan: Timestamp.fromDate(now ?? DateTime.now()),
          )
          .orderBy('startAt', descending: true)
          .limit(maxSessions)
          .get()
          .timeout(timeout);

      final sessions = <Session>[];
      for (final doc in snap.docs) {
        try {
          sessions.add(Session.fromMap(doc.id, doc.data()));
        } on FormatException {
          continue; // مستند تالف: بنتخطاه
        }
      }

      final perSession = await Future.wait(
        sessions.map((s) => _recordsOf(group.centerId, s.id)),
      );

      return (
        sessions: sessions,
        records: [for (final list in perSession) ...list],
      );
    });
  }

  Future<List<Attendance>> _recordsOf(String centerId, String sessionId) async {
    final snap = await _db
        .collection(FirestorePaths.attendance(centerId))
        .where('sessionId', isEqualTo: sessionId)
        .get()
        .timeout(timeout);
    final out = <Attendance>[];
    for (final doc in snap.docs) {
      try {
        out.add(Attendance.fromMap(doc.id, doc.data()));
      } on FormatException {
        continue;
      }
    }
    return out;
  }
}