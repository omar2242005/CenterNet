/// أسماء مسارات الطلاب في مكان واحد.
abstract final class StudentRoutes {
  static const String list = '/students';
  static const String create = '/students/new';

  /// بياخد `extra: Student`.
  static const String detail = '/students/detail';

  /// بياخد `extra: Student`.
  static const String edit = '/students/edit';
}
