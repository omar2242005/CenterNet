import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/core/services/whatsapp_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('toInternational', () {
    test('الصيغ المقبولة', () {
      for (final input in [
        '01012345678',
        '+201012345678',
        '00201012345678',
        '201012345678',
        '010 1234 5678',
        '010-1234-5678',
        '٠١٠١٢٣٤٥٦٧٨', // أرقام هندية
      ]) {
        expect(WhatsAppLauncher.toInternational(input), '201012345678',
            reason: input);
      }
    });

    test('الصيغ المرفوضة', () {
      for (final input in [
        '',
        '0101234567', // قصير
        '010123456789', // طويل
        '01312345678', // شبكة غلط
        '02212345678', // أرضي
        'abc',
      ]) {
        expect(WhatsAppLauncher.toInternational(input), isNull,
            reason: input);
      }
    });
  });

  test('buildUri بيعمل ترميز للرسالة العربية', () {
    final uri = WhatsAppLauncher.buildUri('01012345678', 'كود: AB 12')!;
    expect(uri.host, 'wa.me');
    expect(uri.path, '/201012345678');
    expect(uri.queryParameters['text'], 'كود: AB 12');
    expect(uri.toString(), contains('%20'));
  });

  test('buildUri بيرجّع null لرقم غلط', () {
    expect(WhatsAppLauncher.buildUri('123', 'x'), isNull);
  });

  test('open بيمرر الرابط للـ launcher', () async {
    Uri? opened;
    final w = WhatsAppLauncher(launch: (u) async {
      opened = u;
      return true;
    });
    await w.open('01012345678', 'مرحبا');
    expect(opened?.host, 'wa.me');
    expect(opened?.queryParameters['text'], 'مرحبا');
  });

  test('open برقم غلط بيرمي Failure بعربي من غير ما يفتح حاجة', () async {
    var called = false;
    final w = WhatsAppLauncher(launch: (_) async {
      called = true;
      return true;
    });
    await expectLater(
      w.open('123', 'x'),
      throwsA(isA<Failure>().having((f) => f.message, 'message',
          'رقم الموبايل غير صالح')),
    );
    expect(called, isFalse);
  });

  test('open لما واتساب مش بيفتح بيرمي Failure', () async {
    final w = WhatsAppLauncher(launch: (_) async => false);
    await expectLater(w.open('01012345678', 'x'), throwsA(isA<Failure>()));
  });
}
