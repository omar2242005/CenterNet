import 'package:flutter_bloc/flutter_bloc.dart';
import 'scan_state.dart';
import '../repository/assistant_repository.dart';

class ScanCubit extends Cubit<ScanState> {
  // ignore: unused_field
  final AssistantRepository _repository;

  ScanCubit(this._repository) : super(const ScanState());

  // TODO: Add scan logic
}
