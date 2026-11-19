import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/features/centers/models/center_info.dart';
import 'package:center_net/features/centers/models/center_member.dart';
import 'package:center_net/features/centers/repository/centers_repository.dart';

/// Repository مزيف للاختبارات: بيسجّل النداءات، ولو [failure] اتحدد بيرميه.
class FakeCentersRepository implements CentersRepository {
  FakeCentersRepository({this.failure, this.mine});

  Failure? failure;

  /// اللي بيرجّعه loadMine (null = مالوش سنتر).
  CenterContext? mine;

  final List<String> calls = <String>[];

  void _maybeFail() {
    final f = failure;
    if (f != null) throw f;
  }

  @override
  Future<CenterInfo> createCenter({
    required String name,
    required int year,
  }) async {
    calls.add('create:$name:$year');
    _maybeFail();
    return CenterInfo(id: 'c1', name: name, year: year);
  }

  @override
  Future<CenterContext?> loadMine() async {
    calls.add('loadMine');
    _maybeFail();
    return mine;
  }

  @override
  Future<void> updateSettings({
    required String centerId,
    required String name,
    required int year,
    required int lateAfterMinutes,
  }) async {
    calls.add('update:$centerId:$name:$year:$lateAfterMinutes');
    _maybeFail();
  }
}

/// سنتر ومستخدم جاهزين للاختبارات.
CenterContext sampleContext({
  MemberRole role = MemberRole.admin,
  bool active = true,
  String name = 'مركز النور',
  int year = 2026,
  int lateAfterMinutes = 15,
}) {
  return CenterContext(
    center: CenterInfo(
      id: 'c1',
      name: name,
      year: year,
      lateAfterMinutes: lateAfterMinutes,
    ),
    membership: CenterMember(
      uid: 'u1',
      role: role,
      name: 'أحمد',
      active: active,
    ),
  );
}
