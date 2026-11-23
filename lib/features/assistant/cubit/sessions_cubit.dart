import 'package:flutter_bloc/flutter_bloc.dart';
import 'sessions_state.dart';
import '../repository/assistant_repository.dart';

class SessionsCubit extends Cubit<SessionsState> {
  final AssistantRepository _repository;

  SessionsCubit(this._repository) : super(const SessionsState());

  // TODO: Add sessions logic
}
