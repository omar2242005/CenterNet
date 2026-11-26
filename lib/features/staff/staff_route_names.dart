/// أسماء مسارات الموظفين في مكان واحد.
abstract final class StaffRoutes {
  static const String list = '/staff';
  /// دعوة المعلم والمساعد مساران منفصلين تمامًا (مفيش اختيار دور في الشاشة).
  static const String inviteTeacher = '/staff/invite/teacher';
  static const String inviteAssistant = '/staff/invite/assistant';
  static const String join = '/staff/join';
}
