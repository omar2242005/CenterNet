import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/features/linking/models/invite_code.dart';
import 'package:center_net/features/staff/models/staff_join_result.dart';
import 'package:center_net/features/staff/repository/staff_join_repository.dart';

class FakeStaffJoinRepository implements StaffJoinRepository {
  FakeStaffJoinRepository({this.failure});

  Failure? failure;
  final List<String> calls = <String>[];

  @override
  Future<StaffJoinResult> acceptStaffInvite(String rawCode) async {
    calls.add('accept:$rawCode');
    final f = failure;
    if (f != null) throw f;
    return const StaffJoinResult(
      centerId: 'c1',
      centerName: 'مركز النور',
      role: StaffInviteRole.teacher,
    );
  }
}
