import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/features/linking/models/invite_code.dart';
import 'package:center_net/features/staff/models/staff_invite_issued.dart';
import 'package:center_net/features/staff/repository/staff_repository.dart';

class FakeStaffRepository implements StaffRepository {
  FakeStaffRepository({this.failure});

  Failure? failure;
  final List<String> calls = <String>[];

  static const String code = 'ABCD2345';

  @override
  Future<StaffInviteIssued> createStaffInvite({
    required String name,
    required StaffInviteRole role,
  }) async {
    calls.add('invite:${name.trim()}:${role.wire}');
    final f = failure;
    if (f != null) throw f;
    return StaffInviteIssued(
      invite: InviteCode.staff(
        id: code,
        centerId: 'c1',
        createdBy: 'u1',
        role: role,
        name: name,
        now: DateTime(2026, 11, 19),
      ),
      centerName: 'مركز النور',
    );
  }
}
