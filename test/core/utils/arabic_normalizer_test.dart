import 'package:center_net/core/utils/arabic_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeArabic', () {
    test('"أحمد" و"احمد" و"َأحْمَد" بيدوا نفس النتيجة', () {
      final a = normalizeArabic('أحمد');
      expect(normalizeArabic('احمد'), a);
      expect(normalizeArabic('\u064Eأحْمَد'), a);
      expect(normalizeArabic('إحمد'), a);
      expect(normalizeArabic('آحمد'), a);
      expect(a, 'احمد');
    });

    test('ة ← ه و ى ← ي', () {
      expect(normalizeArabic('فاطمة'), 'فاطمه');
      expect(normalizeArabic('مصطفى'), 'مصطفي');
    });

    test('حذف التشكيل والتطويل', () {
      expect(normalizeArabic('مُحَمَّد'), 'محمد');
      expect(normalizeArabic('محـــمد'), 'محمد');
    });

    test('أرقام هندية ← لاتينية، ومسافات متكررة، وحروف لاتينية صغيرة', () {
      expect(normalizeArabic('  أحمد   ٢٠٢٦  '), 'احمد 2026');
      expect(normalizeArabic('Ahmed ALI'), 'ahmed ali');
    });

    test('نص فاضي', () {
      expect(normalizeArabic(''), '');
      expect(normalizeArabic('   '), '');
    });
  });

  group('matchesSearch', () {
    test('بحث "احمد" يلاقي "أحمد"', () {
      expect(matchesSearch(buildSearchKey('أحمد علي'), 'احمد'), isTrue);
      expect(matchesSearch(buildSearchKey('أحمد علي'), 'علي'), isTrue);
    });

    test('مفيش تطابق', () {
      expect(matchesSearch(buildSearchKey('أحمد علي'), 'سارة'), isFalse);
    });

    test('استعلام فاضي بيطابق كل حاجة', () {
      expect(matchesSearch('احمد', ''), isTrue);
      expect(matchesSearch('احمد', '   '), isTrue);
    });
  });
}
