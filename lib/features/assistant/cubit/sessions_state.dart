import '../../../core/state/view_state.dart';
import '../../sessions/models/session.dart';

class SessionsState {
  final ViewState<List<Session>> status;

  const SessionsState({
    this.status = const ViewLoading(),
  });
}
