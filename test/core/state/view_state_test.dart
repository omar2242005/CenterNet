import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/core/state/view_state.dart';
import 'package:flutter_test/flutter_test.dart';

String describe(ViewState<List<int>> s) => switch (s) {
      ViewLoading() => 'loading',
      ViewEmpty() => 'empty',
      ViewFailed(:final failure) => 'failed:${failure.type.name}',
      ViewSuccess(:final data) => 'success:${data.length}',
    };

void main() {
  test('الحالات الأربع كلها مغطاة في switch', () {
    expect(describe(const ViewLoading()), 'loading');
    expect(describe(const ViewEmpty()), 'empty');
    expect(describe(const ViewFailed(Failure.network())), 'failed:network');
    expect(describe(const ViewSuccess([1, 2])), 'success:2');
  });

  test('listViewState: فاضية = فارغ، غير كده = نجاح', () {
    expect(listViewState<int>([]).isEmpty, isTrue);
    final s = listViewState<int>([1]);
    expect(s.isSuccess, isTrue);
  });

  test('ViewFailed بنفس الـ Failure متساوية (عشان Cubit ما يكررش emit)', () {
    expect(const ViewFailed<int>(Failure.network()),
        const ViewFailed<int>(Failure.network()));
  });

  test('getters', () {
    expect(const ViewLoading<int>().isLoading, isTrue);
    expect(const ViewFailed<int>(Failure.unknown()).isFailed, isTrue);
  });
}
