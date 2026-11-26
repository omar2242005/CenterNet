import 'staff_member.dart';

/// نتيجة تحميل قائمة الموظفين: السنتر + أعضاؤه (الأدمن الأول، وبعده النشطين).
class StaffRoster {
  const StaffRoster({required this.centerId, required this.members});

  final String centerId;
  final List<StaffMember> members;

  /// الترتيب: الأدمن، ثم النشط قبل المعطّل، ثم بالاسم.
  static int compare(StaffMember a, StaffMember b) {
    if (a.isAdmin != b.isAdmin) return a.isAdmin ? -1 : 1;
    if (a.active != b.active) return a.active ? -1 : 1;
    return a.name.compareTo(b.name);
  }
}
