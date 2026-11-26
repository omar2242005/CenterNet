import 'package:cloud_firestore/cloud_firestore.dart';

import 'account_type.dart';

/// مستند `users/{uid}`: للتوجيه في الشاشات فقط، مفيش صلاحية بتيجي منه.
/// كلمة السر مبتتخزنش هنا أبدًا (Firebase Auth بس).
class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.accountType,
    this.centerId,
  });

  final String uid;
  final String name;
  final String email;
  final String phone;
  final AccountType accountType;

  /// null لحد ما يتنشئ سنتر أو يتقبل كود (خطوة 2.2 / 2.3).
  final String? centerId;

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    final name = map['name'];
    if (name is! String) {
      throw const FormatException('مستند المستخدم من غير name');
    }
    final centerId = map['centerId'];
    return AppUser(
      uid: uid,
      name: name,
      email: (map['email'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      accountType: AccountType.parse(map['accountType']),
      centerId: centerId is String ? centerId : null,
    );
  }

  /// الـ map بتاع الإنشاء. الـ Rules بترفض centerId وقت الإنشاء، فمش بيتكتب هنا.
  /// [createdAt] اختياري للاختبار؛ الافتراضي serverTimestamp.
  static Map<String, dynamic> toCreateMap({
    required String uid,
    required String name,
    required String email,
    required String phone,
    required AccountType accountType,
    Object? createdAt,
  }) {
    return <String, dynamic>{
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone,
      'accountType': accountType.wire,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'createdBy': uid,
    };
  }
}
