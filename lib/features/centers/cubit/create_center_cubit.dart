import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failure.dart';
import '../models/center_info.dart';
import '../repository/centers_repository.dart';

enum CreateCenterStatus { idle, submitting, success, failure }

class CreateCenterState {
  const CreateCenterState({
    this.status = CreateCenterStatus.idle,
    this.failure,
    this.center,
  });

  final CreateCenterStatus status;
  final Failure? failure;

  /// السنتر اللي اتعمل (في حالة success).
  final CenterInfo? center;

  bool get isSubmitting => status == CreateCenterStatus.submitting;
}

/// عملية "إنشاء سنتر". الاسم والسنة بيوصلوا هنا بعد ما الشاشة تتحقق منهم.
class CreateCenterCubit extends Cubit<CreateCenterState> {
  CreateCenterCubit(this._repo) : super(const CreateCenterState());

  final CentersRepository _repo;

  Future<void> create({required String name, required int year}) async {
    if (state.isSubmitting) return;
    emit(const CreateCenterState(status: CreateCenterStatus.submitting));
    try {
      final center = await _repo.createCenter(name: name, year: year);
      if (isClosed) return;
      emit(
        CreateCenterState(status: CreateCenterStatus.success, center: center),
      );
    } on Failure catch (f) {
      if (isClosed) return;
      emit(CreateCenterState(status: CreateCenterStatus.failure, failure: f));
    }
  }
}
