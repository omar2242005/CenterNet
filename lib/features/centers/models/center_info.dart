import 'package:cloud_firestore/cloud_firestore.dart';

/// مستند `centers/{centerId}`. اسمه CenterInfo عشان ميتلخبطش مع widget الـ Center.
class CenterInfo {
  const CenterInfo({
    required this.id,
    required this.name,
    required this.year,
    required this.createdBy,
    required this.lateAfterMinutes,
  });

  /// مدة التأخير الافتراضية (دقيقة) حسب الملف الشامل.
  static const int defaultLateAfterMinutes = 15;

  /// الحدود اللي الـ Rules بتفرضها على lateAfterMinutes.
  static const int maxLateAfterMinutes = 180;
  static const int maxNameLength = 80;

  final String id;
  final String name;
  final int year;
  final String createdBy;
  final int lateAfterMinutes;

  factory CenterInfo.fromMap(String id, Map<String, dynamic> map) {
    final name = map['name'];
    final year = map['year'];
    final createdBy = map['createdBy'];
    if (name is! String || createdBy is! String) {
      throw const FormatException('مستند سنتر ناقص name أو createdBy');
    }
    final late = map['lateAfterMinutes'];
    return CenterInfo(
      id: id,
      name: name,
      year: year is int ? year : DateTime.now().year,
      createdBy: createdBy,
      lateAfterMinutes: late is int ? late : defaultLateAfterMinutes,
    );
  }

  /// الـ map بتاع الإنشاء. الحقول مطابقة لـ validCenter في الـ Rules.
  static Map<String, dynamic> toCreateMap({
    required String name,
    required int year,
    required String createdBy,
    Object? createdAt,
  }) {
    return <String, dynamic>{
      'name': name.trim(),
      'year': year,
      'createdBy': createdBy,
      'lateAfterMinutes': defaultLateAfterMinutes,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  /// الـ map بتاع تعديل الإعدادات (الحقول المسموح بتعديلها بس).
  static Map<String, dynamic> toSettingsMap({
    required String name,
    required int year,
    required int lateAfterMinutes,
  }) {
    return <String, dynamic>{
      'name': name.trim(),
      'year': year,
      'lateAfterMinutes': lateAfterMinutes,
    };
  }
}
