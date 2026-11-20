import 'student.dart';

/// نتيجة تحميل طلاب سنتر: الـ id بتاع السنتر + الطلاب مرتبين بالرقم التسلسلي.
class StudentsRoster {
  const StudentsRoster({required this.centerId, required this.students});

  final String centerId;
  final List<Student> students;
}
