import '../../../l10n/app_localizations.dart';
import '../../linking/models/invite_code.dart';

/// اسم دور الموظف بالعربي من `app_ar.arb`.
extension StaffInviteRoleText on StaffInviteRole {
  String label(AppLocalizations l10n) => switch (this) {
        StaffInviteRole.teacher => l10n.staffRoleTeacher,
        StaffInviteRole.assistant => l10n.staffRoleAssistant,
      };
}
