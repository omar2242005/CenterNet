import 'package:center_net/app/route_guard.dart';
import 'package:center_net/features/attendance/attendance_route_names.dart';
import 'package:center_net/features/auth/auth_route_names.dart';
import 'package:center_net/features/centers/center_route_names.dart';
import 'package:center_net/features/home/home_route_names.dart';
import 'package:center_net/features/home/models/home_destination.dart';
import 'package:center_net/features/staff/staff_route_names.dart';
import 'package:center_net/features/students/student_route_names.dart';
import 'package:flutter_test/flutter_test.dart';

String? g(
  String location, {
  bool signedIn = true,
  bool verified = true,
  HomeDestination? role,
}) =>
    guardRoute(
      location: location,
      signedIn: signedIn,
      emailVerified: verified,
      role: role,
    );

void main() {
  group('مش مسجّل دخول', () {
    test('الشاشات العامة بتعدّي', () {
      for (final p in [
        '/',
        AuthRoutes.login,
        AuthRoutes.register,
        AuthRoutes.accountType,
        AuthRoutes.forgotPassword,
      ]) {
        expect(g(p, signedIn: false, verified: false), isNull, reason: p);
      }
    });

    test('أي حاجة تانية تحوّل للدخول', () {
      for (final p in [
        AuthRoutes.signedIn,
        AuthRoutes.verifyEmail,
        HomeRoutes.admin,
        StudentRoutes.list,
        StaffRoutes.join,
        '/route-مش-متسجل',
      ]) {
        expect(g(p, signedIn: false, verified: false), AuthRoutes.login,
            reason: p);
      }
    });
  });

  group('مسجّل بس الإيميل مش مأكّد', () {
    test('تأكيد الإيميل وشاشات الدخول بتعدّي', () {
      expect(g(AuthRoutes.verifyEmail, verified: false), isNull);
      expect(g(AuthRoutes.login, verified: false), isNull);
      expect(g(AuthRoutes.accountType, verified: false), isNull);
    });

    test('أي حاجة تانية تحوّل لتأكيد الإيميل', () {
      expect(g(AuthRoutes.signedIn, verified: false), AuthRoutes.verifyEmail);
      expect(g(HomeRoutes.admin, verified: false), AuthRoutes.verifyEmail);
    });
  });

  group('مسجّل ومأكّد', () {
    test('شاشات الدخول وتأكيد الإيميل تحوّل للـ gate', () {
      for (final p in [
        AuthRoutes.login,
        AuthRoutes.register,
        AuthRoutes.accountType,
        AuthRoutes.forgotPassword,
        AuthRoutes.verifyEmail,
      ]) {
        expect(g(p, role: HomeDestination.admin), AuthRoutes.signedIn,
            reason: p);
      }
    });

    test('الـ gate والـ splash بيعدّوا حتى من غير دور', () {
      expect(g(AuthRoutes.signedIn), isNull);
      expect(g('/'), isNull);
    });

    test('الأدمن يفتح شاشاته', () {
      for (final p in [
        HomeRoutes.admin,
        StudentRoutes.list,
        StudentRoutes.create,
        StudentRoutes.detail,
        StudentRoutes.edit,
        StaffRoutes.list,
        StaffRoutes.invite,
        CenterRoutes.settings,
      ]) {
        expect(g(p, role: HomeDestination.admin), isNull, reason: p);
      }
    });

    test('المعلم والمساعد مينفعش يفتحوا شاشات الأدمن ويرجعوا لرئيستهم', () {
      for (final p in [
        StudentRoutes.list,
        StudentRoutes.create,
        StaffRoutes.list,
        StaffRoutes.invite,
        CenterRoutes.settings,
        HomeRoutes.admin,
      ]) {
        expect(g(p, role: HomeDestination.teacher), HomeRoutes.teacher,
            reason: p);
        expect(g(p, role: HomeDestination.assistant), HomeRoutes.assistant,
            reason: p);
      }
    });

    test('المسح للمساعد والمعلم بس', () {
      expect(g(AttendanceRoutes.scan, role: HomeDestination.assistant), isNull);
      expect(g(AttendanceRoutes.scan, role: HomeDestination.teacher), isNull);
      expect(g(AttendanceRoutes.scan, role: HomeDestination.admin),
          HomeRoutes.admin);
      expect(g(AttendanceRoutes.scan, role: HomeDestination.student),
          HomeRoutes.student);
    });

    test('الطالب وولي الأمر مينفعش يفتحوا شاشات الموظفين', () {
      expect(g(StudentRoutes.list, role: HomeDestination.student),
          HomeRoutes.student);
      expect(g(StaffRoutes.list, role: HomeDestination.guardian),
          HomeRoutes.guardian);
      expect(g(HomeRoutes.student, role: HomeDestination.guardian),
          HomeRoutes.guardian);
    });

    test('إنشاء السنتر لمن معندوش سنتر بس، وقبول الكود للموظف بس', () {
      expect(g(CenterRoutes.create, role: HomeDestination.createCenter),
          isNull);
      expect(g(CenterRoutes.create, role: HomeDestination.admin),
          HomeRoutes.admin);
      expect(g(StaffRoutes.join, role: HomeDestination.joinCenter), isNull);
      expect(g(StaffRoutes.join, role: HomeDestination.teacher),
          HomeRoutes.teacher);
      // مستخدم من غير سنتر مينفعش يفتح إعدادات السنتر.
      expect(g(CenterRoutes.settings, role: HomeDestination.createCenter),
          CenterRoutes.create);
    });

    test('الدور لسه مش معروف: الشاشات المحمية تعدّي على الـ gate', () {
      expect(g(StudentRoutes.list), AuthRoutes.signedIn);
      expect(g(HomeRoutes.teacher), AuthRoutes.signedIn);
    });

    test('المعطّل ومن غير عضوية شاشته بس', () {
      expect(g(HomeRoutes.inactive, role: HomeDestination.inactive), isNull);
      expect(g(StudentRoutes.list, role: HomeDestination.inactive),
          HomeRoutes.inactive);
      expect(g('/route-مش-متسجل', role: HomeDestination.noAccess),
          HomeRoutes.noAccess);
    });

    test('مسار مش في الجدول بيعدّي (عشان باقي الفريق)', () {
      expect(g('/groups', role: HomeDestination.teacher), isNull);
      expect(g('/my-account', role: HomeDestination.student), isNull);
    });

    test('مفيش حلقة: وجهة كل دور هي نفسها مسموحة له', () {
      for (final d in HomeDestination.values) {
        final home = HomeRoutes.forDestination(d);
        expect(g(home, role: d), isNull, reason: '$d → $home');
      }
    });
  });
}
