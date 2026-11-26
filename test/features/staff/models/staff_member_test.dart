import 'package:center_net/features/linking/models/invite_code.dart';
import 'package:center_net/features/staff/models/staff_member.dart';
import 'package:center_net/features/staff/models/staff_roster.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StaffMemberRole', () {
    test('parse بيفهم الأدوار التلاتة', () {
      expect(StaffMemberRole.parse('admin'), StaffMemberRole.admin);
      expect(StaffMemberRole.parse('teacher'), StaffMemberRole.teacher);
      expect(StaffMemberRole.parse('assistant'), StaffMemberRole.assistant);
    });

    test('parse بيرفض دور غير معروف', () {
      expect(() => StaffMemberRole.parse('owner'), throwsFormatException);
      expect(() => StaffMemberRole.parse(null), throwsFormatException);
    });

    test('fromInvite', () {
      expect(
        StaffMemberRole.fromInvite(StaffInviteRole.teacher),
        StaffMemberRole.teacher,
      );
      expect(
        StaffMemberRole.fromInvite(StaffInviteRole.assistant),
        StaffMemberRole.assistant,
      );
    });
  });

  group('StaffMember', () {
    test('fromMap بيقرا مستند عضو سليم', () {
      final m = StaffMember.fromMap('u1', <String, dynamic>{
        'role': 'teacher',
        'name': 'سارة',
        'active': true,
        'createdBy': 'u1',
      });
      expect(m.uid, 'u1');
      expect(m.name, 'سارة');
      expect(m.role, StaffMemberRole.teacher);
      expect(m.active, isTrue);
    });

    test('fromMap بيرفض مستند ناقص أو بدور غلط', () {
      expect(
        () => StaffMember.fromMap('u1', <String, dynamic>{
          'role': 'teacher',
          'active': true,
        }),
        throwsFormatException,
      );
      expect(
        () => StaffMember.fromMap('u1', <String, dynamic>{
          'role': 'teacher',
          'name': 'سارة',
        }),
        throwsFormatException,
      );
      expect(
        () => StaffMember.fromMap('u1', <String, dynamic>{
          'role': 'owner',
          'name': 'سارة',
          'active': true,
        }),
        throwsFormatException,
      );
    });

    test('الأدمن مش قابل للتعديل', () {
      const admin = StaffMember(
        uid: 'a',
        name: 'مدير',
        role: StaffMemberRole.admin,
        active: true,
      );
      expect(admin.isAdmin, isTrue);
      expect(admin.editable, isFalse);
    });

    test('المعلم والمساعد قابلين للتعديل (الدور ثابت)', () {
      const teacher = StaffMember(
        uid: 't',
        name: 'سارة',
        role: StaffMemberRole.teacher,
        active: true,
      );
      const assistant = StaffMember(
        uid: 's',
        name: 'كريم',
        role: StaffMemberRole.assistant,
        active: true,
      );
      expect(teacher.editable, isTrue);
      expect(assistant.editable, isTrue);
    });

    test('copyWith بيغيّر الدور والتفعيل بس', () {
      const m = StaffMember(
        uid: 't',
        name: 'سارة',
        role: StaffMemberRole.teacher,
        active: true,
      );
      final changed = m.copyWith(
        role: StaffMemberRole.assistant,
        active: false,
      );
      expect(changed.uid, 't');
      expect(changed.name, 'سارة');
      expect(changed.role, StaffMemberRole.assistant);
      expect(changed.active, isFalse);
      expect(m.copyWith(), m);
    });
  });

  group('StaffRoster.compare', () {
    test('الأدمن الأول، بعده النشطين، بعدهم المعطّلين، وبالاسم', () {
      const admin = StaffMember(
        uid: 'a',
        name: 'يوسف',
        role: StaffMemberRole.admin,
        active: true,
      );
      const activeA = StaffMember(
        uid: 'b',
        name: 'أحمد',
        role: StaffMemberRole.teacher,
        active: true,
      );
      const activeB = StaffMember(
        uid: 'c',
        name: 'سارة',
        role: StaffMemberRole.assistant,
        active: true,
      );
      const disabled = StaffMember(
        uid: 'd',
        name: 'أمل',
        role: StaffMemberRole.teacher,
        active: false,
      );

      final list = <StaffMember>[disabled, activeB, admin, activeA]
        ..sort(StaffRoster.compare);

      expect(list.map((m) => m.uid).toList(), ['a', 'b', 'c', 'd']);
    });
  });
}
