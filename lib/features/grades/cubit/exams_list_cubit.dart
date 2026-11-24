import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failure.dart';
import '../../../core/state/view_state.dart';
import '../../groups/models/group.dart';
import '../models/exam.dart';
import '../repositories/exams_repository.dart';

class ExamsListState {
  const ExamsListState({
    this.exams = const <Exam>[],
    this.loading = true,
    this.failure,
    this.busyExamId,
  });

  final List<Exam> exams;
  final bool loading;
  final Failure? failure;

  /// الامتحان اللي عليه نشر/إلغاء نشر شغال دلوقتي.
  final String? busyExamId;

  ExamsListState copyWith({
    List<Exam>? exams,
    bool? loading,
    Failure? failure,
    bool clearFailure = false,
    String? busyExamId,
    bool clearBusy = false,
  }) {
    return ExamsListState(
      exams: exams ?? this.exams,
      loading: loading ?? this.loading,
      failure: clearFailure ? null : (failure ?? this.failure),
      busyExamId: clearBusy ? null : (busyExamId ?? this.busyExamId),
    );
  }

  /// تحميل · فارغ · خطأ · نجاح.
  ViewState<List<Exam>> get view {
    if (loading) return const ViewLoading<List<Exam>>();
    final f = failure;
    if (f != null) return ViewFailed<List<Exam>>(f);
    return listViewState<Exam>(exams);
  }
}

/// امتحانات مجموعة: قراءة + نشر وإلغاء نشر.
class ExamsListCubit extends Cubit<ExamsListState> {
  ExamsListCubit(this._repo, this.group) : super(const ExamsListState());

  final ExamsRepository _repo;
  final Group group;

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearFailure: true));
    try {
      final exams = await _repo.loadGroupExams(group);
      if (isClosed) return;
      emit(state.copyWith(exams: exams, loading: false));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(state.copyWith(loading: false, failure: f));
    }
  }

  /// نشر أو إلغاء نشر. بيرجّع الخطأ (للـ SnackBar) أو null.
  Future<Failure?> setPublished(Exam exam, {required bool published}) async {
    if (state.busyExamId != null) return null;
    emit(state.copyWith(busyExamId: exam.id));
    try {
      final updated = await _repo.setPublished(exam, published: published);
      if (isClosed) return null;
      emit(
        state.copyWith(
          exams: [for (final e in state.exams) e.id == updated.id ? updated : e],
          clearBusy: true,
        ),
      );
      return null;
    } on Failure catch (f) {
      if (!isClosed) emit(state.copyWith(clearBusy: true));
      return f;
    }
  }
}