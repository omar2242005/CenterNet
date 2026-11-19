import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore_paths.dart';

/// حالة المجموعة. الأرشفة بدل الحذف.
enum GroupStatus {
  active('active'),
  archived('archived');

  const GroupStatus(this.wire);
  final String wire;

  static GroupStatus parse(Object? raw) {
    for (final s in GroupStatus.values) {
      if (s.wire == raw) return s;
    }
    throw FormatException('حالة مجموعة غير معروفة: $raw');
  }
}

/// ميعاد أسبوعي ثابت للمجموعة.
///
/// * [weekday] زي `DateTime.weekday`: 1 = الاثنين ... 7 = الأحد.
/// * [startMinutes] دقائق من منتصف الليل بتوقيت القاهرة (17:00 = 1020).
///   بنخزن دقائق مش Timestamp عشان الميعاد الأسبوعي مالوش تاريخ معين،
///   ومولّد الجلسات (خطوة 3.4) هو اللي بيحوله لوقت حائط بالقاهرة.
class GroupSlot {
  static const int minDurationMinutes = 1;
  static const int maxDurationMinutes = 480;

  final int weekday;
  final int startMinutes;
  final int durationMinutes;

  GroupSlot({
    required this.weekday,
    required this.startMinutes,
    required this.durationMinutes,
  }) {
    if (weekday < DateTime.monday || weekday > DateTime.sunday) {
      throw ArgumentError.value(weekday, 'weekday', 'اليوم من 1 لـ 7');
    }
    if (startMinutes < 0 || startMinutes > 1439) {
      throw ArgumentError.value(
        startMinutes,
        'startMinutes',
        'الوقت من 0 لـ 1439 دقيقة',
      );
    }
    if (durationMinutes < minDurationMinutes ||
        durationMinutes > maxDurationMinutes) {
      throw ArgumentError.value(
        durationMinutes,
        'durationMinutes',
        'مدة الحصة من $minDurationMinutes لـ $maxDurationMinutes دقيقة',
      );
    }
  }

  factory GroupSlot.fromMap(Map<String, dynamic> map) {
    final w = map['weekday'];
    final s = map['startMinutes'];
    final d = map['durationMinutes'];
    if (w is! int || s is! int || d is! int) {
      throw const FormatException('ميعاد ناقص weekday أو startMinutes أو المدة');
    }
    try {
      return GroupSlot(weekday: w, startMinutes: s, durationMinutes: d);
    } on ArgumentError catch (e) {
      throw FormatException('ميعاد غير صالح: ${e.message}');
    }
  }

  int get startHour => startMinutes ~/ 60;
  int get startMinute => startMinutes % 60;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'weekday': weekday,
        'startMinutes': startMinutes,
        'durationMinutes': durationMinutes,
      };

  @override
  bool operator ==(Object other) =>
      other is GroupSlot &&
      other.weekday == weekday &&
      other.startMinutes == startMinutes &&
      other.durationMinutes == durationMinutes;

  @override
  int get hashCode => Object.hash(weekday, startMinutes, durationMinutes);
}

/// مستند `centers/{c}/groups/{gid}`.
///
/// * [teacherId] و[assistantIds] هما أساس صلاحيات الحضور (قرار "مجموعات
///   المساعد"): B بيتحقق منهم في الـ Rules عن طريق الجلسة ← المجموعة.
/// * [room] نص حر (مفيش feature للقاعات في P0). [capacity] اختيارية.
/// * [monthlyFee] بالقروش (450 ج.م = 45000).
class Group {
  final String id;
  final String centerId;
  final String name;
  final String subject;
  final String grade;
  final String teacherId;
  final List<String> assistantIds;
  final String room;
  final int? capacity;
  final int monthlyFee;
  final List<GroupSlot> slots;
  final GroupStatus status;

  /// null قبل ما السيرفر يكتب الوقت (قراءة من الكاش بعد كتابة محلية).
  final DateTime? createdAt;
  final String createdBy;

  const Group._({
    required this.id,
    required this.centerId,
    required this.name,
    required this.subject,
    required this.grade,
    required this.teacherId,
    required this.assistantIds,
    required this.room,
    required this.capacity,
    required this.monthlyFee,
    required this.slots,
    required this.status,
    required this.createdBy,
    this.createdAt,
  });

  /// مجموعة جديدة (active). الـ id بيتولد أوتوماتيك (حروف وأرقام بس).
  factory Group.create({
    required String id,
    required String centerId,
    required String name,
    required String subject,
    required String grade,
    required String teacherId,
    required String createdBy,
    List<String> assistantIds = const [],
    String room = '',
    int? capacity,
    int monthlyFee = 0,
    List<GroupSlot> slots = const [],
  }) {
    // بيرمي ArgumentError لو الـ id أو centerId مش حروف وأرقام.
    FirestorePaths.group(centerId, id);
    final trimmedName = name.trim();
    _requireNonEmpty('name', trimmedName);
    _requireNonEmpty('teacherId', teacherId);
    _requireNonEmpty('createdBy', createdBy);
    _checkMoney(monthlyFee);
    _checkCapacity(capacity);
    return Group._(
      id: id,
      centerId: centerId,
      name: trimmedName,
      subject: subject.trim(),
      grade: grade.trim(),
      teacherId: teacherId,
      assistantIds: _cleanAssistants(assistantIds, teacherId),
      room: room.trim(),
      capacity: capacity,
      monthlyFee: monthlyFee,
      slots: List<GroupSlot>.unmodifiable(slots),
      status: GroupStatus.active,
      createdBy: createdBy,
    );
  }

