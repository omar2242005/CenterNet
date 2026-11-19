import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failure.dart';
import '../repository/centers_repository.dart';

enum CreateCenterStatus { idle, submitting, success, failure }

class CreateCenterState {
  const CreateCenterState({
    this.status = CreateCenterStatus.idle,
    this.failure,
    this.centerId,
  });

  final CreateCenterStatus status;
  final Failure? failure;
  final String? centerId;

  bool get isSubmitting => status == CreateCenterStatus.submitting;
}

class CreateCenterCubit extends Cubit<CreateCenterState> {
  CreateCenterCubit(this._repo) : super(const CreateCenterState());

  final CentersRepository _repo;

  Future<void> submit({required String name, required int year}) async {
    if (state.isSubmitting) return;
    emit(const CreateCenterState(status: CreateCenterStatus.submitting));
    try {
      final id = await _repo.createCenter(name: name, year: year);
      if (isClosed) return;
      emit(CreateCenterState(status: CreateCenterStatus.success, centerId: id));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(CreateCenterState(status: CreateCenterStatus.failure, failure: f));
    }
  }
}
