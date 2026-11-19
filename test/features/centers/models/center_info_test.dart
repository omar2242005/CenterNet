import 'package:center_net/features/centers/models/center_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CenterInfo', () {
    test('fromMap بيقرا الحقول', () {
      final c = CenterInfo.fromMap('c1', {
        'name': 'مركز النور',
        'year': 2026,
        'lateAfterMinutes': 20,
        'createdBy': 'u1',
      });
      expect(c.id, 'c1');
      expect(c.name, 'مركز النور');
      expect(c.year, 2026);
      expect(c.lateAfterMinutes, 20);
    });

    test(
      'fromMap: lateAfterMinutes الناقصة = 15، والأرقام العشرية بتتحوّل',
      () {
        final c = CenterInfo.fromMap('c1', {'name': 'س', 'year': 2026.0});
        expect(c.lateAfterMinutes, CenterInfo.defaultLateAfterMinutes);
        expect(c.lateAfterMinutes, 15);
        expect(c.year, 2026);
      },
    );

    test('fromMap بيرمي FormatException لو name أو year ناقص', () {
      expect(
        () => CenterInfo.fromMap('c1', {'year': 2026}),
        throwsFormatException,
      );
      expect(
        () => CenterInfo.fromMap('c1', {'name': 'س'}),
        throwsFormatException,
      );
    });

    test('toCreateMap: الحقول اللي validCenter بتسمح بيها بالظبط', () {
      final map = CenterInfo.toCreateMap(
        uid: 'u1',
        name: 'مركز النور',
        year: 2026,
        createdAt: 'TS',
      );
      expect(map, {
        'name': 'مركز النور',
        'year': 2026,
        'createdBy': 'u1',
        'createdAt': 'TS',
        'lateAfterMinutes': 15,
      });
    });

    test('toSettingsMap: الحقول التلاتة المسموحة للأدمن بس', () {
      final map = CenterInfo.toSettingsMap(
        name: 'س',
        year: 2027,
        lateAfterMinutes: 30,
      );
      expect(map.keys.toSet(), {'name', 'year', 'lateAfterMinutes'});
      expect(map.containsKey('createdBy'), isFalse);
    });

    test('copyWith', () {
      const c = CenterInfo(id: 'c1', name: 'أ', year: 2026);
      final d = c.copyWith(name: 'ب', lateAfterMinutes: 5);
      expect(d.id, 'c1');
      expect(d.name, 'ب');
      expect(d.year, 2026);
      expect(d.lateAfterMinutes, 5);
    });
  });
}
