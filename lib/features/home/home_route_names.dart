import '../centers/center_route_names.dart';
import '../staff/staff_route_names.dart';
import 'models/home_destination.dart';

/// أسماء مسارات الرئيسيات في مكان واحد.
///
/// نقطة الدخول بعد أي تسجيل دخول هي `AuthRoutes.signedIn`: الشاشة اللي
/// عليها بتحدد الوجهة وتوجّه لواحد من دول.
abstract final class HomeRoutes {
  static const String admin = '/home/admin';
  static const String teacher = '/home/teacher';
  static const String assistant = '/home/assistant';
  static const String student = '/home/student';
  static const String guardian = '/home/guardian';
  static const String inactive = '/home/inactive';
  static const String noAccess = '/home/no-access';

  static String forDestination(HomeDestination d) => switch (d) {
        HomeDestination.createCenter => CenterRoutes.create,
        HomeDestination.joinCenter => StaffRoutes.join,
        HomeDestination.admin => admin,
        HomeDestination.teacher => teacher,
        HomeDestination.assistant => assistant,
        HomeDestination.student => student,
        HomeDestination.guardian => guardian,
        HomeDestination.inactive => inactive,
        HomeDestination.noAccess => noAccess,
      };
}
