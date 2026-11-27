import '../../students/models/student.dart';

/// بيانات شاشة التحديثات: الطلاب (واحد للطالب، وكل الأبناء لولي الأمر).
class UpdatesArgs {
  const UpdatesArgs({required this.students, required this.guardian});

  final List<Student> students;
  final bool guardian;
}
