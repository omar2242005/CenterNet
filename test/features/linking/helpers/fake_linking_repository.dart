import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/features/linking/models/invite_code.dart';
import 'package:center_net/features/linking/models/link_request.dart';
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

  /// طلبات الربط المخزنة، وسجل الاستدعاءات.
  final List<LinkRequest> requests = <LinkRequest>[];
  final List<String> calls = <String>[];

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

  @override
  Future<LinkRequest> sendRequest({
    required String centerId,
    required int studentNo,
    required LinkKind kind,
    String? relation,
  }) async {
    if (failure != null) throw failure!;
    calls.add('sendRequest:$studentNo');
    final r = LinkRequest(
      id: 'u1_$studentNo',
      centerId: centerId,
      uid: 'u1',
      name: 'اسم',
      studentNo: studentNo,
      kind: kind,
      status: LinkRequestStatus.pending,
      relation: relation,
    );
    requests.add(r);
    return r;
  }

  @override
  Future<LinkRequest> loadRequest(LinkRequest r) async {
    if (failure != null) throw failure!;
    return requests.firstWhere((x) => x.id == r.id, orElse: () => r);
  }

  @override
  Future<void> cancelRequest(LinkRequest r) async {
    if (failure != null) throw failure!;
    calls.add('cancelRequest:${r.studentNo}');
    requests.removeWhere((x) => x.id == r.id);
  }

  @override
  Future<void> completeRequest(LinkRequest r) async {
    if (failure != null) throw failure!;
    calls.add('completeRequest:${r.studentNo}');
  }

  @override
  Future<List<LinkRequest>> loadPendingRequests() async {
    if (failure != null) throw failure!;
    return requests
        .where((r) => r.status == LinkRequestStatus.pending)
        .toList();
  }

  @override
  Future<void> approveRequest(LinkRequest r) async {
    if (failure != null) throw failure!;
    calls.add('approveRequest:${r.studentNo}');
  }

  @override
  Future<void> rejectRequest(LinkRequest r) async {
    if (failure != null) throw failure!;
    calls.add('rejectRequest:${r.studentNo}');
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
