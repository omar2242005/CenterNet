import '../../../l10n/app_localizations.dart';
import '../../linking/models/invite_code.dart';
import 'staff_member.dart';

/// اسم دور الموظف بالعربي من `app_ar.arb`.
extension StaffInviteRoleText on StaffInviteRole {
  String label(AppLocalizations l10n) => switch (this) {
    StaffInviteRole.teacher => l10n.staffRoleTeacher,
    StaffInviteRole.assistant => l10n.staffRoleAssistant,
  };
}

/// اسم دور العضو (شامل الأدمن) بالعربي.
extension StaffMemberRoleText on StaffMemberRole {
  String label(AppLocalizations l10n) => switch (this) {
    StaffMemberRole.admin => l10n.staffRoleAdmin,
    StaffMemberRole.teacher => l10n.staffRoleTeacher,
    StaffMemberRole.assistant => l10n.staffRoleAssistant,
  };
}
