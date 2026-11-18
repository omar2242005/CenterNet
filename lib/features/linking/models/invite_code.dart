import 'package:cloud_firestore/cloud_firestore.dart';

/// نوع الكود. القيمة المكتوبة في Firestore = [wire].
enum InviteKind {
  staff('staff'),
  student('student'),
  guardian('guardian');

  const InviteKind(this.wire);
  final String wire;

  static InviteKind parse(Object? raw) {
    for (final k in InviteKind.values) {
      if (k.wire == raw) return k;
    }
    throw FormatException('نوع كود غير معروف: $raw');
  }
}

/// دور الموظف في كود الموظف. مفيش admin هنا أبدًا (الـ Rules بترفضه).
enum StaffInviteRole {
  teacher('teacher'),
  assistant('assistant');

  const StaffInviteRole(this.wire);
  final String wire;

  static StaffInviteRole parse(Object? raw) {
    for (final r in StaffInviteRole.values) {
      if (r.wire == raw) return r;
    }
    throw FormatException('دور غير صالح في كود الموظف: $raw');
  }
}

/// حالة الكود حسب ساعة الجهاز. للعرض فقط، الـ Rules هي الحكم.
enum InviteCodeStatus { valid, used, expired }

/// مستند `inviteCodes/{code}`. الـ id هو الكود نفسه (8 رموز).
///
/// القواعد اللي الـ Rules معتمدة عليها وبيحافظ عليها الموديل:
/// * `usedBy` بيتكتب `null` صراحة عند الإنشاء (الـ Rules بتتحقق منه).
/// * الحقول الاختيارية الفاضية (role/name/studentId/relation) بتتشال من
///   الـ map بدل ما تتكتب null.
/// * `expiresAt` = وقت الجهاز + 7 أيام (الـ Rules بتسمح بـ 8 كحد أقصى).
/// * `createdAt` بيتكتب بـ serverTimestamp.
class InviteCode {
  /// مدة صلاحية الكود حسب الخطة. الـ Rules بتسمح بيوم زيادة، والعميل يلتزم بـ 7.
  static const Duration validity = Duration(days: 7);

  /// أقصى عدد أولياء أمور لكل طالب (قرار 10 في الملف الشامل).
  /// الموديل مش بيفرضه: الفرض في شاشة الربط.
  static const int maxGuardiansPerStudent = 4;

  final String id;
  final String centerId;
  final InviteKind kind;

  /// كود الموظف فقط.
  final StaffInviteRole? role;

  /// كود الموظف فقط: الاسم اللي اختاره الأدمن.
  final String? name;

  /// كود الطالب وولي الأمر فقط.
  final String? studentId;

  /// كود ولي الأمر فقط: صلة القرابة (أب، أم...).
  final String? relation;

  final DateTime expiresAt;

  /// uid المستخدم اللي استهلك الكود، أو null لو لسه.
  final String? usedBy;

  /// null قبل ما السيرفر يكتب الوقت (قراءة من الكاش بعد كتابة محلية).
  final DateTime? createdAt;

  final String createdBy;

  const InviteCode._({
    required this.id,
    required this.centerId,
    required this.kind,
    required this.expiresAt,
    required this.createdBy,
    this.role,
    this.name,
    this.studentId,
    this.relation,
    this.usedBy,
    this.createdAt,
  });

  /// كود موظف جديد.
  factory InviteCode.staff({
    required String id,
    required String centerId,
    required String createdBy,
    required StaffInviteRole role,
    required String name,
    required DateTime now,
  }) {
    _requireNonEmpty('id', id);
    _requireNonEmpty('centerId', centerId);
    _requireNonEmpty('createdBy', createdBy);
    final trimmed = name.trim();
    _requireNonEmpty('name', trimmed);
    return InviteCode._(
      id: id,
      centerId: centerId,
      kind: InviteKind.staff,
      role: role,
      name: trimmed,
      expiresAt: now.add(validity),
      createdBy: createdBy,
    );
  }

  /// كود ربط حساب الطالب بسجله.
  factory InviteCode.student({
    required String id,
    required String centerId,
    required String createdBy,
    required String studentId,
    required DateTime now,
  }) {
    _requireNonEmpty('id', id);
    _requireNonEmpty('centerId', centerId);
    _requireNonEmpty('createdBy', createdBy);
    _requireNonEmpty('studentId', studentId);
    return InviteCode._(
      id: id,
      centerId: centerId,
      kind: InviteKind.student,
      studentId: studentId,
      expiresAt: now.add(validity),
      createdBy: createdBy,
    );
  }

  /// كود ربط ولي أمر بالطالب (مع صلة القرابة).
  factory InviteCode.guardian({
    required String id,
    required String centerId,
    required String createdBy,
    required String studentId,
    required String relation,
    required DateTime now,
  }) {
    _requireNonEmpty('id', id);
    _requireNonEmpty('centerId', centerId);
    _requireNonEmpty('createdBy', createdBy);
    _requireNonEmpty('studentId', studentId);
    final trimmed = relation.trim();
    _requireNonEmpty('relation', trimmed);
    return InviteCode._(
      id: id,
      centerId: centerId,
      kind: InviteKind.guardian,
      studentId: studentId,
      relation: trimmed,
      expiresAt: now.add(validity),
      createdBy: createdBy,
    );
  }

  /// قراءة مستند. [id] هو id المستند (الكود).
  factory InviteCode.fromMap(String id, Map<String, dynamic> map) {
    final kind = InviteKind.parse(map['kind']);
    final centerId = map['centerId'];
    final createdBy = map['createdBy'];
    if (centerId is! String || createdBy is! String) {
      throw const FormatException('كود دعوة ناقص centerId أو createdBy');
    }
    final expires = _toDate(map['expiresAt']);
    if (expires == null) {
      throw const FormatException('كود دعوة من غير expiresAt');
    }
    final usedBy = map['usedBy'];
    return InviteCode._(
      id: id,
      centerId: centerId,
      kind: kind,
      role: kind == InviteKind.staff ? StaffInviteRole.parse(map['role']) : null,
      name: map['name'] as String?,
      studentId: map['studentId'] as String?,
      relation: map['relation'] as String?,
      expiresAt: expires,
      usedBy: usedBy is String ? usedBy : null,
      createdAt: _toDate(map['createdAt']),
      createdBy: createdBy,
    );
  }

  /// الـ map بتاع الإنشاء (create).
  ///
  /// [createdAt] اختياري للاختبار؛ الافتراضي serverTimestamp.
  Map<String, dynamic> toCreateMap({Object? createdAt}) {
    return <String, dynamic>{
      'centerId': centerId,
      'kind': kind.wire,
      if (role != null) 'role': role!.wire,
      if (name != null) 'name': name,
      if (studentId != null) 'studentId': studentId,
      if (relation != null) 'relation': relation,
      'expiresAt': Timestamp.fromDate(expiresAt),
      // لازم يفضل null صريح: الـ Rules بتتحقق من usedBy == null.
      'usedBy': null,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'createdBy': createdBy,
    };
  }

  bool get isUsed => usedBy != null;

  bool isExpired(DateTime now) => !expiresAt.isAfter(now);

  InviteCodeStatus statusAt(DateTime now) {
    if (isUsed) return InviteCodeStatus.used;
    if (isExpired(now)) return InviteCodeStatus.expired;
    return InviteCodeStatus.valid;
  }

  static void _requireNonEmpty(String field, String value) {
    if (value.isEmpty) {
      throw ArgumentError.value(value, field, 'مينفعش يكون فاضي');
    }
  }

  static DateTime? _toDate(Object? raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }
}
