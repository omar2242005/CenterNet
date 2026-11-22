import 'group.dart';

/// نتيجة تحميل مجموعات: السنتر + المجموعات مرتبة بالاسم.
class GroupsRoster {
  const GroupsRoster({required this.centerId, required this.groups});

  final String centerId;
  final List<Group> groups;
}
