import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failure.dart';
import '../models/group.dart';
import '../models/group_input.dart';
import '../repository/groups_repository.dart';

enum GroupFormStatus { idle, submitting, success, failure }

class GroupFormState {
  const GroupFormState({
    this.status = GroupFormStatus.idle,
    this.failure,
    this.saved,
  });

  final GroupFormStatus status;
  final Failure? failure;

  /// المجموعة بعد الحفظ (في حالة النجاح).
  final Group? saved;

  bool get isSubmitting => status == GroupFormStatus.submitting;
}

/// إنشاء مجموعة جديدة، أو تعديل مجموعة لو [editing] متحدد.
class GroupFormCubit extends Cubit<GroupFormState> {
  GroupFormCubit(this._repo, {this.editing}) : super(const GroupFormState());

  final GroupsRepository _repo;
  final Group? editing;

  Future<void> submit(GroupInput input) async {
    if (state.isSubmitting) return;
    emit(const GroupFormState(status: GroupFormStatus.submitting));
    try {
      final current = editing;
      final saved = current == null
          ? await _repo.createGroup(input)
          : await _repo.updateGroup(current, input);
      if (isClosed) return;
      emit(GroupFormState(status: GroupFormStatus.success, saved: saved));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(GroupFormState(status: GroupFormStatus.failure, failure: f));
    }
  }
}
