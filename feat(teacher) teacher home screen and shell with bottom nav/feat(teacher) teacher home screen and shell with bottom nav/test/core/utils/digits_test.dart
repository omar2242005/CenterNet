import 'package:center_net/core/utils/digits.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('الأرقام الهندية والفارسية بتتحول للاتينية', () {
    expect(toLatinDigits('٠١٠١٢٣٤٥٦٧٨'), '01012345678');
    expect(toLatinDigits('۰۱۲۳۴۵۶۷۸۹'), '0123456789');
  });

  test('باقي النص زي ما هو', () {
    expect(toLatinDigits('أحمد 5 abc'), 'أحمد 5 abc');
    expect(toLatinDigits(''), '');
  });
}
