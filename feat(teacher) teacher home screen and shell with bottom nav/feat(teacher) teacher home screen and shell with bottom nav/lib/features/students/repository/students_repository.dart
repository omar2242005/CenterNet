import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/errors/failure.dart';
import '../../../core/firestore_paths.dart';
import '../../../core/utils/arabic_normalizer.dart';
import '../../../core/utils/validators.dart';
import '../models/student.dart';
import '../models/students_roster.dart';

/// إدارة الطلاب (جانب الأدمن): قائمة، إضافة برقم تسلسلي، تعديل، أرشفة.
///
/// * الإضافة Transaction واحدة: بتقرا عدّاد `counters/students` وتكتب الطالب
///   والعدّاد الجديد مع بعض، فالرقم التسلسلي مبيتكررش.
/// * مفيش حذف نهائي: الأرشفة بدل الحذف.
/// * الـ Rules هي الحكم: لو المستخدم مش أدمن الكتابة بتترفض ويتحوّل الرفض
///   لـ [Failure.permission].
class StudentsRepository {
  StudentsRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  /// أقصى مدة انتظار (الكتابة محتاجة نت، زي باقي عمليات الأدمن).
  static const Duration timeout = Duration(seconds: 20);

  /// بيحمّل طلاب سنتر المستخدم الحالي (نشطين ومؤرشفين) مرتبين بالرقم.
  Future<StudentsRoster> loadStudents() {
    return ErrorMapper.guard(() async {
      final centerId = await _myCenterId(_requireUid());
      final snap = await _db
          .collection(FirestorePaths.students(centerId))
          .get()
          .timeout(timeout);

      final students = <Student>[];
      for (final doc in snap.docs) {
        try {
          students.add(Student.fromMap(doc.id, doc.data()));
        } on FormatException {
          // مستند تالف: بنتخطاه بدل ما نوقّع القائمة كلها.
          continue;
        }
      }
      students.sort((a, b) => a.studentNo.compareTo(b.studentNo));
      return StudentsRoster(centerId: centerId, students: students);
    });
  }

  /// بيضيف طالب جديد برقم تسلسلي (Transaction). بيرجّع الطالب المحفوظ.
  Future<Student> addStudent({
    required String fullName,
    required String phone,
    required String grade,
  }) {
    return ErrorMapper.guard(() async {
      final uid = _requireUid();
      final name = _checkedName(fullName);
      final mobile = _checkedMobile(phone);
      final centerId = await _myCenterId(uid);

      final studentRef =
          _db.collection(FirestorePaths.students(centerId)).doc();
      final counterRef = _db.doc(FirestorePaths.studentCounter(centerId));

      final created = await _db.runTransaction<Student>((tx) async {
        final counterSnap = await tx.get(counterRef);
        final raw = counterSnap.data()?['next'];
        final next = raw is int && raw >= 1 ? raw : 1;

        final student = Student.create(
          id: studentRef.id,
          centerId: centerId,
          studentNo: next,
          fullName: name,
          searchKey: buildSearchKey(name),
          phone: mobile,
          grade: grade,
          createdBy: uid,
        );
        tx.set(studentRef, student.toCreateMap());
        tx.set(counterRef, <String, dynamic>{'next': next + 1});
        return student;
      }).timeout(timeout);
      return created;
    });
  }

  /// بيعدّل اسم/موبايل/صف الطالب (من غير ما يلمس المجموعات أو الرقم).
  Future<Student> updateStudent(
    Student student, {
    required String fullName,
    required String phone,
    required String grade,
  }) {
    return ErrorMapper.guard(() async {
      _requireUid();
      final name = _checkedName(fullName);
      final mobile = _checkedMobile(phone);
      final ref = _studentRef(student);
      await ref
          .update(
            Student.toUpdateMap(
              fullName: name,
              searchKey: buildSearchKey(name),
              phone: mobile,
              grade: grade,
              groupIds: student.groupIds,
            ),
          )
          .timeout(timeout);
      return _reload(ref);
    });
  }

  /// أرشفة طالب ([archived] = true) أو استرجاعه. مفيش حذف.
  Future<Student> setArchived(Student student, {required bool archived}) {
    return ErrorMapper.guard(() async {
      _requireUid();
      final ref = _studentRef(student);
      await ref
          .update(archived ? Student.toArchiveMap() : Student.toRestoreMap())
          .timeout(timeout);
      return _reload(ref);
    });
  }

  DocumentReference<Map<String, dynamic>> _studentRef(Student s) =>
      _db.doc(FirestorePaths.student(s.centerId, s.id));

  Future<Student> _reload(DocumentReference<Map<String, dynamic>> ref) async {
    final snap = await ref.get();
    final data = snap.data();
    if (data == null) throw const Failure.notFound();
    try {
      return Student.fromMap(snap.id, data);
    } on FormatException {
      throw const Failure.unknown();
    }
  }

  String _checkedName(String input) {
    if (Validators.name(input) != null) {
      throw const Failure.validation('اكتب اسم الطالب بشكل صحيح.');
    }
    return input.trim();
  }

  String _checkedMobile(String input) {
    if (Validators.mobile(input) != null) {
      throw const Failure.validation('رقم الموبايل غير صالح، مثال: 01012345678');
    }
    return Validators.normalizeMobile(input);
  }

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const Failure.permission();
    return uid;
  }

  Future<String> _myCenterId(String uid) async {
    final userSnap = await _db.doc(FirestorePaths.user(uid)).get();
    final centerId = userSnap.data()?['centerId'];
    if (centerId is! String) {
      throw const Failure.notFound(
        message: 'أنشئ سنتر أولًا قبل إدارة الطلاب.',
      );
    }
    return centerId;
  }
}
