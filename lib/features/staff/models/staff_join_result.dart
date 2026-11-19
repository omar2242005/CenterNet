import '../../linking/models/invite_code.dart';

/// نتيجة قبول كود دعوة موظف: السنتر اللي انضم له والدور اللي اتحدد.
class StaffJoinResult {
  const StaffJoinResult({
    required this.centerId,
    required this.centerName,
    required this.role,
  });

  final String centerId;

  /// فاضي لو تعذّرت قراءة اسم السنتر بعد الانضمام (الانضمام نفسه نجح).
  final String centerName;
  final StaffInviteRole role;
}
