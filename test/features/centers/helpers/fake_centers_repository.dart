import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/features/centers/models/center_info.dart';
import 'package:center_net/features/centers/repository/centers_repository.dart';

class FakeCentersRepository implements CentersRepository {
  FakeCentersRepository({this.center, this.failure});

  CenterInfo? center;
  Failure? failure;
  final List<String> calls = <String>[];

  void _maybeFail() {
    final f = failure;
    if (f != null) throw f;
  }

  @override
  Future<String> createCenter({required String name, required int year}) async {
    calls.add('create:$name:$year');
    _maybeFail();
    return 'newCenter1';
  }

  @override
  Future<CenterInfo?> loadMyCenter() async {
    calls.add('load');
    _maybeFail();
    return center;
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
