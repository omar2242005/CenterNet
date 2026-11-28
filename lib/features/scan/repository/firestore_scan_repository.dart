import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/errors/failure.dart';
import '../../../core/firestore_paths.dart';
import '../../attendance/models/attendance.dart';
import '../../attendance/repository/attendance_repository.dart';
import '../../payments/models/payment.dart';
import '../models/pending_scan.dart';
import '../models/scan_setup.dart';
import '../rules/scan_validator.dart';
import 'scan_repository.dart';

/// كتابة المسحات وتأكيدها من السيرفر + تحضير بيانات المسح.
///
/// persistence مفعّل في التطبيق، فنجاح `set` وحده معناه أن الكتابة دخلت
/// الكاش فقط. لا نعتبر المسحة متزامنة إلا بعد `Source.server` يؤكدها.
class FirestoreScanRepository implements ScanRepository {
  FirestoreScanRepository(this._attendance, this._auth, this._db);

  final AttendanceRepository _attendance;
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
      paymentStatus: scan.paymentStatus,
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

  @override
  Future<int> lateAfterMinutes(String centerId) {
    return ErrorMapper.guard(() async {
      _requireUid();
      final snap = await _db
          .doc(FirestorePaths.center(centerId))
          .get()
          .timeout(serverConfirmationTimeout);
      final raw = snap.data()?['lateAfterMinutes'];
      return raw is int ? raw : ScanValidator.defaultLateAfterMinutes;
    });
  }

  @override
  Future<ScanSetup> prepareScanSetup(String sessionId) {
    return ErrorMapper.guard(() async {
      final centerId = await _attendance.currentCenterId();
      final session = await _attendance.sessionById(sessionId);
      if (session.isCancelled) {
        throw const Failure.validation('الحصة دي ملغاة.');
      }
      final studentIds = await _attendance.groupStudentIds(
        centerId,
        session.groupId,
      );
      final lateAfter = await lateAfterMinutes(centerId);
      // [P1-خطوة4] علامات الدفع للشهر الحالي. فشلها (أوفلاين مثلًا) مش
      // بيعطّل المسح: null = الحالة غير معروفة لكل الطلاب.
      final now = DateTime.now();
      Map<String, bool>? paidByStudentId;
      try {
        paidByStudentId = await groupMonthPaymentStatus(
          centerId,
          session.groupId,
          year: now.year,
          month: now.month,
        );
      } on Failure catch (_) {
        paidByStudentId = null;
      }
      // مجموعة فاضية بترمي Failure.validation جوه forSession.
      return ScanSetup.forSession(
        session: session,
        groupStudentIds: studentIds,
        lateAfterMinutes: lateAfter,
        paidByStudentId: paidByStudentId,
        paymentStatusMonth: paidByStudentId == null
            ? null
            : Payment.monthKey(now.year, now.month),
      );
    });
  }

  @override
  Future<Map<String, bool>> groupMonthPaymentStatus(
    String centerId,
    String groupId, {
    required int year,
    required int month,
  }) {
    return ErrorMapper.guard(() async {
      _requireUid();
      final key = Payment.monthKey(year, month);
      // فلترين equality بس = مفيش composite index.
      // Source.server عمدًا: الكاش الفاضي أوفلاين بيرجّع نجاح فاضي فيخلي
      // كل الطلاب "غير مدفوع" غلط. عايزين الأوفلاين يفشل → غير معروف،
      // والنجاح الفاضي يبقى معناه أكيد: مفيش حد في المجموعة دافع الشهر ده.
      final snap = await _db
          .collection(FirestorePaths.paymentStatus(centerId))
          .where('groupId', isEqualTo: groupId)
          .where('month', isEqualTo: key)
          .get(const GetOptions(source: Source.server))
          .timeout(serverConfirmationTimeout);
      final out = <String, bool>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final sid = data['studentId'];
        final paid = data['paid'];
        if (sid is String && paid is bool) out[sid] = paid;
      }
      return out;
    });
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

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const Failure.permission();
    return uid;
  }
}
