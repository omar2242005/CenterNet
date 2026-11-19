import 'package:center_net/features/centers/models/center_member.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MemberRole', () {
    test('parse بيرجّع الدور الصح', () {
      for (final r in MemberRole.values) {
        expect(MemberRole.parse(r.wire), r);
      }
    });

    test('parse بيرمي FormatException لقيمة غريبة', () {
      expect(() => MemberRole.parse('owner'), throwsFormatException);
      expect(() => MemberRole.parse(null), throwsFormatException);
    });
  });

  group('CenterMember', () {
    test('fromMap بيقرا الحقول', () {
      final m = CenterMember.fromMap('u1', {
        'role': 'teacher',
        'name': 'سارة',
        'active': true,
      });
      expect(m.uid, 'u1');
      expect(m.role, MemberRole.teacher);
      expect(m.name, 'سارة');
      expect(m.active, isTrue);
    });

    test('fromMap بيرمي FormatException لو حقل ناقص أو غلط', () {
      expect(
        () => CenterMember.fromMap('u1', {'role': 'admin', 'active': true}),
        throwsFormatException,
      );
      expect(
        () => CenterMember.fromMap('u1', {'role': 'admin', 'name': 'س'}),
        throwsFormatException,
      );
      expect(
        () => CenterMember.fromMap('u1', {
          'role': 'boss',
          'name': 'س',
          'active': true,
        }),
        throwsFormatException,
      );
    });

    test('isAdmin: أدمن ونشط بس', () {
      CenterMember make(MemberRole r, bool active) =>
          CenterMember(uid: 'u', role: r, name: 'س', active: active);
      expect(make(MemberRole.admin, true).isAdmin, isTrue);
      expect(make(MemberRole.admin, false).isAdmin, isFalse);
      expect(make(MemberRole.teacher, true).isAdmin, isFalse);
      expect(make(MemberRole.assistant, true).isAdmin, isFalse);
    });

    test(
      'toAdminCreateMap: الحقول اللي validMember بتسمح بيها، من غير inviteCode',
      () {
        final map = CenterMember.toAdminCreateMap(
          uid: 'u1',
          name: '  أحمد ',
          createdAt: 'TS',
        );
        expect(map, {
          'role': 'admin',
          'name': 'أحمد',
          'active': true,
          'createdAt': 'TS',
          'createdBy': 'u1',
        });
      },
    );
  });
}
