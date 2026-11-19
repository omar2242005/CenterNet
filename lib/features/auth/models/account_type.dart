/// نوع الحساب وقت التسجيل. للتوجيه في الشاشات فقط، ومبيدّيش أي صلاحية
/// (الصلاحيات من members و studentLinks فقط).
enum AccountType {
  admin('admin'),
  staff('staff'),
  guardian('guardian'),
  student('student');

  const AccountType(this.wire);

  /// القيمة المكتوبة في Firestore.
  final String wire;

  static AccountType parse(Object? raw) {
    for (final t in AccountType.values) {
      if (t.wire == raw) return t;
    }
    throw FormatException('نوع حساب غير معروف: $raw');
  }
}
