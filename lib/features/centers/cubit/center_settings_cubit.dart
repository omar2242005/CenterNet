import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failure.dart';
import '../../../core/state/view_state.dart';
import '../models/center_info.dart';
import '../repository/centers_repository.dart';

class CenterSettingsState {
  const CenterSettingsState({
    this.view = const ViewLoading<CenterInfo>(),
    this.saving = false,
    this.saved = false,
    this.saveFailure,
  });

  /// تحميل · فارغ (مفيش سنتر) · خطأ · نجاح.
  final ViewState<CenterInfo> view;
  final bool saving;

  /// آخر حفظ نجح (بيتصفّر مع أي محاولة جديدة).
  final bool saved;
  final Failure? saveFailure;

  CenterSettingsState copyWith({
    ViewState<CenterInfo>? view,
    bool? saving,
    bool? saved,
    Failure? saveFailure,
    bool clearSaveFailure = false,
  }) {
    return CenterSettingsState(
      view: view ?? this.view,
      saving: saving ?? this.saving,
      saved: saved ?? this.saved,
      saveFailure: clearSaveFailure ? null : (saveFailure ?? this.saveFailure),
    );
  }
}

class CenterSettingsCubit extends Cubit<CenterSettingsState> {
  CenterSettingsCubit(this._repo) : super(const CenterSettingsState());

  final CentersRepository _repo;

  Future<void> load() async {
    emit(const CenterSettingsState());
    try {
      final center = await _repo.loadMyCenter();
      if (isClosed) return;
      emit(CenterSettingsState(
        view: center == null
            ? const ViewEmpty<CenterInfo>()
            : ViewSuccess<CenterInfo>(center),
      ));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(CenterSettingsState(view: ViewFailed<CenterInfo>(f)));
    }
  }

  Future<void> save({
    required String name,
    required int year,
    required int lateAfterMinutes,
  }) async {
    final current = state.view;
    if (state.saving || current is! ViewSuccess<CenterInfo>) return;
    emit(state.copyWith(saving: true, saved: false, clearSaveFailure: true));
    try {
      await _repo.updateSettings(
        centerId: current.data.id,
        name: name,
        year: year,
        lateAfterMinutes: lateAfterMinutes,
      );
      if (isClosed) return;
      final updated = CenterInfo(
        id: current.data.id,
        name: name.trim(),
        year: year,
        createdBy: current.data.createdBy,
        lateAfterMinutes: lateAfterMinutes,
      );
      emit(CenterSettingsState(
        view: ViewSuccess<CenterInfo>(updated),
        saved: true,
      ));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(state.copyWith(saving: false, saveFailure: f));
    }
  }
}
