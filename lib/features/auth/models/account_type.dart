/// نوع الحساب وقت التسجيل. للتوجيه في الشاشات فقط، ومبيدّيش أي صلاحية
/// (الصلاحيات من members و studentLinks فقط).
enum AccountType {
  admin('admin'),
  teacher('teacher'),
  assistant('assistant'),

  /// قديم: حسابات اتسجلت قبل فصل المعلم عن المساعد. بيتقرأ بس ومبيظهرش
  /// في شاشة الاختيار.
  staff('staff'),
  guardian('guardian'),
  student('student');

  const AccountType(this.wire);

  /// القيمة المكتوبة في Firestore.
  final String wire;

  /// جهة الموظفين (أدمن/معلم/مساعد/قديم): الصلاحية الفعلية من members.
  bool get isStaffSide =>
      this == admin || this == teacher || this == assistant || this == staff;

  /// الأنواع اللي بتظهر في شاشة التسجيل.
  static const List<AccountType> selectable = [
    admin,
    teacher,
    assistant,
    guardian,
    student,
  ];

  static AccountType parse(Object? raw) {
    for (final t in AccountType.values) {
      if (t.wire == raw) return t;
    }
    throw FormatException('نوع حساب غير معروف: $raw');
  }
}
