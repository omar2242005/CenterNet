import '../../../core/state/view_state.dart';

class AssistantHomeState {
  final ViewState<void> status;

  const AssistantHomeState({
    this.status = const ViewLoading(),
  });
  // TODO: Add more state properties
}
