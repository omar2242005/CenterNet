import 'package:center_net/features/auth/models/account_type.dart';
import 'package:center_net/features/home/models/home_destination.dart';
import 'package:center_net/features/staff/models/staff_member.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MembershipInfo m(StaffMemberRole r, {bool active = true}) =>
      (role: r, active: active);

  group('بدون سنتر', () {
    test('أدمن يروح لإنشاء سنتر', () {
      expect(
        decideHome(accountType: AccountType.admin, centerId: null),
        HomeDestination.createCenter,
      );
    });

    test('موظف يروح لإدخال كود الدعوة', () {
      expect(
        decideHome(accountType: AccountType.staff, centerId: null),
        HomeDestination.joinCenter,
      );
    });
  });

  group('أدمن وموظف بسنتر', () {
    test('الدور من العضوية مش من accountType', () {
      expect(
        decideHome(
          accountType: AccountType.staff,
          centerId: 'c1',
          membership: m(StaffMemberRole.admin),
        ),
        HomeDestination.admin,
      );
    });

    test('معلم ومساعد', () {
      expect(
        decideHome(
          accountType: AccountType.staff,
          centerId: 'c1',
          membership: m(StaffMemberRole.teacher),
        ),
        HomeDestination.teacher,
      );
      expect(
        decideHome(
          accountType: AccountType.staff,
          centerId: 'c1',
          membership: m(StaffMemberRole.assistant),
        ),
        HomeDestination.assistant,
      );
    });

    test('عضو معطّل', () {
      expect(
        decideHome(
          accountType: AccountType.staff,
          centerId: 'c1',
          membership: m(StaffMemberRole.teacher, active: false),
        ),
        HomeDestination.inactive,
      );
    });

    test('centerId من غير عضوية', () {
      expect(
        decideHome(accountType: AccountType.staff, centerId: 'c1'),
        HomeDestination.noAccess,
      );
      expect(
        decideHome(accountType: AccountType.admin, centerId: 'c1'),
        HomeDestination.noAccess,
      );
    });
  });

  group('الطالب وولي الأمر (مؤقتًا بالـ accountType)', () {
    test('بـ centerId وبدونه نفس النتيجة', () {
      for (final c in <String?>[null, 'c1']) {
        expect(
          decideHome(accountType: AccountType.student, centerId: c),
          HomeDestination.student,
        );
        expect(
          decideHome(accountType: AccountType.guardian, centerId: c),
          HomeDestination.guardian,
        );
      }
    });

    test('العضوية متأثرش عليهم', () {
      expect(
        decideHome(
          accountType: AccountType.guardian,
          centerId: 'c1',
          membership: m(StaffMemberRole.admin),
        ),
        HomeDestination.guardian,
      );
    });
  });
}
