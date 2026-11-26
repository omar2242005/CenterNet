import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failure.dart';
import '../../../core/state/view_state.dart';
import '../../../core/utils/arabic_normalizer.dart';
import '../../students/models/student.dart';
import '../../students/repository/students_repository.dart';
import '../models/group.dart';
import '../repository/groups_repository.dart';

class GroupEnrollmentState {
  const GroupEnrollmentState({
    required this.group,
    this.students = const <Student>[],
    this.query = '',
    this.loading = true,
    this.failure,
    this.busyStudentId,
  });

  final Group group;
  final List<Student> students;
  final String query;
  final bool loading;
  final Failure? failure;

  /// الطالب اللي عليه عملية تسجيل/إلغاء شغالة دلوقتي.
  final String? busyStudentId;

  GroupEnrollmentState copyWith({
    List<Student>? students,
    String? query,
    bool? loading,
    Failure? failure,
    bool clearFailure = false,
    String? busyStudentId,
    bool clearBusy = false,
  }) {
    return GroupEnrollmentState(
      group: group,
      students: students ?? this.students,
      query: query ?? this.query,
      loading: loading ?? this.loading,
      failure: clearFailure ? null : (failure ?? this.failure),
      busyStudentId: clearBusy ? null : (busyStudentId ?? this.busyStudentId),
    );
  }

  List<Student> get enrolled =>
      <Student>[for (final s in students) if (s.isInGroup(group.id)) s];

  /// تحذير بس (مش منع): السعة وصلت حدها.
  bool get isFull => group.isFull(enrolled.length);

  /// الطلاب النشطين، والمؤرشف لو لسه مسجّل (عشان يقدر الأدمن يشيله).
  List<Student> get visible {
    final q = normalizeArabic(query);
    return <Student>[
      for (final s in students)
        if ((!s.isArchived || s.isInGroup(group.id)) &&
            (q.isEmpty ||
                matchesSearch(s.searchKey, q) ||
                s.studentNo.toString() == q))
          s,
    ];
  }

  ViewState<List<Student>> get view {
    if (loading) return const ViewLoading<List<Student>>();
    final f = failure;
    if (f != null) return ViewFailed<List<Student>>(f);
    return listViewState<Student>(visible);
  }
}

/// تسجيل طلاب في مجموعة وإلغاء تسجيلهم.
class GroupEnrollmentCubit extends Cubit<GroupEnrollmentState> {
  GroupEnrollmentCubit(this._students, this._groups, Group group)
      : super(GroupEnrollmentState(group: group));

  final StudentsRepository _students;
  final GroupsRepository _groups;

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearFailure: true));
    try {
      final roster = await _students.loadStudents();
      if (isClosed) return;
      emit(state.copyWith(students: roster.students, loading: false));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(state.copyWith(loading: false, failure: f));
    }
  }

  void setQuery(String query) => emit(state.copyWith(query: query));

  /// بيسجّل الطالب لو مش مسجّل، وبيشيله لو مسجّل. بيرجّع الخطأ أو null.
  Future<Failure?> toggle(Student student) async {
    if (state.busyStudentId != null) return null;
    final group = state.group;
    final current = state.students.firstWhere(
      (s) => s.id == student.id,
      orElse: () => student,
    );
    final wasEnrolled = current.isInGroup(group.id);

    emit(state.copyWith(busyStudentId: current.id));
    try {
      if (wasEnrolled) {
        await _groups.unenrollStudent(group, current);
      } else {
        await _groups.enrollStudent(group, current);
      }
      if (isClosed) return null;
      final ids = wasEnrolled
          ? <String>[for (final id in current.groupIds) if (id != group.id) id]
          : <String>[...current.groupIds, group.id];
      final updated = current.withGroupIds(ids);
      emit(
        state.copyWith(
          students: [
            for (final s in state.students) s.id == updated.id ? updated : s,
          ],
          clearBusy: true,
        ),
      );
      return null;
    } on Failure catch (f) {
      if (!isClosed) emit(state.copyWith(clearBusy: true));
      return f;
    }
  }
}
