import '../../linking/models/invite_code.dart';

/// نتيجة إنشاء كود دعوة موظف: الكود نفسه + اسم السنتر (لرسالة الواتساب).
class StaffInviteIssued {
  const StaffInviteIssued({required this.invite, required this.centerName});

  final InviteCode invite;
  final String centerName;
}
