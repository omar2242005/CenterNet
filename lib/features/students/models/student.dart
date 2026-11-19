import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore_paths.dart';

/// حالة الطالب. مفيش حذف: الأرشفة بدل الحذف.
enum StudentStatus {
  active('active'),
  archived('archived');

  const StudentStatus(this.wire);
  final String wire;

  static StudentStatus parse(Object? raw) {
    for (final s in StudentStatus.values) {
      if (s.wire == raw) return s;
    }
    throw FormatException('حالة طالب غير معروفة: $raw');
  }
}

/// مستند `centers/{c}/students/{sid}`.
///
/// * سجل الطالب مستقل عن حسابه وملك السنتر (قرار 1).
/// * الـ id بيتولد أوتوماتيك (حروف وأرقام بس) والـ [studentNo] رقم تسلسلي
///   بيتحجز في Transaction في الـ Repository (خطوة 3.1) عشان مفيش تكرار.
/// * [searchKey] = الاسم بعد التطبيع العربي. الموديل مش بيطبّع بنفسه: الـ
///   Repository بيمرر الناتج من utils بتاعة D (عشان التطبيع في مكان واحد).
/// * [groupIds] هي طريقة تسجيل الطالب في المجموعات (array-contains).
class Student {
  final String id;
  final String centerId;
  final int studentNo;
  final String fullName;
  final String searchKey;
  final String phone;
  final String grade;
  final List<String> groupIds;
  final StudentStatus status;

  /// null قبل ما السيرفر يكتب الوقت (قراءة من الكاش بعد كتابة محلية).
  final DateTime? createdAt;
  final String createdBy;

  const Student._({
    required this.id,
    required this.centerId,
    required this.studentNo,
    required this.fullName,
    required this.searchKey,
    required this.phone,
    required this.grade,
    required this.groupIds,
    required this.status,
    required this.createdBy,
    this.createdAt,
  });

  /// طالب جديد (active). التحقق من صيغة الموبايل في الـ utils/الشاشة، مش هنا.
  factory Student.create({
    required String id,
    required String centerId,
    required int studentNo,
    required String fullName,
    required String searchKey,
    required String phone,
    required String grade,
    required String createdBy,
    List<String> groupIds = const [],
  }) {
    // بيرمي ArgumentError لو الـ id أو centerId مش حروف وأرقام.
    FirestorePaths.student(centerId, id);
    if (studentNo < 1) {
      throw ArgumentError.value(studentNo, 'studentNo', 'لازم يبدأ من 1');
    }
    final name = fullName.trim();
    _requireNonEmpty('fullName', name);
    _requireNonEmpty('searchKey', searchKey);
    _requireNonEmpty('createdBy', createdBy);
    return Student._(
      id: id,
      centerId: centerId,
      studentNo: studentNo,
      fullName: name,
      searchKey: searchKey,
      phone: phone.trim(),
      grade: grade.trim(),
      groupIds: _cleanIds(groupIds),
      status: StudentStatus.active,
      createdBy: createdBy,
    );
  }

  /// قراءة مستند. [id] هو id المستند.
  factory Student.fromMap(String id, Map<String, dynamic> map) {
    final centerId = map['centerId'];
    final fullName = map['fullName'];
    final searchKey = map['searchKey'];
    final createdBy = map['createdBy'];
    final studentNo = map['studentNo'];
    if (centerId is! String ||
        fullName is! String ||
        searchKey is! String ||
        createdBy is! String) {
      throw const FormatException(
        'طالب ناقص centerId أو fullName أو searchKey أو createdBy',
      );
    }
    if (studentNo is! int) {
      throw const FormatException('طالب من غير studentNo');
    }
    final rawGroups = map['groupIds'];
    return Student._(
      id: id,
      centerId: centerId,
      studentNo: studentNo,
      fullName: fullName,
      searchKey: searchKey,
      phone: (map['phone'] as String?) ?? '',
      grade: (map['grade'] as String?) ?? '',
      groupIds: rawGroups is List ? rawGroups.whereType<String>().toList() : [],
      status: StudentStatus.parse(map['status']),
      createdAt: _toDate(map['createdAt']),
      createdBy: createdBy,
    );
  }

  /// الـ map بتاع الإنشاء. [createdAt] اختياري للاختبار؛ الافتراضي
  /// serverTimestamp.
  Map<String, dynamic> toCreateMap({Object? createdAt}) {
    return <String, dynamic>{
      'centerId': centerId,
      'studentNo': studentNo,
      'fullName': fullName,
      'searchKey': searchKey,
      'phone': phone,
      'grade': grade,
      'groupIds': groupIds,
      'status': status.wire,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'createdBy': createdBy,
    };
  }

  /// الـ map بتاع تعديل بيانات الطالب (update). مش بيلمس studentNo ولا
  /// centerId ولا status ولا createdBy/createdAt.
  static Map<String, dynamic> toUpdateMap({
    required String fullName,
    required String searchKey,
    required String phone,
    required String grade,
    required List<String> groupIds,
  }) {
    final name = fullName.trim();
    _requireNonEmpty('fullName', name);
    _requireNonEmpty('searchKey', searchKey);
    return <String, dynamic>{
      'fullName': name,
      'searchKey': searchKey,
      'phone': phone.trim(),
      'grade': grade.trim(),
      'groupIds': _cleanIds(groupIds),
    };
  }

  /// الـ map بتاع الأرشفة (بدل الحذف).
  static Map<String, dynamic> toArchiveMap() =>
      <String, dynamic>{'status': StudentStatus.archived.wire};

  /// الـ map بتاع الاسترجاع من الأرشيف.
  static Map<String, dynamic> toRestoreMap() =>
      <String, dynamic>{'status': StudentStatus.active.wire};

  bool get isArchived => status == StudentStatus.archived;

  bool isInGroup(String groupId) => groupIds.contains(groupId);

  /// نسخة بمجموعات متغيرة (للعرض/الاختبار؛ الكتابة بتتم بـ [toUpdateMap]).
  Student withGroupIds(List<String> ids) => Student._(
        id: id,
        centerId: centerId,
        studentNo: studentNo,
        fullName: fullName,
        searchKey: searchKey,
        phone: phone,
        grade: grade,
        groupIds: _cleanIds(ids),
        status: status,
        createdBy: createdBy,
        createdAt: createdAt,
      );

  static List<String> _cleanIds(List<String> ids) {
    final seen = <String>{};
    for (final id in ids) {
      _requireNonEmpty('groupIds', id);
      seen.add(id);
    }
    return List<String>.unmodifiable(seen);
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
