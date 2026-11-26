import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/firestore_paths.dart';
import '../../assistant/models/attendance.dart';
import '../../grades/models/exam.dart';
import '../../grades/models/score.dart';
import '../../groups/models/group.dart';
import '../../students/models/student.dart';
import '../models/child_data.dart';

/// قراءة بيانات طالب مربوط (جدول، حضور، نتايج) للطالب أو ولي الأمر.
///
/// قراءة فقط. الـ Rules هي الحكم: الطالب المربوط بس، والامتحانات المنشورة بس.
class StudentDataRepository {
  StudentDataRepository(this._db);

  final FirebaseFirestore _db;

  static const Duration timeout = Duration(seconds: 20);

  Future<List<Group>> _loadGroups(Student s) async {
    final snaps = await Future.wait(
      s.groupIds.map(
        (id) => _db
            .doc(FirestorePaths.group(s.centerId, id))
            .get()
            .timeout(timeout),
      ),
    );
    final out = <Group>[];
    for (final snap in snaps) {
      final data = snap.data();
      if (data == null) continue;
      try {
        out.add(Group.fromMap(snap.id, data));
      } on FormatException {
        continue; // مستند تالف: بنتخطاه
      }
    }
    return out;
  }

  /// الجدول الأسبوعي من مواعيد مجموعات الطالب.
  Future<List<ScheduleEntry>> loadSchedule(Student s) {
    return ErrorMapper.guard(() async => buildSchedule(await _loadGroups(s)));
  }

  /// سجل حضور الطالب (من غير الملغي).
  Future<AttendanceHistory> loadAttendance(Student s) {
    return ErrorMapper.guard(() async {
      final snap = await _db
          .collection(FirestorePaths.attendance(s.centerId))
          .where('studentId', isEqualTo: s.id)
          .get()
          .timeout(timeout);
      final records = <Attendance>[];
      for (final doc in snap.docs) {
        try {
          records.add(Attendance.fromMap(doc.id, doc.data()));
        } on FormatException {
          continue;
        }
      }
      final groups = await _loadGroups(s);
      return buildAttendanceHistory(records, {
        for (final g in groups) g.id: g.name,
      });
    });
  }

  /// نتايج الطالب في الامتحانات المنشورة بس.
  ///
  /// الدرجات بتتقرا بالـ id (`examId_studentId`) مش بـ query، لأن الـ Rules
  /// بتشترط الامتحان منشور وده مينفعش يتثبت في query. غياب الدرجة (أو رفض
  /// الـ Rules لمستند مش موجود) = لسه متسجلتش.
  Future<ResultsData> loadResults(Student s) {
    return ErrorMapper.guard(() async {
      final exams = <Exam>[];
      for (final gid in s.groupIds) {
        final snap = await _db
            .collection(FirestorePaths.exams(s.centerId))
            .where('groupId', isEqualTo: gid)
            .where('published', isEqualTo: true)
            .get()
            .timeout(timeout);
        for (final doc in snap.docs) {
          try {
            exams.add(Exam.fromMap(doc.id, doc.data()));
          } on FormatException {
            continue;
          }
        }
      }
      final scores = await Future.wait(exams.map((e) => _score(s, e)));
      return buildResults(exams, scores.whereType<Score>());
    });
  }

  Future<Score?> _score(Student s, Exam e) async {
    try {
      final snap = await _db
          .doc(
            FirestorePaths.score(
              s.centerId,
              FirestoreIds.score(e.id, s.id),
            ),
          )
          .get()
          .timeout(timeout);
      final data = snap.data();
      if (data == null) return null;
      return Score.fromMap(snap.id, data);
    } on FirebaseException catch (err) {
      if (err.code == 'permission-denied') return null;
      rethrow;
    } on FormatException {
      return null;
    }
  }
}
