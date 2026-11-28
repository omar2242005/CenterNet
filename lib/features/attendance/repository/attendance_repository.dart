import '../../sessions/models/session.dart';
import '../../students/models/student.dart';
import '../models/attendance.dart';

/// قراءات الحضور المشتركة: سجلات جلسة، وطلاب مجموعة، وسياق الموظف
/// (السنتر والحصة). الكتابة (المسح والمزامنة) في `features/scan`.
///
/// الشاشات اللي بتستخدمه: قائمة الحضور وتفاصيل الحصة عند المساعد، وقايمة
/// الغياب عند المعلم. مفيش دور مخصوص هنا.
abstract class AttendanceRepository {
  /// سنتر المستخدم الحالي من `users/{uid}.centerId`.
  /// [Failure.permission] لو الحساب لسه ما اتربطش بسنتر.
  Future<String> currentCenterId();

  /// جلسة واحدة بالـ id (من سنتر المستخدم). [Failure.notFound] لو مش موجودة.
  Future<Session> sessionById(String sessionId);

  /// طلاب مجموعة كاملين (نشطين ومؤرشفين) — للأسماء والأكواد في قائمة
  /// الحضور. الأرشفة بيفلترها اللي بيحسب الملخص.
  Future<List<Student>> groupStudents(String centerId, String groupId);

  /// ids الطلاب النشطين في مجموعة. العضوية متخزنة على مستند الطالب
  /// (`groupIds` array-contains)، مش على مستند المجموعة.
  Future<Set<String>> groupStudentIds(String centerId, String groupId);

  /// سجلات حضور جلسة واحدة بكل حالاتها (حاضر/متأخر/بعذر/ملغي). الفلترة
  /// والدمج مسؤولية AttendanceMerger. persistence مفعّل، فالقراءة بتشمل
  /// الكاش المحلي لما الشبكة مقطوعة.
  Future<List<Attendance>> sessionAttendance(String centerId, String sessionId);
}
