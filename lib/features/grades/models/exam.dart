import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore_paths.dart';

/// مستند `centers/{c}/exams/{id}`.
///
/// * بيتعمل **مسودة** (`published = false`): الطالب وولي الأمر مبيشوفوهوش.
/// * النشر = تغيير `published` بس (كتابة واحدة، للمعلم والأدمن)، والتراجع
///   عنه ممكن. مفيش حذف.
/// * [maxScore] لازم يكون أكبر من صفر. الدرجات نفسها في [Score].
class Exam {
  /// أقصى طول لعنوان الامتحان.
  static const int maxTitleLength = 120;

  final String id;
  final String centerId;
  final String groupId;
  final String title;
  final DateTime date;
  final double maxScore;
  final bool published;

  /// null قبل ما السيرفر يكتب الوقت (قراءة من الكاش بعد كتابة محلية).
  final DateTime? createdAt;
  final String createdBy;

  const Exam._({
    required this.id,
    required this.centerId,
    required this.groupId,
    required this.title,
    required this.date,
    required this.maxScore,
    required this.published,
    required this.createdBy,
    this.createdAt,
  });

  /// امتحان جديد (مسودة). بيرمي ArgumentError لو أي مدخل غلط.
  factory Exam.create({
    required String id,
    required String centerId,
    required String groupId,
    required String title,
    required DateTime date,
    required double maxScore,
    required String createdBy,
  }) {
    // بيرمي ArgumentError لو الـ id أو centerId أو groupId مش حروف وأرقام.
    FirestorePaths.exam(centerId, id);
    FirestorePaths.group(centerId, groupId);
    final name = title.trim();
    if (name.isEmpty) {
      throw ArgumentError.value(title, 'title', 'مينفعش يكون فاضي');
    }
    if (name.length > maxTitleLength) {
      throw ArgumentError.value(
        title,
        'title',
        'أطول من $maxTitleLength حرف',
      );
    }
    _requireValidMax(maxScore);
    if (createdBy.isEmpty) {
      throw ArgumentError.value(createdBy, 'createdBy', 'مينفعش يكون فاضي');
    }
    return Exam._(
      id: id,
      centerId: centerId,
      groupId: groupId,
      title: name,
      date: date,
      maxScore: maxScore,
      published: false,
      createdBy: createdBy,
    );
  }

  /// قراءة مستند. [id] هو id المستند. بيرمي FormatException لو تالف.
  factory Exam.fromMap(String id, Map<String, dynamic> map) {
    final centerId = map['centerId'];
    final groupId = map['groupId'];
    final title = map['title'];
    final createdBy = map['createdBy'];
    if (centerId is! String ||
        groupId is! String ||
        title is! String ||
        createdBy is! String) {
      throw const FormatException(
        'امتحان ناقص centerId أو groupId أو title أو createdBy',
      );
    }
    final date = _toDate(map['date']);
    if (date == null) {
      throw const FormatException('امتحان من غير تاريخ');
    }
    final rawMax = map['maxScore'];
    if (rawMax is! num || !rawMax.isFinite || rawMax <= 0) {
      throw const FormatException('امتحان من غير درجة نهائية صالحة');
    }
    return Exam._(
      id: id,
      centerId: centerId,
      groupId: groupId,
      title: title,
      date: date,
      maxScore: rawMax.toDouble(),
      published: map['published'] == true,
      createdAt: _toDate(map['createdAt']),
      createdBy: createdBy,
    );
  }

  /// الـ map بتاع الإنشاء (create فقط). [createdAt] اختياري للاختبار؛
  /// الافتراضي serverTimestamp.
  Map<String, dynamic> toCreateMap({Object? createdAt}) {
    return <String, dynamic>{
      'centerId': centerId,
      'groupId': groupId,
      'title': title,
      'date': Timestamp.fromDate(date),
      'maxScore': maxScore,
      'published': published,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'createdBy': createdBy,
    };
  }

  /// الـ map بتاع النشر (update بحقل واحد).
  static Map<String, dynamic> toPublishMap() =>
      const <String, dynamic>{'published': true};

  /// الـ map بتاع إلغاء النشر (update بحقل واحد).
  static Map<String, dynamic> toUnpublishMap() =>
      const <String, dynamic>{'published': false};

  /// هل الدرجة [value] جوه نطاق الامتحان (من 0 لحد [maxScore])؟
  bool isScoreInRange(double value) => value >= 0 && value <= maxScore;

  static void _requireValidMax(double max) {
    if (!max.isFinite || max <= 0) {
      throw ArgumentError.value(max, 'maxScore', 'لازم يكون أكبر من صفر');
    }
  }

  static DateTime? _toDate(Object? raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }
}
