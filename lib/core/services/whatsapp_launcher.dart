import 'package:url_launcher/url_launcher.dart';

import '../errors/failure.dart';
import '../utils/digits.dart';

/// فتح واتساب برسالة جاهزة (دعوات الأكواد وإبلاغ ولي الأمر).
///
/// بناء الرابط دوال static نقية بتتختبر من غير جهاز. فتح الرابط الفعلي
/// بيتم عن طريق باراميتر `launch` في الـ constructor، وبيتبدل في الاختبار.
class WhatsAppLauncher {
  WhatsAppLauncher({Future<bool> Function(Uri uri)? launch})
      : _launch = launch ??
            ((uri) => launchUrl(uri, mode: LaunchMode.externalApplication));

  final Future<bool> Function(Uri uri) _launch;

  static final RegExp _egyptMobile = RegExp(r'^01[0125]\d{8}$');

  /// يحوّل موبايل مصري لصيغة دولية بدون + (مثال: 201012345678).
  /// بيقبل 01012345678 و+201012345678 و00201012345678 وأرقام هندية
  /// ومسافات وشرطات. بيرجّع null لو مش موبايل مصري صالح.
  static String? toInternational(String phone) {
    var p = toLatinDigits(phone).replaceAll(RegExp(r'[\s\-().]'), '');
    if (p.startsWith('+')) p = p.substring(1);
    if (p.startsWith('0020')) p = '0${p.substring(4)}';
    if (p.startsWith('20') && p.length == 12) p = '0${p.substring(2)}';
    if (!_egyptMobile.hasMatch(p)) return null;
    return '20${p.substring(1)}';
  }

  /// رابط wa.me بالرسالة. null لو الرقم مش صالح.
  static Uri? buildUri(String phone, String message) {
    final intl = toInternational(phone);
    if (intl == null) return null;
    return Uri.parse('https://wa.me/$intl?text=${Uri.encodeComponent(message)}');
  }

  /// بيرمي [Failure] بعربي لو الرقم غلط أو واتساب مش بيفتح.
  Future<void> open(String phone, String message) async {
    final uri = buildUri(phone, message);
    if (uri == null) {
      throw const Failure.validation('رقم الموبايل غير صالح');
    }
    final ok = await _launch(uri);
    if (!ok) {
      throw const Failure.validation(
        'تعذر فتح واتساب. تأكد إن التطبيق متثبّت.',
      );
    }
  }
}
