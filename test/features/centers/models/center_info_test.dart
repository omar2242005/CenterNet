import 'package:center_net/features/centers/models/center_form_error.dart';
import 'package:center_net/features/centers/models/center_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CenterInfo', () {
    test('toCreateMap: الحقول المسموحة بس، والتأخير الافتراضي 15', () {
      final m = CenterInfo.toCreateMap(
        name: '  مركز النور ',
        year: 2026,
        createdBy: 'u1',
        createdAt: 'TS',
      );
      expect(m, {
        'name': 'مركز النور',
        'year': 2026,
        'createdBy': 'u1',
        'lateAfterMinutes': 15,
        'createdAt': 'TS',
      });
    });

    test('toSettingsMap: name و year و lateAfterMinutes بس (من غير createdBy)', () {
      final m = CenterInfo.toSettingsMap(
        name: ' س ',
        year: 2027,
        lateAfterMinutes: 20,
      );
      expect(m, {'name': 'س', 'year': 2027, 'lateAfterMinutes': 20});
    });

    test('fromMap بيقرا الحقول ويستخدم الافتراضي للناقص', () {
      final c = CenterInfo.fromMap('c1', {'name': 'x', 'createdBy': 'u1'});
      expect(c.id, 'c1');
      expect(c.lateAfterMinutes, 15);
      expect(c.year, DateTime.now().year);
    });

    test('fromMap بيرمي FormatException لو name ناقص', () {
      expect(
        () => CenterInfo.fromMap('c1', {'createdBy': 'u1'}),
        throwsFormatException,
      );
    });
  });

  group('CenterValidators', () {
    test('الاسم', () {
      expect(CenterValidators.name('  '), CenterFormError.required);
      expect(CenterValidators.name('a' * 81), CenterFormError.nameTooLong);
      expect(CenterValidators.name('مركز النور 2'), isNull);
    });

    test('السنة', () {
      expect(CenterValidators.year(''), CenterFormError.required);
      expect(CenterValidators.year('abc'), CenterFormError.yearInvalid);
      expect(CenterValidators.year('1999'), CenterFormError.yearInvalid);
      expect(CenterValidators.year('2026'), isNull);
    });

    test('مدة التأخير 0 إلى 180', () {
      expect(CenterValidators.lateAfter(''), CenterFormError.required);
      expect(CenterValidators.lateAfter('-1'), CenterFormError.lateInvalid);
      expect(CenterValidators.lateAfter('181'), CenterFormError.lateInvalid);
      expect(CenterValidators.lateAfter('0'), isNull);
      expect(CenterValidators.lateAfter('180'), isNull);
    });
  });
}
