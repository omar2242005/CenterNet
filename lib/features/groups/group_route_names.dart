/// أسماء مسارات المجموعات في مكان واحد.
abstract final class GroupRoutes {
  static const String list = '/groups';
  static const String create = '/groups/new';

  /// بياخد `extra: Group`.
  static const String edit = '/groups/edit';

  /// بياخد `extra: Group`.
  static const String students = '/groups/students';

  /// بياخد `extra: Group`.
  static const String sessions = '/groups/sessions';
}
