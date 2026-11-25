import '../../auth/models/app_user.dart';
import '../../groups/models/group.dart';
import '../../sessions/models/session.dart';
import '../models/pending_scan.dart';
import '../models/scan_setup.dart';
import 'assistant_repository.dart';

class MockAssistantRepository implements AssistantRepository {
  MockAssistantRepository({
    this.onWriteAttendance,
    this.onMyProfile,
    this.onTodaySessions,
    this.onSessionById,
    this.onGroupById,
    this.onGroupStudentIds,
    this.onLateAfterMinutes,
    this.onPrepareScanSetup,
  });

  final Future<void> Function(PendingScan scan)? onWriteAttendance;
  final Future<AppUser> Function()? onMyProfile;
  final Future<List<Session>> Function({DateTime? now})? onTodaySessions;
  final Future<Session> Function(String sessionId)? onSessionById;
  final Future<Group> Function(String groupId)? onGroupById;
  final Future<Set<String>> Function(String centerId, String groupId)?
      onGroupStudentIds;
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
  Future<int> lateAfterMinutes(String centerId) =>
      onLateAfterMinutes?.call(centerId) ?? Future.value(15);

  @override
  Future<ScanSetup> prepareScanSetup(String sessionId) =>
      onPrepareScanSetup?.call(sessionId) ??
      (throw UnimplementedError('MockAssistantRepository.prepareScanSetup'));
}
