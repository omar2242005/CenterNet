import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failure.dart';
import '../../../core/state/view_state.dart';

/// تحميل بيانات شاشة (جدول/حضور/نتايج) بالحالات الأربع.
/// [isEmpty] بيحدد إمتى النتيجة تتعرض كـ "فارغ".
class ChildDataCubit<T> extends Cubit<ViewState<T>> {
  ChildDataCubit(this._loader, {this.isEmpty}) : super(ViewLoading<T>());

  final Future<T> Function() _loader;
  final bool Function(T data)? isEmpty;

  Future<void> load() async {
    emit(ViewLoading<T>());
    try {
      final data = await _loader();
      if (isClosed) return;
      emit(
        (isEmpty?.call(data) ?? false)
            ? ViewEmpty<T>()
            : ViewSuccess<T>(data),
      );
    } on Failure catch (f) {
      if (isClosed) return;
      emit(ViewFailed<T>(f));
    }
  }
}
