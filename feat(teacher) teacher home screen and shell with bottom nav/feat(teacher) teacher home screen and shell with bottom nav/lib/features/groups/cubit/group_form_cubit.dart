import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failure.dart';
import '../../../core/utils/arabic_normalizer.dart';
import '../models/group.dart';
import '../models/group_input.dart';
import '../repository/groups_repository.dart';

/// تعارض قاعة وميعاد: المجموعة المعادية والميعاد المتقاطع من مواعيدها.
typedef RoomConflict = ({Group group, GroupSlot slot});

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

  /// بيفحص تعارض القاعة والميعاد مع باقي مجموعات السنتر قبل الحفظ:
  /// نفس اسم القاعة (بعد التطبيع العربي) + ميعاد متقاطع في نفس اليوم.
  /// المؤرشفة والمجموعة اللي بتتعدل مش بيتحسبوا. بيرجّع أول تعارض أو null.
  Future<RoomConflict?> findRoomConflict(GroupInput input) async {
    final room = normalizeArabic(input.room);
    if (room.isEmpty) return null;
    final roster = await _repo.loadGroups();
    for (final other in roster.groups) {
      if (other.isArchived || other.id == editing?.id) continue;
      if (normalizeArabic(other.room) != room) continue;
      for (final mine in input.slots) {
        for (final theirs in other.slots) {
          if (slotsOverlap(mine, theirs)) {
            return (group: other, slot: theirs);
          }
        }
      }
    }
    return null;
  }

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
