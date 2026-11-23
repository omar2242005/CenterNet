import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_state.dart';
import '../repository/assistant_repository.dart';

class AssistantHomeCubit extends Cubit<AssistantHomeState> {
  final AssistantRepository _repository;

  AssistantHomeCubit(this._repository) : super(const AssistantHomeState());

  // TODO: Add home logic
}
