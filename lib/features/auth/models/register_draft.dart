/// بيانات نموذج التسجيل بين شاشة البيانات وشاشة اختيار نوع الحساب.
/// بتتحفظ في الذاكرة بس (بتتبعت عن طريق go_router extra) ومبتتكتبش في أي مكان.
class RegisterDraft {
  const RegisterDraft({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
  });

  final String name;
  final String email;

  /// موبايل بعد التنظيف: 01XXXXXXXXX.
  final String phone;
  final String password;
}
