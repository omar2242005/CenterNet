import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/features/groups/models/group.dart';
import 'package:center_net/features/groups/models/group_input.dart';
import 'package:center_net/features/groups/models/groups_roster.dart';
import 'package:center_net/features/groups/repository/groups_repository.dart';
import 'package:center_net/features/students/models/student.dart';

Group makeGroup(
  String id,
  String name, {
  String teacherId = 't1',
  bool archived = false,
  int? capacity,
}) {
  return Group.fromMap(id, <String, dynamic>{
    'centerId': 'c1',
    'name': name,
    'teacherId': teacherId,
    'createdBy': 'u1',
    'assistantIds': <String>[],
    'status': archived ? 'archived' : 'active',
    if (capacity != null) 'capacity': capacity,
  });
}

class FakeGroupsRepository implements GroupsRepository {
  FakeGroupsRepository({
    List<Group>? groups,
    this.loadFailure,
    this.writeFailure,
  }) : groups = groups ?? <Group>[];

  /// بيفشّل التحميل.
  Failure? loadFailure;

  /// بيفشّل الإنشاء والتعديل والأرشفة والتسجيل.
  Failure? writeFailure;

  final List<Group> groups;
  final List<String> calls = <String>[];

  void _maybeFailWrite() {
    final f = writeFailure;
    if (f != null) throw f;
  }

  Future<GroupsRoster> _roster(String call) async {
    calls.add(call);
    final f = loadFailure;
    if (f != null) throw f;
    return GroupsRoster(centerId: 'c1', groups: List<Group>.of(groups));
  }

  @override
  Future<GroupsRoster> loadGroups() => _roster('load');

  @override
  Future<GroupsRoster> loadMyGroups() => _roster('loadMy');

  @override
  Future<Group> createGroup(GroupInput input) async {
    calls.add('create:${input.name}');
    _maybeFailWrite();
    final g = makeGroup(
      'g${groups.length + 1}',
      input.name,
      teacherId: input.teacherId,
    );
    groups.add(g);
    return g;
  }

  @override
  Future<Group> updateGroup(Group group, GroupInput input) async {
    calls.add('update:${group.id}:${input.name}');
    _maybeFailWrite();
    return makeGroup(
      group.id,
      input.name,
      teacherId: input.teacherId,
      archived: group.isArchived,
    );
  }

  @override
  Future<Group> archiveGroup(Group group) async {
    calls.add('archive:${group.id}');
    _maybeFailWrite();
    return makeGroup(
      group.id,
      group.name,
      teacherId: group.teacherId,
      archived: true,
    );
  }

  @override
  Future<void> enrollStudent(Group group, Student student) async {
    calls.add('enroll:${group.id}:${student.id}');
    _maybeFailWrite();
  }

  @override
  Future<void> unenrollStudent(Group group, Student student) async {
    calls.add('unenroll:${group.id}:${student.id}');
    _maybeFailWrite();
  }
}
