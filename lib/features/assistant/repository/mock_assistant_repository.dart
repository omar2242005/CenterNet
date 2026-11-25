import '../../auth/models/app_user.dart';
import '../../groups/models/group.dart';
import '../../sessions/models/session.dart';
import '../../students/models/student.dart';
import '../models/attendance.dart';
import '../models/pending_scan.dart';
import '../models/scan_setup.dart';
import 'assistant_repository.dart';

class MockAssistantRepository implements AssistantRepository {
  MockAssistantRepository({
    this.onWriteAttendance,
    this.onMyProfile,
    this.onMyStaffGroups,
    this.onTodaySessions,
    this.onSessionById,
    this.onGroupById,
    this.onGroupStudentIds,
    this.onGroupStudents,
    this.onSessionAttendance,
    this.onLateAfterMinutes,
    this.onPrepareScanSetup,
  });

  final Future<void> Function(PendingScan scan)? onWriteAttendance;
  final Future<AppUser> Function()? onMyProfile;
  final Future<List<Group>> Function()? onMyStaffGroups;
  final Future<List<Session>> Function({DateTime? now})? onTodaySessions;
  final Future<Session> Function(String sessionId)? onSessionById;
  final Future<Group> Function(String groupId)? onGroupById;
  final Future<Set<String>> Function(String centerId, String groupId)?
      onGroupStudentIds;
  final Future<List<Student>> Function(String centerId, String groupId)?
      onGroupStudents;
  final Future<List<Attendance>> Function(String centerId, String sessionId)?
      onSessionAttendance;
  final Future<int> Function(String centerId)? onLateAfterMinutes;
  final Future<ScanSetup> Function(String sessionId)? onPrepareScanSetup;

  final List<PendingScan> writes = <PendingScan>[];

  @override
  Future<void> writeAttendance(PendingScan scan) async {
    writes.add(scan);
    await onWriteAttendance?.call(scan);
  }

  @override
  Future<AppUser> myProfile() =>
      onMyProfile?.call() ??
      (throw UnimplementedError('MockAssistantRepository.myProfile'));

  @override
  Future<List<Group>> myStaffGroups() =>
      onMyStaffGroups?.call() ?? Future.value(const <Group>[]);

  @override
  Future<List<Session>> todaySessions({DateTime? now}) =>
      onTodaySessions?.call(now: now) ?? Future.value(const <Session>[]);

  @override
  Future<Session> sessionById(String sessionId) =>
      onSessionById?.call(sessionId) ??
      (throw UnimplementedError('MockAssistantRepository.sessionById'));

  @override
  Future<Group> groupById(String groupId) =>
      onGroupById?.call(groupId) ??
      (throw UnimplementedError('MockAssistantRepository.groupById'));

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

  @override
  Future<int> lateAfterMinutes(String centerId) =>
      onLateAfterMinutes?.call(centerId) ?? Future.value(15);

  @override
  Future<ScanSetup> prepareScanSetup(String sessionId) =>
      onPrepareScanSetup?.call(sessionId) ??
      (throw UnimplementedError('MockAssistantRepository.prepareScanSetup'));
}
