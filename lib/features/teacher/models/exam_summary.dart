import '../../grades/models/exam.dart';
import '../../groups/models/group.dart';

/// حالة امتحان في قايمة المعلم.
enum TeacherExamStatus {
  /// لسه ماجاش ميعاده.
  upcoming,

  /// ميعاده عدّى وفيه طلاب لسه ماترصدلهمش.
  inProgress,

  /// كل طلاب المجموعة اترصدوا.
  graded,
}

/// امتحان + مجموعته + أرقام الرصد (لقايمة امتحانات المعلم).
class ExamSummary {
  const ExamSummary({
    required this.exam,
    required this.group,
    required this.studentCount,
    required this.recordedCount,
  });

  final Exam exam;
  final Group group;

  /// طلاب المجموعة النشطين.
  final int studentCount;

  /// كام طالب اترصد (أي حالة: درجة أو غائب أو معفى).
  final int recordedCount;

  TeacherExamStatus statusAt(DateTime now) {
    if (exam.date.isAfter(now)) return TeacherExamStatus.upcoming;
    if (studentCount > 0 && recordedCount >= studentCount) {
      return TeacherExamStatus.graded;
    }
    return TeacherExamStatus.inProgress;
  }
}

/// بيانات شاشة الإنشاء/التفاصيل/الرصد: الامتحان والمجموعة اللي بيتبعها.
class TeacherExamArgs {
  const TeacherExamArgs(this.group, this.exam);

  final Group group;
  final Exam exam;
}
