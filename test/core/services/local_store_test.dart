import 'package:center_net/core/services/local_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LocalStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = await LocalStore.open();
  });

  test('نص: كتابة وقراءة وحذف', () async {
    expect(store.getString('k'), isNull);
    await store.setString('k', 'مرحبا');
    expect(store.getString('k'), 'مرحبا');
    expect(store.containsKey('k'), isTrue);
    await store.remove('k');
    expect(store.containsKey('k'), isFalse);
  });

  test('JSON: قائمة خرائط بترجع زي ما اتكتبت', () async {
    final list = [
      {'sid': 's1', 'status': 'pending'},
      {'sid': 's2', 'status': 'failed', 'reason': 'سجّله مساعد آخر'},
    ];
    await store.setJson('scans', list);
    expect(store.getJson('scans'), list);
  });

  test('مفتاح مش موجود = null', () {
    expect(store.getJson('nope'), isNull);
  });

  test('JSON باظ بيرمي FormatException (مفيش فشل صامت)', () async {
    await store.setString('bad', '{not json');
    expect(() => store.getJson('bad'), throwsFormatException);
  });
}
