import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/errors/failure.dart';
import '../../../core/firestore_paths.dart';
import '../models/attendance.dart';
import '../models/pending_scan.dart';
import 'assistant_repository.dart';

/// مزامنة حضور المساعد مع Firestore.
///
/// persistence مفعّل في التطبيق، فنجاح `set` وحده معناه أن الكتابة دخلت
/// الكاش فقط. لا نعتبر المسحة متزامنة إلا بعد `Source.server` يؤكدها.
class FirestoreAssistantRepository implements AssistantRepository {
  FirestoreAssistantRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  static const Duration serverConfirmationTimeout = Duration(seconds: 20);

  @override
  Future<void> writeAttendance(PendingScan scan) async {
    final centerId = scan.centerId;
    final status = scan.attendanceStatus;
    if (centerId == null || status == null) {
      throw const Failure.validation(
        'هذه مسحة قديمة ناقصة بيانات المزامنة. راجع إدارة السنتر.',
      );
    }
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const Failure.permission();

    final attendance = Attendance.create(
      centerId: centerId,
      sessionId: scan.sessionId,
      studentId: scan.studentId,
      status: switch (status) {
        PendingAttendanceStatus.present => AttendanceStatus.present,
        PendingAttendanceStatus.late => AttendanceStatus.lateArrival,
      },
      method: AttendanceMethod.qr,
      scannedAt: scan.scannedAt,
      recordedBy: uid,
    );
    final ref = _db.doc(FirestorePaths.attendanceDoc(centerId, attendance.id));

    try {
      await ref.set(attendance.toCreateMap());
      await _confirmMatchingServerRecord(ref, attendance);
    } on Object catch (error) {
      final failure = ErrorMapper.map(error);

      // لو التطبيق مات بعد تأكيد الكتابة وقبل markSynced، المحاولة الجديدة
      // تُرفض كـ update. القراءة من السيرفر هي التي تثبت أنها نفس المسحة.
      if (failure.type != FailureType.network &&
          await _serverRecordMatches(ref, attendance)) {
        return;
      }
      throw failure;
    }
  }

  Future<void> _confirmMatchingServerRecord(
    DocumentReference<Map<String, dynamic>> ref,
    Attendance expected,
  ) async {
    final snap = await ref
        .get(const GetOptions(source: Source.server))
        .timeout(serverConfirmationTimeout);
    if (!_matches(snap.data(), expected)) {
      throw const Failure.unknown(
        message: 'تعذر تأكيد حفظ الحضور على السيرفر.',
      );
    }
  }

  Future<bool> _serverRecordMatches(
    DocumentReference<Map<String, dynamic>> ref,
    Attendance expected,
  ) async {
    try {
      final snap = await ref
          .get(const GetOptions(source: Source.server))
          .timeout(serverConfirmationTimeout);
      return _matches(snap.data(), expected);
    } on Object {
      return false;
    }
  }

  bool _matches(Map<String, dynamic>? data, Attendance expected) =>
      data?['sessionId'] == expected.sessionId &&
      data?['studentId'] == expected.studentId;
}
