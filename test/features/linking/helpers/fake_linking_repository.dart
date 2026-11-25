import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/features/linking/models/invite_code.dart';
import 'package:center_net/features/linking/models/linked_student.dart';
import 'package:center_net/features/linking/models/student_link.dart';
import 'package:center_net/features/linking/repository/linking_repository.dart';
import 'package:center_net/features/students/models/student.dart';

import '../../students/helpers/fake_students_repository.dart';

/// ربط وهمي في الذاكرة للاختبارات.
class FakeLinkingRepository implements LinkingRepository {
  FakeLinkingRepository({this.failure, List<LinkedStudent>? linked})
      : linked = linked ?? <LinkedStudent>[];

  /// لو مش null كل العمليات بترميه.
  Failure? failure;
  final List<LinkedStudent> linked;

  final List<String> redeemedCodes = <String>[];
  final List<StudentLink> unlinked = <StudentLink>[];

  @override
  Future<void> redeem(String raw, {required LinkKind expected}) async {
    if (failure != null) throw failure!;
    redeemedCodes.add(raw);
  }

  @override
  Future<List<LinkedStudent>> loadMyStudents() async {
    if (failure != null) throw failure!;
    return List<LinkedStudent>.of(linked);
  }

  @override
  Future<void> unlink(StudentLink link) async {
    if (failure != null) throw failure!;
    unlinked.add(link);
    linked.removeWhere((l) => l.link.id == link.id);
  }

  @override
  Future<InviteCode> issueCode(Student student, {String? relation}) async {
    if (failure != null) throw failure!;
    return relation == null
        ? InviteCode.student(
            id: 'ABCDEFGH',
            centerId: student.centerId,
            createdBy: 'admin1',
            studentId: student.id,
            now: DateTime(2026, 11, 1),
          )
        : InviteCode.guardian(
            id: 'ABCDEFGH',
            centerId: student.centerId,
            createdBy: 'admin1',
            studentId: student.id,
            relation: relation,
            now: DateTime(2026, 11, 1),
          );
  }
}

/// طالب مربوط جاهز للاختبار.
LinkedStudent makeLinked(int no, {LinkKind kind = LinkKind.guardian}) {
  final student = makeStudent(no, 'طالب $no');
  return LinkedStudent(
    link: StudentLink.create(
      centerId: student.centerId,
      uid: 'u1',
      studentId: student.id,
      kind: kind,
      relation: kind == LinkKind.guardian ? 'أب' : null,
    ),
    student: student,
  );
}
