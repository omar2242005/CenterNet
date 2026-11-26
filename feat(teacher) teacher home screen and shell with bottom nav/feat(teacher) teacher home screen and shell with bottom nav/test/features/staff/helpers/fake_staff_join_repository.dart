import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/features/linking/models/invite_code.dart';
import 'package:center_net/features/staff/models/staff_invite_preview.dart';
import 'package:center_net/features/staff/models/staff_join_result.dart';
import 'package:center_net/features/staff/repository/staff_join_repository.dart';

class FakeStaffJoinRepository implements StaffJoinRepository {
  FakeStaffJoinRepository({
    this.failure,
    this.previewFailure,
    this.role = StaffInviteRole.teacher,
  });

  /// فشل القبول.
  Failure? failure;

  /// فشل المعاينة (مثلًا عدم تطابق الدور).
  Failure? previewFailure;
  StaffInviteRole role;
  final List<String> calls = <String>[];

  @override
  Future<StaffInvitePreview> previewInvite(String rawCode) async {
    calls.add('preview:$rawCode');
    final f = previewFailure;
    if (f != null) throw f;
    return StaffInvitePreview(code: rawCode, role: role);
  }

  @override
  Future<StaffJoinResult> acceptStaffInvite(String rawCode) async {
    calls.add('accept:$rawCode');
    final f = failure;
    if (f != null) throw f;
    return StaffJoinResult(
      centerId: 'c1',
      centerName: 'مركز النور',
      role: role,
    );
  }
}
