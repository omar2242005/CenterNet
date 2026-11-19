import 'package:cloud_firestore/cloud_firestore.dart';

/// دور العضو جوه السنتر. القيمة المكتوبة في Firestore هي [wire].
/// (كود الدعوة بيدعم teacher و assistant بس؛ الأدمن هو منشئ السنتر فقط.)
enum MemberRole {
  admin('admin'),
  teacher('teacher'),
  assistant('assistant');

  const MemberRole(this.wire);

  final String wire;

  static MemberRole parse(Object? raw) {
    for (final r in MemberRole.values) {
      if (r.wire == raw) return r;
    }
    throw FormatException('دور عضو غير معروف: $raw');
  }
}

/// مستند `centers/{c}/members/{uid}`: الصلاحيات كلها بتيجي من هنا
/// (مش من `users.accountType` ولا `users.centerId`).
class CenterMember {
  const CenterMember({
    required this.uid,
    required this.role,
    required this.name,
    required this.active,
  });

  final String uid;
  final MemberRole role;
  final String name;
  final bool active;

  /// أدمن ونشط. الموظف المعطّل (active=false) مالوش صلاحيات.
  bool get isAdmin => role == MemberRole.admin && active;

  factory CenterMember.fromMap(String uid, Map<String, dynamic> map) {
    final name = map['name'];
    final active = map['active'];
    if (name is! String) {
      throw const FormatException('مستند العضو من غير name');
    }
    if (active is! bool) {
      throw const FormatException('مستند العضو من غير active');
    }
    return CenterMember(
      uid: uid,
      role: MemberRole.parse(map['role']),
      name: name,
      active: active,
    );
  }

  /// عضوية منشئ السنتر (أدمن). شكلها لازم يطابق `validMember` و
  /// `bootstrapsCenter` في firestore.rules.
  /// [createdAt] اختياري للاختبار؛ الافتراضي serverTimestamp.
  static Map<String, dynamic> toAdminCreateMap({
    required String uid,
    required String name,
    Object? createdAt,
  }) {
    return <String, dynamic>{
      'role': MemberRole.admin.wire,
      'name': name.trim(),
      'active': true,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'createdBy': uid,
    };
  }
}
