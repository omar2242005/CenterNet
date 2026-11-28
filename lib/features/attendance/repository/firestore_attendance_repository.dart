import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/errors/failure.dart';
import '../../../core/firestore_paths.dart';
import '../../sessions/models/session.dart';
import '../../students/models/student.dart';
import '../models/attendance.dart';
import 'attendance_repository.dart';

/// قراءات الحضور من Firestore لكل الأدوار اللي بتشوف حضور.
///
/// persistence مفعّل في التطبيق، فالقراءة بتشمل الكاش المحلي لما الشبكة
/// مقطوعة (وده المقصود في قائمة الحضور: المسحات المعلّقة بتتدمج مع
/// سجلات Firestore).
class FirestoreAttendanceRepository implements AttendanceRepository {
  FirestoreAttendanceRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  static const Duration timeout = Duration(seconds: 20);

  @override
  Future<String> currentCenterId() {
    return ErrorMapper.guard(() async {
      final uid = _requireUid();
      final snap = await _db
          .doc(FirestorePaths.user(uid))
          .get()
          .timeout(timeout);
      final centerId = snap.data()?['centerId'];
      if (centerId is! String) {
        throw const Failure.permission(
          message: 'حسابك غير مرتبط بأي سنتر بعد.',
        );
      }
      return centerId;
    });
  }

  @override
  Future<Session> sessionById(String sessionId) {
    return ErrorMapper.guard(() async {
      final centerId = await currentCenterId();
      final snap = await _db
          .doc(FirestorePaths.session(centerId, sessionId))
          .get()
          .timeout(timeout);
      final data = snap.data();
      if (data == null) throw const Failure.notFound();
      try {
        return Session.fromMap(snap.id, data);
      } on FormatException {
        throw const Failure.unknown();
      }
    });
  }

  @override
  Future<Set<String>> groupStudentIds(String centerId, String groupId) {
    return ErrorMapper.guard(() async {
      _requireUid();
      // العضوية متخزنة على مستند الطالب (groupIds)، مش على مستند المجموعة.
      final snap = await _db
          .collection(FirestorePaths.students(centerId))
          .where('groupIds', arrayContains: groupId)
          .get()
          .timeout(timeout);
      final ids = <String>{};
      for (final doc in snap.docs) {
        try {
          final student = Student.fromMap(doc.id, doc.data());
          if (!student.isArchived) ids.add(student.id);
        } on FormatException {
          continue; // مستند تالف: بنتخطاه
        }
      }
      return ids;
    });
  }

  @override
  Future<List<Student>> groupStudents(String centerId, String groupId) {
    return ErrorMapper.guard(() async {
      _requireUid();
      final snap = await _db
          .collection(FirestorePaths.students(centerId))
          .where('groupIds', arrayContains: groupId)
          .get()
          .timeout(timeout);
      final out = <Student>[];
      for (final doc in snap.docs) {
        try {
          out.add(Student.fromMap(doc.id, doc.data()));
        } on FormatException {
          continue; // مستند تالف: بنتخطاه
        }
      }
      return out;
    });
  }

  @override
  Future<List<Attendance>> sessionAttendance(String centerId, String sessionId) {
    return ErrorMapper.guard(() async {
      _requireUid();
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
          continue; // مستند تالف: بنتخطاه
        }
      }
      return out;
    });
  }

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const Failure.permission();
    return uid;
  }
}
