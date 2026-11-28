import '../../sessions/models/session.dart';
import '../../students/models/student.dart';
import '../models/attendance.dart';
import 'attendance_repository.dart';

/// نسخة اختبارية من [AttendanceRepository]: كل دالة ليها callback، والافتراضي
/// نتيجة فاضية بدل ما الاختبار يحتاج يظبّط كل حاجة.
class MockAttendanceRepository implements AttendanceRepository {
  MockAttendanceRepository({
    this.onCurrentCenterId,
    this.onSessionById,
    this.onGroupStudents,
    this.onGroupStudentIds,
    this.onSessionAttendance,
  });

  final Future<String> Function()? onCurrentCenterId;
  final Future<Session> Function(String sessionId)? onSessionById;
  final Future<List<Student>> Function(String centerId, String groupId)?
      onGroupStudents;
  final Future<Set<String>> Function(String centerId, String groupId)?
      onGroupStudentIds;
  final Future<List<Attendance>> Function(String centerId, String sessionId)?
      onSessionAttendance;

  @override
  Future<String> currentCenterId() =>
      onCurrentCenterId?.call() ?? Future.value('center-1');

  @override
  Future<Session> sessionById(String sessionId) =>
      onSessionById?.call(sessionId) ??
      (throw UnimplementedError('MockAttendanceRepository.sessionById'));

  @override
  Future<Set<String>> groupStudentIds(String centerId, String groupId) =>
      onGroupStudentIds?.call(centerId, groupId) ??
      Future.value(const <String>{});

  @override
  Future<List<Student>> groupStudents(String centerId, String groupId) =>
      onGroupStudents?.call(centerId, groupId) ??
      Future.value(const <Student>[]);

  @override
  Future<List<Attendance>> sessionAttendance(
    String centerId,
    String sessionId,
  ) =>
      onSessionAttendance?.call(centerId, sessionId) ??
      Future.value(const <Attendance>[]);
}
