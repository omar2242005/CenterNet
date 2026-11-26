import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failure.dart';
import '../../../core/state/view_state.dart';
import '../models/teacher_home_data.dart';
import '../repository/teacher_home_repository.dart';

class TeacherHomeState {
  const TeacherHomeState({this.status = const ViewLoading<TeacherHomeData>()});

  final ViewState<TeacherHomeData> status;
}

/// منطق رئيسية المعلم: تحميل مرة واحدة + إعادة محاولة.
class TeacherHomeCubit extends Cubit<TeacherHomeState> {
  TeacherHomeCubit(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      super(const TeacherHomeState());

  final TeacherHomeRepository _repository;
  final DateTime Function() _clock;

  Future<void> load() async {
    emit(const TeacherHomeState());
    try {
      final data = await _repository.load(now: _clock());
      if (isClosed) return;
      emit(
        TeacherHomeState(
          // مفيش مجموعات = حالة فاضية برسالة، مش كروت أصفار.
          status: data.groupsCount == 0
              ? const ViewEmpty<TeacherHomeData>()
              : ViewSuccess<TeacherHomeData>(data),
        ),
      );
    } on Failure catch (f) {
      if (isClosed) return;
      emit(TeacherHomeState(status: ViewFailed<TeacherHomeData>(f)));
    }
  }
}
