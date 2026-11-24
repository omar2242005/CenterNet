import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/errors/failure.dart';
import '../../../core/firestore_paths.dart';
import '../models/exam.dart';
import '../models/score.dart';

/// درجات امتحان: قراءة ورصد.
///
/// * الرصد Transaction: لو الدرجة مش موجودة بتتكتب (create)، ولو موجودة
///   بتتعدّل (update لـ state/score/comment بس). الـ Rules بترفض set فوق
///   درجة موجودة، فمينفعش نكتبها بـ set مباشر.
/// * الرصد محتاج نت (Transaction بتفشل أوفلاين).
/// * معلم المجموعة والأدمن بس يرصدوا (الـ Rules هي الحكم).
class ScoresRepository {
  ScoresRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  static const Duration timeout = Duration(seconds: 20);

  /// كل درجات الامتحان.
  Future<List<Score>> loadExamScores(Exam exam) {
    return ErrorMapper.guard(() async {
      _requireUid();
      final snap = await _db
          .collection(FirestorePaths.scores(exam.centerId))
          .where('examId', isEqualTo: exam.id)
          .get()
          .timeout(timeout);
      final out = <Score>[];
      for (final doc in snap.docs) {
        try {
          out.add(Score.fromMap(doc.id, doc.data()));
        } on FormatException {
          continue; // مستند تالف: بنتخطاه
        }
      }
      return out;
    });
  }

  /// رصد (أو تعديل) درجة طالب. [score] مطلوبة مع scored، وممنوعة مع
  /// الغائب والمعفى. بيرجّع الدرجة المحفوظة.
  Future<Score> saveScore({
    required Exam exam,
    required String studentId,
    required ScoreState state,
    double? score,
    String comment = '',
  }) {
    return ErrorMapper.guard(() async {
      final uid = _requireUid();
      final Score entry;
      try {
        entry = Score.create(
          centerId: exam.centerId,
          examId: exam.id,
          studentId: studentId,
          state: state,
          maxScore: exam.maxScore,
          createdBy: uid,
          score: score,
          comment: comment,
        );
      } on ArgumentError catch (e) {
        throw Failure.validation(e.message.toString());
      }

      final ref = _ref(entry.centerId, entry.id);
      await _db.runTransaction<void>((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) {
          tx.set(ref, entry.toCreateMap());
        } else {
          tx.update(ref, <String, dynamic>{
            'state': entry.state.wire,
            'score': entry.score,
            'comment': entry.comment,
          });
        }
      }).timeout(timeout);

      final snap = await ref.get();
      final data = snap.data();
      if (data == null) throw const Failure.notFound();
      try {
        return Score.fromMap(snap.id, data);
      } on FormatException {
        throw const Failure.unknown();
      }
    });
  }

  DocumentReference<Map<String, dynamic>> _ref(String centerId, String id) =>
      _db.doc(FirestorePaths.score(centerId, id));

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const Failure.permission();
    return uid;
  }
}