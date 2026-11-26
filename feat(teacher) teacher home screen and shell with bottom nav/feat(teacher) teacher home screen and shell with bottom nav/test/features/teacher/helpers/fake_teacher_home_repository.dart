import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/features/teacher/models/teacher_home_data.dart';
import 'package:center_net/features/teacher/repository/teacher_home_repository.dart';

class FakeTeacherHomeRepository implements TeacherHomeRepository {
  FakeTeacherHomeRepository({this.data, this.failure});

  TeacherHomeData? data;
  Failure? failure;
  int loads = 0;

  @override
  Future<TeacherHomeData> load({DateTime? now}) async {
    loads++;
    final f = failure;
    if (f != null) throw f;
    return data!;
  }
}
