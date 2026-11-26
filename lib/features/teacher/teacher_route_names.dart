/// مسارات شاشات المعلم. الشاشتين بياخدوا البيانات من extra.
abstract final class TeacherRoutes {
  static const String groups = '/teacher/groups';
  static const String groupDetails = '/teacher/group'; // extra: Group
  static const String exams = '/teacher/exams';
  static const String examCreate = '/teacher/exams/new';
  static const String examDetails = '/teacher/exam'; // extra: TeacherExamArgs
  static const String examScores =
      '/teacher/exam/scores'; // extra: TeacherExamArgs
}
