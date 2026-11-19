import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/core/state/view_state.dart';
import 'package:center_net/features/centers/cubit/my_center_cubit.dart';
import 'package:center_net/features/centers/models/center_info.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_centers_repository.dart';

void main() {
  test('الحالة الأولى تحميل', () {
    final cubit = MyCenterCubit(FakeCentersRepository());
    expect(cubit.state, isA<ViewLoading>());
  });

  test('load: لو مالوش سنتر = فارغ', () async {
    final cubit = MyCenterCubit(FakeCentersRepository());
    await cubit.load();
    expect(cubit.state, isA<ViewEmpty>());
  });

  test('load: لو عنده سنتر = نجاح ومعاه السنتر والعضوية', () async {
    final cubit = MyCenterCubit(FakeCentersRepository(mine: sampleContext()));
    await cubit.load();
    final state = cubit.state;
    expect(state, isA<ViewSuccess<CenterContext>>());
    state as ViewSuccess<CenterContext>;
    expect(state.data.center.name, 'مركز النور');
    expect(state.data.membership.isAdmin, isTrue);
  });

  test('load: الفشل = خطأ، وإعادة المحاولة بتنجح', () async {
    final repo = FakeCentersRepository(failure: const Failure.network());
    final cubit = MyCenterCubit(repo);
    await cubit.load();
    expect(cubit.state, isA<ViewFailed>());

    repo.failure = null;
    repo.mine = sampleContext();
    await cubit.load();
    expect(cubit.state, isA<ViewSuccess>());
  });
}
