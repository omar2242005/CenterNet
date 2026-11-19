import 'digits.dart';

final RegExp _diacritics = RegExp('[\u064B-\u065F\u0670]');
final RegExp _tatweel = RegExp('\u0640');
final RegExp _alefVariants = RegExp('[\u0622\u0623\u0625\u0671]');
final RegExp _spaces = RegExp(r'\s+');

/// تطبيع النص العربي للبحث والمقارنة:
///
/// * أ / إ / آ / ٱ ← ا
/// * ة ← ه
/// * ى ← ي
/// * حذف التشكيل والتطويل
/// * أرقام هندية ← لاتينية
/// * مسافات متكررة ← مسافة واحدة، وحروف لاتينية صغيرة
///
/// "أحمد" و"احمد" و"َأَحْمَد" بيدوا نفس النتيجة.
String normalizeArabic(String input) {
  var s = toLatinDigits(input);
  s = s.replaceAll(_diacritics, '');
  s = s.replaceAll(_tatweel, '');
  s = s.replaceAll(_alefVariants, '\u0627');
  s = s.replaceAll('\u0629', '\u0647');
  s = s.replaceAll('\u0649', '\u064A');
  s = s.replaceAll(_spaces, ' ').trim();
  return s.toLowerCase();
}

/// قيمة حقل `searchKey` اللي بتتخزن مع الطالب (الاسم بعد التطبيع).
String buildSearchKey(String fullName) => normalizeArabic(fullName);

/// هل [query] موجود جوه [searchKey]؟ الاتنين بيتطبّعوا هنا،
/// فالـ caller يقدر يبعت النص الخام. الاستعلام الفاضي بيطابق كل حاجة.
bool matchesSearch(String searchKey, String query) {
  final q = normalizeArabic(query);
  if (q.isEmpty) return true;
  return normalizeArabic(searchKey).contains(q);
}
