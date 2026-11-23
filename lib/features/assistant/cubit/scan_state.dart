import '../../../core/state/view_state.dart';
import '../rules/scan_result.dart';

class ScanState {
  final ViewState<ScanResult?> status;

  const ScanState({
    this.status = const ViewLoading(),
  });
}
