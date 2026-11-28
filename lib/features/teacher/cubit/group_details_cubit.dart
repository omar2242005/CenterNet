import 'package:center_net/features/attendance/rules/absence_calculator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failure.dart';
import '../../../core/state/view_state.dart';
import '../../groups/models/group.dart';
import '../../students/models/student.dart';
import '../../students/repository/students_repository.dart';
import '../repository/group_attendance_repository.dart';

class GroupDetailsState {
  const GroupDetailsState({
    required this.group,
    this.students = const <Student>[],
    this.absences = const <String, int>{},
    this.sessionsCount = 0,
    this.loading = true,
    this.failure,
  });

  final Group group;

  /// طلاب المجموعة النشطين مرتبين بالرقم التسلسلي.
  final List<Student> students;

  /// عدد غيابات كل طالب (المفتاح = studentId).
  final Map<String, int> absences;

  /// عدد الحصص الفايتة اللي اتحسب عليها الغياب.
  final int sessionsCount;
  final bool loading;
  final Failure? failure;

  GroupDetailsState copyWith({
    List<Student>? students,
    Map<String, int>? absences,
    int? sessionsCount,
    bool? loading,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return GroupDetailsState(
      group: group,
      students: students ?? this.students,
      absences: absences ?? this.absences,
      sessionsCount: sessionsCount ?? this.sessionsCount,
      loading: loading ?? this.loading,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  int absencesOf(String studentId) => absences[studentId] ?? 0;

  ViewState<List<Student>> get view {
    if (loading) return const ViewLoading<List<Student>>();
    final f = failure;
    if (f != null) return ViewFailed<List<Student>>(f);
    return listViewState<Student>(students);
  }
}

/// تفاصيل مجموعة للمعلم: الطلبة وعدد غياب كل واحد.
class GroupDetailsCubit extends Cubit<GroupDetailsState> {
  GroupDetailsCubit(this._students, this._attendance, Group group)
      : super(GroupDetailsState(group: group));

  final StudentsRepository _students;
  final GroupAttendanceRepository _attendance;

  Future<void> load({DateTime? now}) async {
    emit(state.copyWith(loading: true, clearFailure: true));
    try {
      final group = state.group;
      final clock = now ?? DateTime.now();
      final roster = await _students.loadStudents();
      final data = await _attendance.load(group, now: clock);
      if (isClosed) return;

      final inGroup = <Student>[
        for (final s in roster.students)
          if (!s.isArchived && s.isInGroup(group.id)) s,
      ]..sort((a, b) => a.studentNo.compareTo(b.studentNo));

      final absences = <String, int>{
        for (final s in inGroup)
          s.id: AbsenceCalculator.absenceCount(
            student: s,
            sessions: data.sessions,
            now: clock,
            records: data.records,
          ),
      };

      emit(
        state.copyWith(
          students: inGroup,
          absences: absences,
          sessionsCount: data.sessions.where((s) => s.isCountedAt(clock)).length,
          loading: false,
        ),
      );
    } on Failure catch (f) {
      if (isClosed) return;
      emit(state.copyWith(loading: false, failure: f));
    }
  }
}