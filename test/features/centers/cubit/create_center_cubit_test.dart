import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/features/centers/cubit/create_center_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_centers_repository.dart';

void main() {
  Future<List<CreateCenterState>> collect(
    CreateCenterCubit cubit,
    Future<void> Function() action,
  ) async {
    final states = <CreateCenterState>[];
    final sub = cubit.stream.listen(states.add);
    await action();
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    return states;
  }

  test('إنشاء ناجح: submitting ثم success ومعاه السنتر', () async {
    final repo = FakeCentersRepository();
    final cubit = CreateCenterCubit(repo);
    final states = await collect(
      cubit,
      () => cubit.create(name: 'مركز النور', year: 2026),
    );

    expect(states.map((s) => s.status), [
      CreateCenterStatus.submitting,
      CreateCenterStatus.success,
    ]);
    expect(states.last.center?.id, 'c1');
    expect(states.last.center?.name, 'مركز النور');
    expect(repo.calls, ['create:مركز النور:2026']);
  });

  test('فشل: submitting ثم failure برسالة الـ Failure', () async {
    final repo = FakeCentersRepository(
      failure: const Failure.alreadyExists(message: 'لديك مركز بالفعل'),
    );
    final cubit = CreateCenterCubit(repo);
    final states = await collect(
      cubit,
      () => cubit.create(name: 'س', year: 2026),
    );

    expect(states.map((s) => s.status), [
      CreateCenterStatus.submitting,
      CreateCenterStatus.failure,
    ]);
    expect(states.last.failure?.message, 'لديك مركز بالفعل');
    expect(states.last.center, isNull);
  });

  test('ضغطتين ورا بعض: النداء الأول بس', () async {
    final repo = FakeCentersRepository();
    final cubit = CreateCenterCubit(repo);
    await Future.wait([
      cubit.create(name: 'مركز', year: 2026),
      cubit.create(name: 'مركز', year: 2026),
    ]);
    expect(repo.calls, ['create:مركز:2026']);
  });
}
