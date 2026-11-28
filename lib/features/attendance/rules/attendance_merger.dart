import '../../students/models/student.dart';
import '../models/attendance.dart';
import '../models/attendance_entry.dart';
import '../../scan/models/pending_scan.dart';

/// ملخص حضور جلسة من البيانات المدموجة (شاشة تفاصيل الحصة).
class AttendanceSummary {
  const AttendanceSummary({
    required this.presentCount,
    required this.lateCount,
    required this.waitingCount,
    required this.failedCount,
    required this.notYetAttendedCount,
    required this.totalStudents,
  });

  /// حضور (غير ملغي) بحالة حاضر، سواء متزامن أو مسحة محلية.
  final int presentCount;

  /// حضور (غير ملغي) بحالة متأخر، سواء متزامن أو مسحة محلية.
  final int lateCount;

  /// مسحات محلية بانتظار الرفع.
  final int waitingCount;

  /// مسحات محلية فشل رفعها.
  final int failedCount;

  /// طلاب المجموعة النشطين اللي مفيش ما يغطيهم في الجلسة.
  final int notYetAttendedCount;

  /// عدد طلاب المجموعة النشطين.
  final int totalStudents;

  /// "X حضر" في العرض: حاضر + متأخر.
  int get attendedCount => presentCount + lateCount;
}

/// دمج حضور جلسة واحدة من مصدرين: سجلات Firestore (بما فيها اللي جاية من
/// الكاش المحلي بتاع persistence) + مسحات [PendingScanStore] اللي لسه
/// ما اتزامنتش.
///
/// * الدمج بالـ id الحتمي (`FirestoreIds.attendance` = `sessionId_sid`):
///   السجل موجود مرة واحدة، ولو موجود في المصدرين فسجل Firestore يكسب —
///   حتى لو ملغي (الإلغاء على السيرفر بيلغي المسحة المحلية بنفس الـ id).
/// * السجلات الملغية مش سطور في القائمة ومش بيتحسبوا حضور، نفس دلالة
///   `Attendance.countsAsAttended` و`AbsenceCalculator._covers`.
/// * الغياب بعذر (غير ملغي) مش سطر في القائمة، بس بيغطي الطالب في حساب
///   "لم يحضروا بعد" (نفس `_covers`).
class AttendanceMerger {
  const AttendanceMerger._();

  /// السطور المدموجة، مرتبة بوقت المسح تصاعديًا (اللي مفيش له وقت في
  /// الآخر)، وبعدين بالاسم عند التساوي.
  static List<AttendanceEntry> merge({
    required String sessionId,
    required Iterable<Attendance> records,
    required Iterable<PendingScan> pendingScans,
    required Map<String, Student> studentsById,
  }) {
    final byId = <String, AttendanceEntry>{};

    // المحلي أولًا: سجل Firestore بنفس الـ id بيستبدله تحت.
    for (final scan in pendingScans) {
      if (scan.sessionId != sessionId) continue;
      if (scan.status == PendingScanStatus.synced) continue;
      final attendanceStatus = scan.attendanceStatus;
      // مسحة قديمة ناقصة بيانات المزامنة: ممنوع نخترع لها حالة حضور.
      if (attendanceStatus == null) continue;
      byId[scan.id] = AttendanceEntry(
        studentId: scan.studentId,
        student: studentsById[scan.studentId],
        status: switch (attendanceStatus) {
          PendingAttendanceStatus.present => AttendanceStatus.present,
          PendingAttendanceStatus.late => AttendanceStatus.lateArrival,
        },
        scannedAt: scan.scannedAt,
        syncState: scan.status == PendingScanStatus.failed
            ? AttendanceSyncState.failed
            : AttendanceSyncState.waiting,
        paymentStatus: scan.paymentStatus,
      );
    }

    for (final record in records) {
      if (record.sessionId != sessionId) continue;
      // السيرفر يكسب حتى لو السجل ملغي: بيشيل أي مسحة محلية بنفس الـ id.
      byId.remove(record.id);
      if (!record.countsAsAttended) continue;
      byId[record.id] = AttendanceEntry(
        studentId: record.studentId,
        student: studentsById[record.studentId],
        status: record.status,
        scannedAt: record.scannedAt,
        syncState: AttendanceSyncState.synced,
        paymentStatus: record.paymentStatus,
      );
    }

    final entries = byId.values.toList()
      ..sort((a, b) {
        final at = a.scannedAt;
        final bt = b.scannedAt;
        if (at == null && bt == null) {
          return _name(a).compareTo(_name(b));
        }
        if (at == null) return 1;
        if (bt == null) return -1;
        final byTime = at.compareTo(bt);
        return byTime != 0 ? byTime : _name(a).compareTo(_name(b));
      });
    return entries;
  }

  /// ids الطلاب "المغطيين" في الجلسة: سطور الحضور (حاضر/متأخر) + الغياب
  /// بعذر غير الملغي. نفس دلالة `AbsenceCalculator._covers` من غير بوابة
  /// التوقيت (الملخص بيظهر قبل نهاية الحصة كمان).
  static Set<String> coveredStudentIds({
    required String sessionId,
    required Iterable<Attendance> records,
    required Iterable<AttendanceEntry> entries,
  }) {
    final covered = <String>{for (final e in entries) e.studentId};
    for (final record in records) {
      if (record.sessionId != sessionId) continue;
      if (!record.voided && record.status == AttendanceStatus.excused) {
        covered.add(record.studentId);
      }
    }
    return covered;
  }

  /// العدادات اللي بتحكم سطور الملخص في تفاصيل الحصة.
  static AttendanceSummary summary({
    required List<AttendanceEntry> entries,
    required Iterable<Student> students,
    required Set<String> coveredStudentIds,
  }) {
    var present = 0;
    var late = 0;
    var waiting = 0;
    var failed = 0;
    for (final entry in entries) {
      if (entry.status == AttendanceStatus.present) {
        present++;
      } else {
        late++;
      }
      switch (entry.syncState) {
        case AttendanceSyncState.waiting:
          waiting++;
        case AttendanceSyncState.failed:
          failed++;
        case AttendanceSyncState.synced:
          break;
      }
    }
    final active = students.where((s) => !s.isArchived).toList();
    final notYet = active
        .where((s) => !coveredStudentIds.contains(s.id))
        .length;
    return AttendanceSummary(
      presentCount: present,
      lateCount: late,
      waitingCount: waiting,
      failedCount: failed,
      notYetAttendedCount: notYet,
      totalStudents: active.length,
    );
  }

  static String _name(AttendanceEntry e) => e.student?.searchKey ?? e.studentId;
}
