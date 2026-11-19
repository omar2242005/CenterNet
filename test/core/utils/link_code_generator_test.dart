import 'dart:math';

import 'package:center_net/core/utils/link_code_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('الأبجدية مفيهاش حروف ملتبسة (0 / O / 1 / I)', () {
    for (final c in ['0', 'O', '1', 'I']) {
      expect(LinkCodeGenerator.alphabet.contains(c), isFalse, reason: c);
    }
    expect(LinkCodeGenerator.alphabet.length, 32);
  });

  test('الكود 8 رموز كلها من الأبجدية (على 2000 كود)', () {
    final r = Random(42);
    for (var i = 0; i < 2000; i++) {
      final code = LinkCodeGenerator.generate(r);
      expect(code.length, 8);
      for (final ch in code.split('')) {
        expect(LinkCodeGenerator.alphabet.contains(ch), isTrue, reason: code);
      }
    }
  });

  test('نفس الـ seed بيدي نفس الكود، وأكواد مختلفة بتختلف', () {
    expect(
      LinkCodeGenerator.generate(Random(1)),
      LinkCodeGenerator.generate(Random(1)),
    );
    expect(
      LinkCodeGenerator.generate(Random(1)),
      isNot(LinkCodeGenerator.generate(Random(2))),
    );
  });

  test('generate من غير Random بيشتغل', () {
    expect(LinkCodeGenerator.generate().length, 8);
  });

  test('normalize و isWellFormed', () {
    expect(LinkCodeGenerator.normalize(' abcd-2345 '), 'ABCD2345');
    expect(LinkCodeGenerator.isWellFormed('abcd 2345'), isTrue);
    expect(LinkCodeGenerator.isWellFormed('ABCD234'), isFalse);
    expect(LinkCodeGenerator.isWellFormed('ABCD2340'), isFalse); // فيه 0
    expect(LinkCodeGenerator.isWellFormed('ABCDEFGO'), isFalse); // فيه O
  });
}
