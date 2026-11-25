import '../../students/models/student.dart';
import 'attendance.dart';

/// حالة مزامنة سطر واحد في قائمة حضور جلسة.
enum AttendanceSyncState {
  /// سجل Firestore (اتزامن).
  synced,

  /// مسحة محلية لسه بانتظار الرفع.
  waiting,

  /// مسحة محلية فشل رفعها ومحتاجة إجراء.
  failed,
}

/// سطر واحد في قائمة حضور جلسة: ناتج دمج سجلات Firestore مع المسحات
/// المحلية غير المتزامنة (AttendanceMerger). الدمج بالـ id الحتمي
/// (`FirestoreIds.attendance`)، ولو سجل موجود في الاتنين فالسيرفر يكسب.
class AttendanceEntry {
  const AttendanceEntry({
    required this.studentId,
    required this.student,
    required this.status,
    required this.scannedAt,
    required this.syncState,
  });

  final String studentId;

  /// null لو مستند الطالب مش ضمن طلاب المجموعة المحمّلين (نادر، بس
  /// مش سبب يخفي السطر).
  final Student? student;

  /// حاضر أو متأخر بس: السجلات الملغية والبعذر مش سطور في القائمة.
  final AttendanceStatus status;

  /// وقت المسح. ممكن يكون null في سجل يدوي من الأدمن.
  final DateTime? scannedAt;

  final AttendanceSyncState syncState;
}
