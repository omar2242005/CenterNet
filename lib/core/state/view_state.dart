import '../errors/failure.dart';

/// الحالات الأربع لأي شاشة بيانات: تحميل · فارغ · خطأ · نجاح.
///
/// الاستخدام في الشاشة:
/// ```dart
/// switch (state) {
///   case ViewLoading(): ...
///   case ViewEmpty(): ...
///   case ViewFailed(:final failure): ... // زر إعادة المحاولة
///   case ViewSuccess(:final data): ...
/// }
/// ```
sealed class ViewState<T> {
  const ViewState();

  bool get isLoading => this is ViewLoading<T>;
  bool get isEmpty => this is ViewEmpty<T>;
  bool get isFailed => this is ViewFailed<T>;
  bool get isSuccess => this is ViewSuccess<T>;
}

class ViewLoading<T> extends ViewState<T> {
  const ViewLoading();
}

class ViewEmpty<T> extends ViewState<T> {
  const ViewEmpty();
}

class ViewFailed<T> extends ViewState<T> {
  final Failure failure;
  const ViewFailed(this.failure);

  @override
  bool operator ==(Object other) =>
      other is ViewFailed<T> && other.failure == failure;

  @override
  int get hashCode => failure.hashCode;
}

class ViewSuccess<T> extends ViewState<T> {
  final T data;
  const ViewSuccess(this.data);
}

/// قائمة فاضية = فارغ، غير كده = نجاح.
ViewState<List<T>> listViewState<T>(List<T> items) =>
    items.isEmpty ? ViewEmpty<List<T>>() : ViewSuccess<List<T>>(items);
