import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore_paths.dart';

/// نوع الربط: حساب الطالب نفسه، أو حساب ولي أمر.
enum LinkKind {
  student('student'),
  guardian('guardian');

  const LinkKind(this.wire);
  final String wire;

  static LinkKind parse(Object? raw) {
    for (final k in LinkKind.values) {
      if (k.wire == raw) return k;
    }
    throw FormatException('نوع ربط غير معروف: $raw');
  }
}

/// حالة الربط. فك الربط = `unlinked` (مفيش حذف).
enum LinkStatus {
  active('active'),
  unlinked('unlinked');

  const LinkStatus(this.wire);
  final String wire;

  static LinkStatus parse(Object? raw) {
    for (final s in LinkStatus.values) {
      if (s.wire == raw) return s;
    }
    throw FormatException('حالة ربط غير معروفة: $raw');
  }
}

/// مستند `centers/{c}/studentLinks/{uid_sid}` (تحت السنتر مش على الجذر).
///
/// ده اللي الـ Rules بتقرا منه صلاحية الطالب/ولي الأمر (`isLinked`)، مش
/// `users.centerId` ولا `accountType`. الـ id حتمي من
/// [FirestoreIds.studentLink] فنفس الحساب مايتربطش بنفس الطالب مرتين.
///
/// الحد الأقصى لأولياء الأمر (4 للطالب) بتفرضه شاشة الربط، مش الموديل.
class StudentLink {
  final String id;
  final String centerId;
  final String uid;
  final String studentId;
  final LinkKind kind;
  final LinkStatus status;

  /// صلة القرابة: ولي الأمر فقط.
  final String? relation;

  /// null قبل ما السيرفر يكتب الوقت (قراءة من الكاش بعد كتابة محلية).
  final DateTime? createdAt;

  /// المستخدم اللي نفّذ الربط (هو صاحب الحساب وقت قبول الكود).
  final String createdBy;

  const StudentLink._({
    required this.id,
    required this.centerId,
    required this.uid,
    required this.studentId,
    required this.kind,
    required this.status,
    required this.createdBy,
    this.relation,
    this.createdAt,
  });

  /// ربط جديد (active). [relation] إلزامي لولي الأمر ومرفوض للطالب.
  factory StudentLink.create({
    required String centerId,
    required String uid,
    required String studentId,
    required LinkKind kind,
    String? relation,
  }) {
    // بيرمي ArgumentError لو أي جزء مش حروف وأرقام.
    FirestorePaths.studentLink(centerId, uid, studentId);
    final rel = relation?.trim();
    if (kind == LinkKind.guardian && (rel == null || rel.isEmpty)) {
      throw ArgumentError.value(relation, 'relation', 'صلة القرابة مطلوبة');
    }
    if (kind == LinkKind.student && rel != null && rel.isNotEmpty) {
      throw ArgumentError.value(
        relation,
        'relation',
        'صلة القرابة لولي الأمر بس',
      );
    }
    return StudentLink._(
      id: FirestoreIds.studentLink(uid, studentId),
      centerId: centerId,
      uid: uid,
      studentId: studentId,
      kind: kind,
      status: LinkStatus.active,
      relation: kind == LinkKind.guardian ? rel : null,
      createdBy: uid,
    );
  }

  /// قراءة مستند. [id] هو id المستند.
  factory StudentLink.fromMap(String id, Map<String, dynamic> map) {
    final centerId = map['centerId'];
    final uid = map['uid'];
    final studentId = map['studentId'];
    final createdBy = map['createdBy'];
    if (centerId is! String ||
        uid is! String ||
        studentId is! String ||
        createdBy is! String) {
      throw const FormatException(
        'ربط ناقص centerId أو uid أو studentId أو createdBy',
      );
    }
    final relation = map['relation'];
    return StudentLink._(
      id: id,
      centerId: centerId,
      uid: uid,
      studentId: studentId,
      kind: LinkKind.parse(map['kind']),
      status: LinkStatus.parse(map['status']),
      relation: relation is String ? relation : null,
      createdAt: _toDate(map['createdAt']),
      createdBy: createdBy,
    );
  }

  /// الـ map بتاع الإنشاء. `relation` بتتشال من الـ map لو null.
  /// [createdAt] اختياري للاختبار؛ الافتراضي serverTimestamp.
  Map<String, dynamic> toCreateMap({Object? createdAt}) {
    return <String, dynamic>{
      'centerId': centerId,
      'uid': uid,
      'studentId': studentId,
      'kind': kind.wire,
      'status': status.wire,
      if (relation != null) 'relation': relation,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'createdBy': createdBy,
    };
  }

  /// الـ map بتاع فك الربط (update لحقل الحالة بس).
  static Map<String, dynamic> toUnlinkMap() =>
      <String, dynamic>{'status': LinkStatus.unlinked.wire};

  bool get isActive => status == LinkStatus.active;

  static DateTime? _toDate(Object? raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }
}
