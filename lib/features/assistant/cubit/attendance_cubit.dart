import 'package:flutter_bloc/flutter_bloc.dart';
import 'attendance_state.dart';
import '../repository/assistant_repository.dart';

class AttendanceCubit extends Cubit<AttendanceState> {
  // ignore: unused_field
  final AssistantRepository _repository;

  AttendanceCubit(this._repository) : super(const AttendanceState());

  // TODO: Add attendance logic
}
