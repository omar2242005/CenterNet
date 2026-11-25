import '../../../core/state/view_state.dart';
import '../../groups/models/group.dart';
import '../../sessions/models/session.dart';

/// بيانات شاشة الحصص: حصص النهارده + المجموعات بتاعتها (لعرض الاسم والقاعة).
class SessionsData {
  const SessionsData({required this.sessions, required this.groups});

  final List<Session> sessions;

  /// groupId ← المجموعة (لو اتعرف يتجابها).
  final Map<String, Group> groups;
}

class SessionsState {
  final ViewState<SessionsData> status;

  const SessionsState({this.status = const ViewLoading()});

  SessionsState copyWith({ViewState<SessionsData>? status}) =>
      SessionsState(status: status ?? this.status);
}
