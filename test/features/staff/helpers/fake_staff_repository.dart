import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/features/linking/models/invite_code.dart';
import 'package:center_net/features/staff/models/staff_invite_issued.dart';
import 'package:center_net/features/staff/models/staff_member.dart';
import 'package:center_net/features/staff/models/staff_roster.dart';
import 'package:center_net/features/staff/repository/staff_repository.dart';

class FakeStaffRepository implements StaffRepository {
  FakeStaffRepository({
    this.failure,
    this.loadFailure,
    this.writeFailure,
    List<StaffMember>? members,
  }) : members = members ?? <StaffMember>[];

  /// بيفشّل إنشاء الكود.
  Failure? failure;

  /// بيفشّل تحميل القائمة.
  Failure? loadFailure;

  /// بيفشّل تغيير الدور وتعطيل/تفعيل العضو.
  Failure? writeFailure;

  /// الأعضاء اللي [loadStaff] بترجّعهم.
  final List<StaffMember> members;

  final List<String> calls = <String>[];

  static const String code = 'ABCD2345';
  static const String centerId = 'c1';

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
        centerId: centerId,
        createdBy: 'u1',
        role: role,
        name: name,
        now: DateTime(2026, 11, 19),
      ),
      centerName: 'مركز النور',
    );
  }

  @override
  Future<StaffRoster> loadStaff() async {
    calls.add('load');
    final f = loadFailure;
    if (f != null) throw f;
    return StaffRoster(
      centerId: centerId,
      members: List<StaffMember>.of(members),
    );
  }

  @override
  Future<void> changeRole({
    required String centerId,
    required String uid,
    required StaffInviteRole role,
  }) async {
    calls.add('role:$centerId:$uid:${role.wire}');
    final f = writeFailure;
    if (f != null) throw f;
  }

  @override
  Future<void> setActive({
    required String centerId,
    required String uid,
    required bool active,
  }) async {
    calls.add('active:$centerId:$uid:$active');
    final f = writeFailure;
    if (f != null) throw f;
  }
}
