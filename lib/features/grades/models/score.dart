import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore_paths.dart';

/// حالة رصد الطالب في امتحان.
///
/// * [scored]: الطالب له درجة (ممكن صفر).
/// * [absent]: غائب.
/// * [excused]: معفى.
///
/// "لسه" مش حالة: معناها إن مفيش مستند `scores` أصلًا للطالب ده.
enum ScoreState {
  scored('scored'),
  absent('absent'),
  excused('excused');

  const ScoreState(this.wire);
  final String wire;

  static ScoreState parse(Object? raw) {
    for (final s in ScoreState.values) {
      if (s.wire == raw) return s;
    }
    throw FormatException('حالة درجة غير معروفة: $raw');
  }
}

/// مستند `centers/{c}/scores/{examId_sid}` (الـ id حتمي من [FirestoreIds.score]).
///
/// * الدرجة بتتكتب وقت الحفظ بس (الرصد محتاج نت)، ومفيش حذف.
/// * [score] موجودة لما الحالة [ScoreState.scored] **فقط**، ومن 0 لحد
///   الدرجة النهائية بخطوة 0.5. الصفر درجة حقيقية، والخانة الفاضية مش صفر.
/// * الغائب والمعفى ملهمش درجة (`score = null`)، وبرّه متوسط الطالب.
class Score {
  /// أقصى طول للتعليق.
  static const int maxCommentLength = 300;

  final String id;
  final String centerId;
  final String examId;
  final String studentId;
  final ScoreState state;

  /// null لو [state] مش [ScoreState.scored].
  final double? score;
  final String comment;

  /// null قبل ما السيرفر يكتب الوقت (قراءة من الكاش بعد كتابة محلية).
  final DateTime? createdAt;
  final String createdBy;

  const Score._({
    required this.id,
    required this.centerId,
    required this.examId,
    required this.studentId,
    required this.state,
    required this.score,
    required this.comment,
    required this.createdBy,
    this.createdAt,
  });

  /// رصد جديد. [maxScore] الدرجة النهائية للامتحان (للتحقق من النطاق).
  ///
  /// بيرمي ArgumentError لو: الدرجة ناقصة مع scored، أو موجودة مع
  /// absent/excused، أو برّه 0..[maxScore]، أو مش بخطوة 0.5، أو التعليق طويل.
  factory Score.create({
    required String centerId,
    required String examId,
    required String studentId,
    required ScoreState state,
    required double maxScore,
    required String createdBy,
    double? score,
    String comment = '',
  }) {
    // بيرمي ArgumentError لو أي جزء مش حروف وأرقام.
    FirestorePaths.center(centerId);
    final id = FirestoreIds.score(examId, studentId);
    if (createdBy.isEmpty) {
      throw ArgumentError.value(createdBy, 'createdBy', 'مينفعش يكون فاضي');
    }
    final note = comment.trim();
    if (note.length > maxCommentLength) {
      throw ArgumentError.value(
        comment,
        'comment',
        'أطول من $maxCommentLength حرف',
      );
    }
    if (state == ScoreState.scored) {
      if (score == null) {
        throw ArgumentError.value(score, 'score', 'الدرجة مطلوبة');
      }
      _requireValidValue(score, maxScore);
    } else if (score != null) {
      throw ArgumentError.value(
        score,
        'score',
        'الغائب والمعفى ملهمش درجة',
      );
    }
    return Score._(
      id: id,
      centerId: centerId,
      examId: examId,
      studentId: studentId,
      state: state,
      score: state == ScoreState.scored ? score : null,
      comment: note,
      createdBy: createdBy,
    );
  }

  /// قراءة مستند. [id] هو id المستند. بيرمي FormatException لو تالف.
  factory Score.fromMap(String id, Map<String, dynamic> map) {
    final centerId = map['centerId'];
    final examId = map['examId'];
    final studentId = map['studentId'];
    final createdBy = map['createdBy'];
    if (centerId is! String ||
        examId is! String ||
        studentId is! String ||
        createdBy is! String) {
      throw const FormatException(
        'درجة ناقصة centerId أو examId أو studentId أو createdBy',
      );
    }
    final state = ScoreState.parse(map['state']);
    final raw = map['score'];
    double? value;
    if (state == ScoreState.scored) {
      if (raw is! num || !raw.isFinite || raw < 0) {
        throw const FormatException('درجة مرصودة من غير قيمة صالحة');
      }
      value = raw.toDouble();
    } else if (raw != null) {
      throw const FormatException('غائب/معفى وليه درجة');
    }
    return Score._(
      id: id,
      centerId: centerId,
      examId: examId,
      studentId: studentId,
      state: state,
      score: value,
      comment: (map['comment'] as String?) ?? '',
      createdAt: _toDate(map['createdAt']),
      createdBy: createdBy,
    );
  }

  /// الـ map بتاع الإنشاء/الحفظ. [createdAt] اختياري للاختبار؛ الافتراضي
  /// serverTimestamp.
  Map<String, dynamic> toCreateMap({Object? createdAt}) {
    return <String, dynamic>{
      'centerId': centerId,
      'examId': examId,
      'studentId': studentId,
      'state': state.wire,
      'score': score,
      'comment': comment,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'createdBy': createdBy,
    };
  }

  /// هل الدرجة بتدخل في المتوسط؟ المرصودة فقط (غائب/معفى برّه).
  bool get isCounted => state == ScoreState.scored && score != null;

  static void _requireValidValue(double value, double maxScore) {
    if (!value.isFinite || value < 0 || value > maxScore) {
      throw ArgumentError.value(
        value,
        'score',
        'الدرجة من 0 لحد $maxScore',
      );
    }
    if (value * 2 != (value * 2).roundToDouble()) {
      throw ArgumentError.value(value, 'score', 'الدرجة بخطوة 0.5');
    }
  }

  static DateTime? _toDate(Object? raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }
}
