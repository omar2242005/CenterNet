import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/errors/failure.dart';
import '../../../core/firestore_paths.dart';
import '../../groups/models/group.dart';
import '../models/exam.dart';

/// امتحانات المجموعات: إنشاء (مسودة)، قراءة، نشر وإلغاء نشر.
///
/// * الإنشاء والنشر للأدمن ومعلم المجموعة بس (الـ Rules هي الحكم).
/// * النشر = update لحقل published بس. مفيش حذف.
class ExamsRepository {
  ExamsRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  static const Duration timeout = Duration(seconds: 20);

  /// امتحان جديد (مسودة) في [group]. الـ id بيتولد أوتوماتيك.
  Future<Exam> createExam(
    Group group, {
    required String title,
    required DateTime date,
    required double maxScore,
  }) {
    return ErrorMapper.guard(() async {
      final uid = _requireUid();
      if (group.isArchived) {
        throw const Failure.validation('المجموعة مؤرشفة.');
      }
      final ref = _db.collection(FirestorePaths.exams(group.centerId)).doc();
      final Exam exam;
      try {
        exam = Exam.create(
          id: ref.id,
          centerId: group.centerId,
          groupId: group.id,
          title: title,
          date: date,
          maxScore: maxScore,
          createdBy: uid,
        );
      } on ArgumentError catch (e) {
        throw Failure.validation(e.message.toString());
      }
      await ref.set(exam.toCreateMap()).timeout(timeout);
      return exam;
    });
  }

  /// امتحانات مجموعة، الأحدث الأول (الترتيب في Dart، فمفيش index).
  Future<List<Exam>> loadGroupExams(Group group) {
    return ErrorMapper.guard(() async {
      _requireUid();
      final snap = await _db
          .collection(FirestorePaths.exams(group.centerId))
          .where('groupId', isEqualTo: group.id)
          .get()
          .timeout(timeout);
      final out = <Exam>[];
      for (final doc in snap.docs) {
        try {
          out.add(Exam.fromMap(doc.id, doc.data()));
        } on FormatException {
          continue; // مستند تالف: بنتخطاه
        }
      }
      out.sort((a, b) => b.date.compareTo(a.date));
      return out;
    });
  }

  /// نشر ([published] = true) أو إلغاء نشر. بيرجّع الامتحان بعد التحديث.
  Future<Exam> setPublished(Exam exam, {required bool published}) {
    return ErrorMapper.guard(() async {
      _requireUid();
      if (exam.published == published) {
        throw Failure.validation(
          published ? 'الامتحان منشور بالفعل.' : 'الامتحان مش منشور أصلًا.',
        );
      }
      final ref = _ref(exam.centerId, exam.id);
      await ref
          .update(published ? Exam.toPublishMap() : Exam.toUnpublishMap())
          .timeout(timeout);
      final snap = await ref.get();
      final data = snap.data();
      if (data == null) throw const Failure.notFound();
      try {
        return Exam.fromMap(snap.id, data);
      } on FormatException {
        throw const Failure.unknown();
      }
    });
  }

  DocumentReference<Map<String, dynamic>> _ref(String centerId, String id) =>
      _db.doc(FirestorePaths.exam(centerId, id));

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const Failure.permission();
    return uid;
  }
}