/// أنواع أخطاء التحقق. الـ utils بترجّع النوع بس، والنص العربي بيتجاب من
/// `app_ar.arb` عن طريق `validation_text.dart` (مفيش نص عربي هنا).
enum ValidationError {
  required,
  nameTooShort,
  nameTooLong,
  nameInvalid,
  mobileInvalid,
  emailInvalid,
  passwordTooShort,
  scoreInvalid,
  scoreOutOfRange,
  scoreStep,
}
