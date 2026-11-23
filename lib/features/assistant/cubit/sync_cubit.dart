import 'package:flutter_bloc/flutter_bloc.dart';
import 'sync_state.dart';
import '../repository/assistant_repository.dart';

class SyncCubit extends Cubit<SyncState> {
  // ignore: unused_field
  final AssistantRepository _repository;

  SyncCubit(this._repository) : super(const SyncState());

  // TODO: Add sync logic
}
