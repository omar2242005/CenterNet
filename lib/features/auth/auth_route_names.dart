/// أسماء مسارات الـ auth في مكان واحد (الـ router الرئيسي بيستخدمها).
abstract final class AuthRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String accountType = '/register/account-type';
  static const String verifyEmail = '/verify-email';
  static const String forgotPassword = '/forgot-password';

  /// نقطة الدخول بعد أي تسجيل دخول: شاشة بتحدد الدور وتوجّه للرئيسية
  /// المناسبة (feature الـ home).
  static const String signedIn = '/signed-in';
}
