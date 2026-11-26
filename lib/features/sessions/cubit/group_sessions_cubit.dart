import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failure.dart';
import '../../../core/state/view_state.dart';
import '../../groups/models/group.dart';
import '../models/session.dart';
import '../repository/sessions_repository.dart';

class GroupSessionsState {
  const GroupSessionsState({
    this.sessions = const <Session>[],
    this.loading = true,
    this.failure,
    this.generating = false,
    this.cancellingId,
    this.deletingId,
  });

  final List<Session> sessions;
  final bool loading;
  final Failure? failure;

  /// توليد "الأسابيع الجاية" شغال دلوقتي.
  final bool generating;

  /// الحصة اللي عليها إلغاء شغال دلوقتي (إلغاء واحد في المرة).
  final String? cancellingId;

  /// الحصة اللي عليها مسح نهائي شغال دلوقتي.
  final String? deletingId;

  GroupSessionsState copyWith({
    List<Session>? sessions,
    bool? loading,
    Failure? failure,
    bool clearFailure = false,
    bool? generating,
    String? cancellingId,
    bool clearCancelling = false,
    String? deletingId,
    bool clearDeleting = false,
  }) {
    return GroupSessionsState(
      sessions: sessions ?? this.sessions,
      loading: loading ?? this.loading,
      failure: clearFailure ? null : (failure ?? this.failure),
      generating: generating ?? this.generating,
      cancellingId: clearCancelling ? null : (cancellingId ?? this.cancellingId),
      deletingId: clearDeleting ? null : (deletingId ?? this.deletingId),
    );
  }

  /// تحميل · فارغ · خطأ · نجاح.
  ViewState<List<Session>> get view {
    if (loading) return const ViewLoading<List<Session>>();
    final f = failure;
    if (f != null) return ViewFailed<List<Session>>(f);
    return listViewState<Session>(sessions);
  }
}

/// حصص مجموعة واحدة (من النهارده): عرض، توليد الأسابيع الجاية، إلغاء.
class GroupSessionsCubit extends Cubit<GroupSessionsState> {
  GroupSessionsCubit(this._repo, this.group)
      : super(const GroupSessionsState());

  final SessionsRepository _repo;
  final Group group;

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearFailure: true));
    try {
      final sessions = await _repo.loadGroupSessions(group);
      if (isClosed) return;
      emit(state.copyWith(sessions: sessions, loading: false));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(state.copyWith(loading: false, failure: f));
    }
  }

  /// بيولّد حصص الأسابيع الجاية ويعيد تحميل القائمة.
  /// بيرجّع نتيجة التوليد عند النجاح، أو الخطأ عند الفشل (للـ SnackBar).
  Future<({GenerateResult? result, Failure? failure})> generate() async {
    if (state.generating) return (result: null, failure: null);
    emit(state.copyWith(generating: true));
    try {
      final result = await _repo.generateUpcoming(group);
      final sessions = await _repo.loadGroupSessions(group);
      if (isClosed) return (result: result, failure: null);
      emit(state.copyWith(sessions: sessions, generating: false));
      return (result: result, failure: null);
    } on Failure catch (f) {
      if (!isClosed) emit(state.copyWith(generating: false));
      return (result: null, failure: f);
    }
  }

  /// بيلغي الحصة ويحدّثها في القائمة. بيرجّع الخطأ (للـ SnackBar) أو null.
  Future<Failure?> cancel(Session session) async {
    if (state.cancellingId != null) return null;
    emit(state.copyWith(cancellingId: session.id));
    try {
      final updated = await _repo.cancelSession(session);
      if (isClosed) return null;
      emit(
        state.copyWith(
          sessions: [
            for (final s in state.sessions)
              if (s.id == updated.id) updated else s,
          ],
          clearCancelling: true,
        ),
      );
      return null;
    } on Failure catch (f) {
      if (!isClosed) emit(state.copyWith(clearCancelling: true));
      return f;
    }
  }

  /// بيمسح حصة ملغاة نهائيًا ويشيلها من القائمة. بيرجّع الخطأ أو null.
  Future<Failure?> deleteCancelled(Session session) async {
    if (state.deletingId != null || state.cancellingId != null) return null;
    emit(state.copyWith(deletingId: session.id));
    try {
      await _repo.deleteCancelledSession(session);
      if (isClosed) return null;
      emit(
        state.copyWith(
          sessions: [
            for (final s in state.sessions)
              if (s.id != session.id) s,
          ],
          clearDeleting: true,
        ),
      );
      return null;
    } on Failure catch (f) {
      if (!isClosed) emit(state.copyWith(clearDeleting: true));
      return f;
    }
  }
}
