import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore_paths.dart';
import 'student_link.dart';

/// حالة طلب الربط. الأدمن بيغيّرها من pending لـ approved أو rejected.
enum LinkRequestStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected');

  const LinkRequestStatus(this.wire);
  final String wire;

  static LinkRequestStatus parse(Object? raw) {
    for (final s in LinkRequestStatus.values) {
      if (s.wire == raw) return s;
    }
    throw FormatException('حالة طلب غير معروفة: $raw');
  }
}

/// مستند `centers/{c}/linkRequests/{uid_studentNo}`.
/// الطالب/ولي الأمر بيطلب الربط برقم الطالب، والأدمن بيوافق فيكتب [code]
/// (كود ربط عادي) والطالب بيكمّل بيه الربط.
class LinkRequest {
  final String id;
  final String centerId;
  final String uid;

  /// اسم صاحب الطلب (عشان الأدمن يعرفه).
  final String name;
  final int studentNo;
  final LinkKind kind;

  /// صلة القرابة: ولي الأمر فقط.
  final String? relation;
  final LinkRequestStatus status;

  /// كود الربط بعد موافقة الأدمن.
  final String? code;

  const LinkRequest({
    required this.id,
    required this.centerId,
    required this.uid,
    required this.name,
    required this.studentNo,
    required this.kind,
    required this.status,
    this.relation,
    this.code,
  });

  factory LinkRequest.fromMap(String id, Map<String, dynamic> map) {
    final centerId = map['centerId'];
    final uid = map['uid'];
    final name = map['name'];
    final studentNo = map['studentNo'];
    if (centerId is! String ||
        uid is! String ||
        name is! String ||
        studentNo is! int) {
      throw const FormatException('طلب ربط ناقص');
    }
    final relation = map['relation'];
    final code = map['code'];
    return LinkRequest(
      id: id,
      centerId: centerId,
      uid: uid,
      name: name,
      studentNo: studentNo,
      kind: LinkKind.parse(map['kind']),
      status: LinkRequestStatus.parse(map['status']),
      relation: relation is String ? relation : null,
      code: code is String ? code : null,
    );
  }

  /// الـ map بتاع الإنشاء (status = pending دايمًا).
  static Map<String, dynamic> toCreateMap({
    required String centerId,
    required String uid,
    required String name,
    required int studentNo,
    required LinkKind kind,
    String? relation,
  }) {
    return <String, dynamic>{
      'centerId': centerId,
      'uid': uid,
      'name': name,
      'studentNo': studentNo,
      'kind': kind.wire,
      'relation': ?relation,
      'status': LinkRequestStatus.pending.wire,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static String idFor(String uid, int studentNo) =>
      FirestoreIds.linkRequest(uid, studentNo);
}
