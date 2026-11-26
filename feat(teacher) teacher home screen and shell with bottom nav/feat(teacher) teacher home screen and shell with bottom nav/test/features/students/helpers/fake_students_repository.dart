import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/core/utils/arabic_normalizer.dart';
import 'package:center_net/features/students/models/student.dart';
import 'package:center_net/features/students/models/students_roster.dart';
import 'package:center_net/features/students/repository/students_repository.dart';

Student makeStudent(
  int no,
  String name, {
  String phone = '01012345678',
  String grade = 'الصف الأول',
  bool archived = false,
  String centerId = 'c1',
}) {
  return Student.fromMap('s$no', <String, dynamic>{
    'centerId': centerId,
    'studentNo': no,
    'fullName': name,
    'searchKey': buildSearchKey(name),
    'phone': phone,
    'grade': grade,
    'groupIds': <String>[],
    'status': archived ? 'archived' : 'active',
    'createdBy': 'u1',
  });
}

class FakeStudentsRepository implements StudentsRepository {
  FakeStudentsRepository({
    List<Student>? students,
    this.loadFailure,
    this.writeFailure,
  }) : students = students ?? <Student>[];

  /// بيفشّل تحميل القائمة.
  Failure? loadFailure;

  /// بيفشّل الإضافة والتعديل والأرشفة.
  Failure? writeFailure;

  final List<Student> students;
  final List<String> calls = <String>[];

  @override
  Future<StudentsRoster> loadStudents() async {
    calls.add('load');
    final f = loadFailure;
    if (f != null) throw f;
    return StudentsRoster(
      centerId: 'c1',
      students: List<Student>.of(students),
    );
  }

  @override
  Future<Student> addStudent({
    required String fullName,
    required String phone,
    required String grade,
  }) async {
    calls.add('add:$fullName:$phone:$grade');
    final f = writeFailure;
    if (f != null) throw f;
    final s = makeStudent(
      students.length + 1,
      fullName,
      phone: phone,
      grade: grade,
    );
    students.add(s);
    return s;
  }

  @override
  Future<Student> updateStudent(
    Student student, {
    required String fullName,
    required String phone,
    required String grade,
  }) async {
    calls.add('update:${student.id}:$fullName:$phone:$grade');
    final f = writeFailure;
    if (f != null) throw f;
    return makeStudent(
      student.studentNo,
      fullName,
      phone: phone,
      grade: grade,
      archived: student.isArchived,
    );
  }

  @override
  Future<Student> setArchived(Student student, {required bool archived}) async {
    calls.add('archive:${student.id}:$archived');
    final f = writeFailure;
    if (f != null) throw f;
    return makeStudent(
      student.studentNo,
      student.fullName,
      phone: student.phone,
      grade: student.grade,
      archived: archived,
    );
  }
}
