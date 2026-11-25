import '../../students/models/student.dart';
import 'student_link.dart';

/// طالب مربوط بالحساب الحالي: الربط نفسه + بيانات الطالب.
class LinkedStudent {
  const LinkedStudent({required this.link, required this.student});

  final StudentLink link;
  final Student student;
}
