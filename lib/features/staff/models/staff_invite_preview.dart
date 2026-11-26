import '../../linking/models/invite_code.dart';

/// معاينة كود دعوة موظف قبل الانضمام: الدور اللي هيتمنح بالظبط.
/// اسم السنتر مش متاح قبل الانضمام (الـ Rules بتسمح بقراءة السنتر للأعضاء بس)،
/// فبيظهر في شاشة النجاح بعد الانضمام.
class StaffInvitePreview {
  const StaffInvitePreview({required this.code, required this.role});

  /// الكود بعد التطبيع.
  final String code;
  final StaffInviteRole role;
}
