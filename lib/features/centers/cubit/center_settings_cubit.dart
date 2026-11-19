import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failure.dart';
import '../../../core/state/view_state.dart';
import '../models/center_info.dart';
import '../repository/centers_repository.dart';

class CenterSettingsState {
  const CenterSettingsState({
    this.view = const ViewLoading(),
    this.saving = false,
    this.saveFailure,
    this.savedTick = 0,
  });

  /// تحميل السنتر (4 حالات).
  final ViewState<CenterContext> view;

  /// جاري الحفظ.
  final bool saving;

  /// فشل آخر حفظ (للعرض تحت الفورم).
  final Failure? saveFailure;

  /// بيزيد مع كل حفظ ناجح، عشان الشاشة تعرض "تم الحفظ" مرة لكل حفظ.
  final int savedTick;

  CenterSettingsState copyWith({
    ViewState<CenterContext>? view,
    bool? saving,
    Failure? saveFailure,
    bool clearSaveFailure = false,
    int? savedTick,
  }) {
    return CenterSettingsState(
      view: view ?? this.view,
      saving: saving ?? this.saving,
      saveFailure: clearSaveFailure ? null : (saveFailure ?? this.saveFailure),
      savedTick: savedTick ?? this.savedTick,
    );
  }
}

/// شاشة إعدادات السنتر: تحميل البيانات ثم حفظ التعديلات.
class CenterSettingsCubit extends Cubit<CenterSettingsState> {
  CenterSettingsCubit(this._repo) : super(const CenterSettingsState());

  final CentersRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(view: const ViewLoading(), clearSaveFailure: true));
    try {
      final ctx = await _repo.loadMine();
      if (isClosed) return;
      emit(
        state.copyWith(
          view: ctx == null ? const ViewEmpty() : ViewSuccess(ctx),
        ),
      );
    } on Failure catch (f) {
      if (isClosed) return;
      emit(state.copyWith(view: ViewFailed(f)));
    }
  }

  /// بيحفظ، ولو نجح بيحدّث السنتر المعروض من غير تحميل تاني.
  Future<void> save({
    required String name,
    required int year,
    required int lateAfterMinutes,
  }) async {
    final current = state.view;
    if (state.saving || current is! ViewSuccess<CenterContext>) return;
    final ctx = current.data;
    emit(state.copyWith(saving: true, clearSaveFailure: true));
    try {
      await _repo.updateSettings(
        centerId: ctx.center.id,
        name: name,
        year: year,
        lateAfterMinutes: lateAfterMinutes,
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          saving: false,
          view: ViewSuccess(
            CenterContext(
              center: ctx.center.copyWith(
                name: name,
                year: year,
                lateAfterMinutes: lateAfterMinutes,
              ),
              membership: ctx.membership,
            ),
          ),
          savedTick: state.savedTick + 1,
        ),
      );
    } on Failure catch (f) {
      if (isClosed) return;
      emit(state.copyWith(saving: false, saveFailure: f));
    }
  }
}
