import 'package:center_net/features/groups/models/group.dart';
import 'package:center_net/features/sessions/models/session.dart';
import 'package:center_net/features/students/models/student.dart';
import 'package:timezone/timezone.dart' as tz;

Group fakeGroup(
  String id, {
  String subject = 'رياضيات',
  String room = '',
  String status = 'active',
}) => Group.fromMap(id, <String, dynamic>{
  'centerId': 'c1',
  'name': 'مجموعة $id',
  'subject': subject,
  'room': room,
  'teacherId': 't1',
  'createdBy': 'u1',
  'assistantIds': <String>[],
  'status': status,
});

Student fakeStudent(
  String id,
  int no,
  List<String> groups, {
  String status = 'active',
}) => Student.fromMap(id, <String, dynamic>{
  'centerId': 'c1',
  'studentNo': no,
  'fullName': 'طالب $id',
  'searchKey': 'طالب $id',
  'createdBy': 'u1',
  'groupIds': groups,
  'status': status,
});

/// حصة بتوقيت القاهرة. [cancelled] بيحوّلها لملغاة.
Session fakeSession(
  String groupId,
  DateTime cairoStart, {
  int minutes = 90,
  bool cancelled = false,
}) {
  final cairo = tz.getLocation('Africa/Cairo');
  final start = tz.TZDateTime.from(cairoStart, cairo);
  final s = Session.create(
    centerId: 'c1',
    groupId: groupId,
    cairoStart: start,
    cairoEnd: start.add(Duration(minutes: minutes)),
    createdBy: 'u1',
  );
  if (!cancelled) return s;
  return Session.fromMap(s.id, <String, dynamic>{
    ...s.toCreateMap(createdAt: DateTime(2026)),
    'status': 'cancelled',
  });
}
