import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failure.dart';
import '../../../core/state/view_state.dart';
import '../../groups/models/group.dart';
import '../repository/assistant_repository.dart';
import 'sessions_state.dart';

/// حصص النهارده لسنتر المساعد، مع مجموعاتها للعرض.
class SessionsCubit extends Cubit<SessionsState> {
  SessionsCubit(this._repository) : super(const SessionsState());

  final AssistantRepository _repository;

  Future<void> load() async {
    emit(const SessionsState(status: ViewLoading()));
    try {
      final sessions = await _repository.todaySessions();
      if (sessions.isEmpty) {
        if (!isClosed) emit(const SessionsState(status: ViewEmpty()));
        return;
      }

      // أسماء المجموعات والقاعات. فشل مجموعة واحدة مش بيطيّح القايمة.
      final groupIds = sessions.map((s) => s.groupId).toSet().toList();
      final fetched = await Future.wait(groupIds.map(_tryGroup));
      final groups = <String, Group>{
        for (final g in fetched)
          if (g != null) g.id: g,
      };

      if (isClosed) return;
      emit(
        SessionsState(
          status: ViewSuccess(SessionsData(sessions: sessions, groups: groups)),
        ),
      );
    } on Failure catch (failure) {
      if (!isClosed) emit(SessionsState(status: ViewFailed(failure)));
    }
  }

  Future<Group?> _tryGroup(String groupId) async {
    try {
      return await _repository.groupById(groupId);
    } on Failure {
      return null;
    }
  }
}
