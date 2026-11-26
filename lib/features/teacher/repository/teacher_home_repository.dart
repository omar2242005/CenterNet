import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/errors/error_mapper.dart';
import '../../../core/errors/failure.dart';
import '../../../core/firestore_paths.dart';
import '../../groups/repository/groups_repository.dart';
import '../../sessions/models/session.dart';
import '../../students/repository/students_repository.dart';
import '../models/teacher_home_data.dart';
import '../rules/teacher_home_builder.dart';

/// مصدر بيانات رئيسية المعلم (للاختبار بنبدله بـ fake).
abstract class TeacherHomeRepository {
  Future<TeacherHomeData> load({DateTime? now});
}

/// قراءة بس. بيستخدم نفس استعلامات باقي الشاشات:
/// * مجموعاتي: `GroupsRepository.loadMyGroups`.
/// * الطلاب: `StudentsRepository.loadStudents` (المعلم يقدر يقرا القايمة).
/// * الحصص: لكل مجموعة استعلام مقيّد بـ groupId + startAt (نفس الـ index
///   الصاعد groupId + startAt المستخدم في حصص المساعد).
class FirestoreTeacherHomeRepository implements TeacherHomeRepository {
  FirestoreTeacherHomeRepository(
    this._auth,
    this._db,
    this._groups,
    this._students,
  );

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final GroupsRepository _groups;
  final StudentsRepository _students;

  static const Duration timeout = Duration(seconds: 20);

  /// أقرب كام حصة بنقراهم لكل مجموعة (عشان الملغي مايخبّيش اللي بعده).
  static const int sessionsPerGroup = 10;

  @override
  Future<TeacherHomeData> load({DateTime? now}) {
    return ErrorMapper.guard(() async {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw const Failure.permission();
      final clock = now ?? DateTime.now();

      final userSnap = await _db
          .doc(FirestorePaths.user(uid))
          .get()
          .timeout(timeout);
      final rawName = userSnap.data()?['name'];
      final name = rawName is String ? rawName : '';

      final roster = await _groups.loadMyGroups();
      final active = roster.groups.where((g) => !g.isArchived).toList();
      if (active.isEmpty) {
        return buildTeacherHomeData(
          name: name,
          groups: roster.groups,
          students: const [],
          sessions: const [],
          now: clock,
        );
      }

      final students = await _students.loadStudents();

      final cairo = tz.getLocation('Africa/Cairo');
      final n = tz.TZDateTime.from(clock, cairo);
      final dayStart = tz.TZDateTime(cairo, n.year, n.month, n.day);
      final col = _db.collection(FirestorePaths.sessions(roster.centerId));
      final snaps = await Future.wait([
        for (final g in active)
          col
              .where('groupId', isEqualTo: g.id)
              .where(
                'startAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart),
              )
              .orderBy('startAt')
              .limit(sessionsPerGroup)
              .get()
              .timeout(timeout),
      ]);

      final sessions = <Session>[];
      for (final snap in snaps) {
        for (final doc in snap.docs) {
          try {
            sessions.add(Session.fromMap(doc.id, doc.data()));
          } on FormatException {
            continue; // مستند تالف: بنتخطاه
          }
        }
      }

      return buildTeacherHomeData(
        name: name,
        groups: roster.groups,
        students: students.students,
        sessions: sessions,
        now: clock,
      );
    });
  }
}
