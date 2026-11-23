import '../../../core/state/view_state.dart';
import '../models/pending_scan.dart';

class SyncState {
  final ViewState<List<PendingScan>> status;

  const SyncState({
    this.status = const ViewLoading(),
  });
}
