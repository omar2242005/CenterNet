import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/core/state/view_state.dart';
import 'package:center_net/features/student_area/cubit/child_data_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('نجاح', () async {
    final cubit = ChildDataCubit<List<int>>(
      () async => [1, 2],
      isEmpty: (d) => d.isEmpty,
    );
    addTearDown(cubit.close);
    await cubit.load();
    expect(cubit.state, isA<ViewSuccess<List<int>>>());
  });

  test('فارغ', () async {
    final cubit = ChildDataCubit<List<int>>(
      () async => <int>[],
      isEmpty: (d) => d.isEmpty,
    );
    addTearDown(cubit.close);
    await cubit.load();
    expect(cubit.state, isA<ViewEmpty<List<int>>>());
  });

  test('فشل وإعادة المحاولة', () async {
    var fail = true;
    final cubit = ChildDataCubit<int>(() async {
      if (fail) throw const Failure.network();
      return 7;
    });
    addTearDown(cubit.close);

    await cubit.load();
    expect(cubit.state, isA<ViewFailed<int>>());

    fail = false;
    await cubit.load();
    expect((cubit.state as ViewSuccess<int>).data, 7);
  });
}
