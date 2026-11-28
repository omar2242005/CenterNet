import '../../auth/models/app_user.dart';
import '../../groups/models/group.dart';
import '../../sessions/models/session.dart';
import 'assistant_repository.dart';

class MockAssistantRepository implements AssistantRepository {
  MockAssistantRepository({
    this.onMyProfile,
    this.onMyStaffGroups,
    this.onTodaySessions,
    this.onGroupById,
  });

  final Future<AppUser> Function()? onMyProfile;
  final Future<List<Group>> Function()? onMyStaffGroups;
  final Future<List<Session>> Function({DateTime? now})? onTodaySessions;
  final Future<Group> Function(String groupId)? onGroupById;

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
  Future<Group> groupById(String groupId) =>
      onGroupById?.call(groupId) ??
      (throw UnimplementedError('MockAssistantRepository.groupById'));
}