  /// قراءة مستند. [id] هو id المستند.
  factory Group.fromMap(String id, Map<String, dynamic> map) {
    final centerId = map['centerId'];
    final name = map['name'];
    final teacherId = map['teacherId'];
    final createdBy = map['createdBy'];
    if (centerId is! String ||
        name is! String ||
        teacherId is! String ||
        createdBy is! String) {
      throw const FormatException(
        'مجموعة ناقصة centerId أو name أو teacherId أو createdBy',
      );
    }
    final rawAssistants = map['assistantIds'];
    final rawSlots = map['slots'];
    final fee = map['monthlyFee'];
    final cap = map['capacity'];
    return Group._(
      id: id,
      centerId: centerId,
      name: name,
      subject: (map['subject'] as String?) ?? '',
      grade: (map['grade'] as String?) ?? '',
      teacherId: teacherId,
      // مستندات قديمة من غير الحقل = مفيش مساعدين.
      assistantIds: rawAssistants is List
          ? List<String>.unmodifiable(rawAssistants.whereType<String>())
          : const <String>[],
      room: (map['room'] as String?) ?? '',
      capacity: cap is int ? cap : null,
      monthlyFee: fee is int ? fee : 0,
      slots: rawSlots is List
          ? List<GroupSlot>.unmodifiable(
              rawSlots.whereType<Map>().map(
                    (m) => GroupSlot.fromMap(Map<String, dynamic>.from(m)),
                  ),
            )
          : const <GroupSlot>[],
      status: GroupStatus.parse(map['status']),
      createdAt: _toDate(map['createdAt']),
      createdBy: createdBy,
    );
  }

  /// الـ map بتاع الإنشاء. [createdAt] اختياري للاختبار؛ الافتراضي
  /// serverTimestamp. `capacity` بتتشال من الـ map لو null.
  Map<String, dynamic> toCreateMap({Object? createdAt}) {
    return <String, dynamic>{
      'centerId': centerId,
      'name': name,
      'subject': subject,
      'grade': grade,
      'teacherId': teacherId,
      'assistantIds': assistantIds,
      'room': room,
      if (capacity != null) 'capacity': capacity,
      'monthlyFee': monthlyFee,
      'slots': slots.map((s) => s.toMap()).toList(),
      'status': status.wire,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'createdBy': createdBy,
    };
  }

  /// الـ map بتاع تعديل المجموعة (update). مش بيلمس centerId/status/created*.
  /// [capacity] = null بيمسح السعة (FieldValue.delete).
  static Map<String, dynamic> toUpdateMap({
    required String name,
    required String subject,
    required String grade,
    required String teacherId,
    required List<String> assistantIds,
    required String room,
    required int? capacity,
    required int monthlyFee,
    required List<GroupSlot> slots,
  }) {
    final trimmedName = name.trim();
    _requireNonEmpty('name', trimmedName);
    _requireNonEmpty('teacherId', teacherId);
    _checkMoney(monthlyFee);
    _checkCapacity(capacity);
    return <String, dynamic>{
      'name': trimmedName,
      'subject': subject.trim(),
      'grade': grade.trim(),
      'teacherId': teacherId,
      'assistantIds': _cleanAssistants(assistantIds, teacherId),
      'room': room.trim(),
      'capacity': capacity ?? FieldValue.delete(),
      'monthlyFee': monthlyFee,
      'slots': slots.map((s) => s.toMap()).toList(),
    };
  }

  /// الـ map بتاع الأرشفة (بدل الحذف).
  static Map<String, dynamic> toArchiveMap() =>
      <String, dynamic>{'status': GroupStatus.archived.wire};

  bool get isArchived => status == GroupStatus.archived;

  /// المعلم أو أي مساعد في المجموعة؟ (نفس منطق الـ Rules بتاعة الحضور، للعرض
  /// بس؛ الـ Rules هي الحكم).
  bool isStaffedBy(String uid) =>
      uid == teacherId || assistantIds.contains(uid);

  /// السعة مليانة؟ [enrolled] = عدد الطلاب الحاليين. بدون سعة = أبدًا.
  /// تحذير بسيط بس، مش منع (خطة 3.3).
  bool isFull(int enrolled) => capacity != null && enrolled >= capacity!;

  static List<String> _cleanAssistants(List<String> ids, String teacherId) {
    final seen = <String>{};
    for (final id in ids) {
      _requireNonEmpty('assistantIds', id);
      if (id == teacherId) {
        throw ArgumentError.value(
          id,
          'assistantIds',
          'المعلم مينفعش يبقى مساعد في نفس المجموعة',
        );
      }
      seen.add(id);
    }
    return List<String>.unmodifiable(seen);
  }

  static void _checkMoney(int monthlyFee) {
    if (monthlyFee < 0) {
      throw ArgumentError.value(
        monthlyFee,
        'monthlyFee',
        'السعر بالقروش ومينفعش يبقى سالب',
      );
    }
  }

  static void _checkCapacity(int? capacity) {
    if (capacity != null && capacity < 1) {
      throw ArgumentError.value(capacity, 'capacity', 'السعة لازم 1 أو أكتر');
    }
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
