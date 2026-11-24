import '../../../core/state/view_state.dart';
import '../models/attendance.dart';


class AttendanceState {
  final ViewState<List<Attendance>> status;

  const AttendanceState({
    this.status = const ViewLoading(),
  });
}
