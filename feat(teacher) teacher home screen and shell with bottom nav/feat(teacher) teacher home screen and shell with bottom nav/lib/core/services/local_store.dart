import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// غلاف رفيع على shared_preferences. B بيبني عليه قائمة المسحات المحلية.
///
/// القراءة متزامنة (الـ prefs محمّلة في الذاكرة)، والكتابة async.
/// [getJson] بيرمي FormatException لو المحتوى باظ: مفيش فشل صامت، والمتصل
/// هو اللي يقرر يعمل إيه (مثلًا يعرض خطأ بدل ما يفتكر إن القائمة فاضية).
class LocalStore {
  LocalStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<LocalStore> open() async =>
      LocalStore(await SharedPreferences.getInstance());

  bool containsKey(String key) => _prefs.containsKey(key);

  String? getString(String key) => _prefs.getString(key);

  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  /// بيرجّع null لو المفتاح مش موجود.
  Object? getJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    return jsonDecode(raw);
  }

  /// [value] لازم يكون قابل لـ jsonEncode (Map/List/نص/رقم/bool).
  Future<void> setJson(String key, Object value) =>
      _prefs.setString(key, jsonEncode(value));

  Future<void> remove(String key) => _prefs.remove(key);
}
