import '../../linking/models/invite_code.dart';

/// دور العضو جوه السنتر زي ما هو متخزن في `members/{uid}.role`.
///
/// الأدمن ظاهر هنا للعرض بس: مينفعش حد يتعيّن أدمن ولا يتعدّل دوره من
/// التطبيق (الـ Rules بترفض ده).
enum StaffMemberRole {
  admin('admin'),
  teacher('teacher'),
  assistant('assistant');

  const StaffMemberRole(this.wire);
  final String wire;

  static StaffMemberRole parse(Object? raw) {
    for (final r in StaffMemberRole.values) {
      if (r.wire == raw) return r;
    }
    throw FormatException('دور عضو غير معروف: $raw');
  }

  /// نفس الدور بس من نوع دور الدعوة (معلم / مساعد).
  static StaffMemberRole fromInvite(StaffInviteRole role) => switch (role) {
        StaffInviteRole.teacher => StaffMemberRole.teacher,
        StaffInviteRole.assistant => StaffMemberRole.assistant,
      };
}

/// مستند `centers/{c}/members/{uid}` للعرض في قائمة الموظفين.
class StaffMember {
  const StaffMember({
    required this.uid,
    required this.name,
    required this.role,
    required this.active,
  });

  final String uid;
  final String name;
  final StaffMemberRole role;
  final bool active;

  bool get isAdmin => role == StaffMemberRole.admin;

  /// الأدمن مش بيتعدّل من التطبيق.
  bool get editable => !isAdmin;

  factory StaffMember.fromMap(String uid, Map<String, dynamic> map) {
    final name = map['name'];
    final active = map['active'];
    if (name is! String || active is! bool) {
      throw const FormatException('مستند عضو ناقص name أو active');
    }
    return StaffMember(
      uid: uid,
      name: name,
      role: StaffMemberRole.parse(map['role']),
      active: active,
    );
  }

  StaffMember copyWith({StaffMemberRole? role, bool? active}) {
    return StaffMember(
      uid: uid,
      name: name,
      role: role ?? this.role,
      active: active ?? this.active,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is StaffMember &&
      other.uid == uid &&
      other.name == name &&
      other.role == role &&
      other.active == active;

  @override
  int get hashCode => Object.hash(uid, name, role, active);
}
