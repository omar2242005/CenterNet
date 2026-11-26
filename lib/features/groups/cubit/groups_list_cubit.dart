import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failure.dart';
import '../../../core/state/view_state.dart';
import '../models/group.dart';
import '../repository/groups_repository.dart';

class GroupsListState {
  const GroupsListState({
    this.all = const <Group>[],
    this.showArchived = false,
    this.loading = true,
    this.failure,
  });

  final List<Group> all;
  final bool showArchived;
  final bool loading;
  final Failure? failure;

  GroupsListState copyWith({
    List<Group>? all,
    bool? showArchived,
    bool? loading,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return GroupsListState(
      all: all ?? this.all,
      showArchived: showArchived ?? this.showArchived,
      loading: loading ?? this.loading,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  List<Group> get visible => <Group>[
        for (final g in all)
          if (showArchived || !g.isArchived) g,
      ];

  /// تحميل · فارغ · خطأ · نجاح.
  ViewState<List<Group>> get view {
    if (loading) return const ViewLoading<List<Group>>();
    final f = failure;
    if (f != null) return ViewFailed<List<Group>>(f);
    return listViewState<Group>(visible);
  }
}

/// قائمة المجموعات. [mineOnly] = false للأدمن (كل المجموعات)،
/// و true للمعلم والمساعد (مجموعاتهم بس).
class GroupsListCubit extends Cubit<GroupsListState> {
  GroupsListCubit(this._repo, {this.mineOnly = false})
      : super(const GroupsListState());

  final GroupsRepository _repo;
  final bool mineOnly;

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearFailure: true));
    try {
      final roster =
          mineOnly ? await _repo.loadMyGroups() : await _repo.loadGroups();
      if (isClosed) return;
      emit(state.copyWith(all: roster.groups, loading: false));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(state.copyWith(loading: false, failure: f));
    }
  }

  void setShowArchived(bool value) => emit(state.copyWith(showArchived: value));

  /// بيأرشف المجموعة ويحدّث القائمة محليًا. بيرجّع الخطأ (للـ SnackBar) أو null.
  Future<Failure?> archive(Group group) async {
    try {
      final updated = await _repo.archiveGroup(group);
      if (isClosed) return null;
      emit(
        state.copyWith(
          all: [for (final g in state.all) g.id == updated.id ? updated : g],
        ),
      );
      return null;
    } on Failure catch (f) {
      return f;
    }
  }

  /// بيسترجع المجموعة المؤرشفة ويحدّث القائمة محليًا. بيرجّع الخطأ أو null.
  Future<Failure?> unarchive(Group group) async {
    try {
      final updated = await _repo.unarchiveGroup(group);
      if (isClosed) return null;
      emit(
        state.copyWith(
          all: [for (final g in state.all) g.id == updated.id ? updated : g],
        ),
      );
      return null;
    } on Failure catch (f) {
      return f;
    }
  }

  /// بيحذف المجموعة نهائيًا ويشيلها من القائمة. الريبو بيرفض لو ليها حصص
  /// أو طلاب — بيرجّع الخطأ (للـ SnackBar) أو null.
  Future<Failure?> deletePermanently(Group group) async {
    try {
      await _repo.deleteGroup(group);
      if (isClosed) return null;
      emit(
        state.copyWith(
          all: [for (final g in state.all) if (g.id != group.id) g],
        ),
      );
      return null;
    } on Failure catch (f) {
      return f;
    }
  }
}
