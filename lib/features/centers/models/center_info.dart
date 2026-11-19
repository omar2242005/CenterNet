import 'package:cloud_firestore/cloud_firestore.dart';

import 'center_member.dart';

/// مستند `centers/{centerId}`.
///
/// اسمه CenterInfo مش Center عشان مايتلخبطش مع widget الـ Center بتاع Flutter.
class CenterInfo {
  const CenterInfo({
    required this.id,
    required this.name,
    required this.year,
    this.lateAfterMinutes = defaultLateAfterMinutes,
  });

  /// نفس قيمة ScanValidator.defaultLateAfterMinutes (15 دقيقة).
  static const int defaultLateAfterMinutes = 15;

  /// حدود بتفرضها firestore.rules (validCenter).
  static const int maxLateAfterMinutes = 180;
  static const int nameMaxLength = 80;

  final String id;
  final String name;

  /// السنة الدراسية (مثلًا 2026).
  final int year;

  /// الحاضر لحد startAt + المدة دي، والمتأخر بعدها.
  final int lateAfterMinutes;

  factory CenterInfo.fromMap(String id, Map<String, dynamic> map) {
    final name = map['name'];
    if (name is! String) {
      throw const FormatException('مستند السنتر من غير name');
    }
    final year = map['year'];
    if (year is! num) {
      throw const FormatException('مستند السنتر من غير year');
    }
    final late = map['lateAfterMinutes'];
    return CenterInfo(
      id: id,
      name: name,
      year: year.toInt(),
      lateAfterMinutes: late is num ? late.toInt() : defaultLateAfterMinutes,
    );
  }

  /// map الإنشاء. الحقول لازم تطابق `validCenter` بالظبط (hasOnly).
  /// [createdAt] اختياري للاختبار؛ الافتراضي serverTimestamp.
  static Map<String, dynamic> toCreateMap({
    required String uid,
    required String name,
    required int year,
    int lateAfterMinutes = defaultLateAfterMinutes,
    Object? createdAt,
  }) {
    return <String, dynamic>{
      'name': name,
      'year': year,
      'createdBy': uid,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'lateAfterMinutes': lateAfterMinutes,
    };
  }

  /// map تعديل الإعدادات: الحقول التلاتة اللي الأدمن مسموح له يغيّرها بس
  /// (الـ Rules بتقبل affectedKeys من name و year و lateAfterMinutes فقط).
  static Map<String, dynamic> toSettingsMap({
    required String name,
    required int year,
    required int lateAfterMinutes,
  }) {
    return <String, dynamic>{
      'name': name,
      'year': year,
      'lateAfterMinutes': lateAfterMinutes,
    };
  }

  CenterInfo copyWith({String? name, int? year, int? lateAfterMinutes}) {
    return CenterInfo(
      id: id,
      name: name ?? this.name,
      year: year ?? this.year,
      lateAfterMinutes: lateAfterMinutes ?? this.lateAfterMinutes,
    );
  }
}

/// سنتر المستخدم + عضويته فيه (بيتحمّلوا مع بعض).
class CenterContext {
  const CenterContext({required this.center, required this.membership});

  final CenterInfo center;
  final CenterMember membership;
}
