// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get loading => 'جارٍ التحميل';

  @override
  String get emptyDefault => 'لا توجد بيانات لعرضها';

  @override
  String get confirm => 'تأكيد';

  @override
  String get cancel => 'إلغاء';

  @override
  String get searchHint => 'بحث';

  @override
  String get clearSearch => 'مسح البحث';

  @override
  String get showPassword => 'إظهار كلمة السر';

  @override
  String get hidePassword => 'إخفاء كلمة السر';

  @override
  String get qrSemantics => 'رمز QR الخاص بالطالب';

  @override
  String get validationRequired => 'هذا الحقل مطلوب';

  @override
  String get validationNameTooShort => 'الاسم قصير جدًا';

  @override
  String get validationNameTooLong => 'الاسم طويل جدًا';

  @override
  String get validationNameInvalid => 'الاسم يجب أن يحتوي على حروف فقط';

  @override
  String get validationMobileInvalid =>
      'رقم الموبايل غير صالح، مثال: 01012345678';

  @override
  String get validationEmailInvalid => 'البريد الإلكتروني غير صالح';

  @override
  String get validationPasswordTooShort => 'كلمة السر يجب ألا تقل عن 8 أحرف';

  @override
  String get validationScoreInvalid => 'الدرجة غير صالحة';

  @override
  String get validationScoreOutOfRange => 'الدرجة خارج النطاق المسموح';

  @override
  String get validationScoreStep => 'الدرجة تُكتب بخطوة 0.5 فقط';

  @override
  String currencyEgp(String amount) {
    return '$amount ج.م';
  }

  @override
  String dateFull(int day, String month, int year) {
    return '$day $month $year';
  }

  @override
  String monthName(String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      'm1': 'يناير',
      'm2': 'فبراير',
      'm3': 'مارس',
      'm4': 'أبريل',
      'm5': 'مايو',
      'm6': 'يونيو',
      'm7': 'يوليو',
      'm8': 'أغسطس',
      'm9': 'سبتمبر',
      'm10': 'أكتوبر',
      'm11': 'نوفمبر',
      'other': 'ديسمبر',
    });
    return '$_temp0';
  }

  @override
  String timeFormat(String hour, String minute, String period) {
    return '$hour:$minute $period';
  }

  @override
  String get am => 'ص';

  @override
  String get pm => 'م';

  @override
  String get authLoginTitle => 'تسجيل الدخول';

  @override
  String get authEmail => 'البريد الإلكتروني';

  @override
  String get authPassword => 'كلمة السر';

  @override
  String get authLoginButton => 'دخول';

  @override
  String get authForgotPassword => 'نسيت كلمة السر؟';

  @override
  String get authCreateAccount => 'إنشاء حساب جديد';

  @override
  String get authRegisterTitle => 'إنشاء حساب';

  @override
  String get authName => 'الاسم';

  @override
  String get authPhone => 'رقم الموبايل';

  @override
  String get authContinue => 'متابعة';

  @override
  String get authHaveAccount => 'لدي حساب بالفعل';

  @override
  String get authAccountTypeTitle => 'نوع الحساب';

  @override
  String get authAccountTypeNotice =>
      'اختيارك لنوع الحساب لا يمنحك أي صلاحيات. تحصل على الصلاحيات بإنشاء سنتر أو بإدخال كود دعوة.';

  @override
  String get authCreateAccountButton => 'إنشاء الحساب';

  @override
  String get accountTypeAdmin => 'مدير سنتر';

  @override
  String get accountTypeStaff => 'معلم أو مساعد';

  @override
  String get accountTypeGuardian => 'ولي أمر';

  @override
  String get accountTypeStudent => 'طالب';

  @override
  String get authVerifyTitle => 'تأكيد البريد الإلكتروني';

  @override
  String authVerifyBody(String email) {
    return 'أرسلنا رابط التأكيد إلى $email. افتح الرابط ثم اضغط \"تم التأكيد\".';
  }

  @override
  String get authVerifyCheck => 'تم التأكيد';

  @override
  String get authVerifyResend => 'إعادة إرسال الرابط';

  @override
  String get authVerifyNotYet =>
      'لم يتم تأكيد البريد بعد. افتح الرابط في الرسالة ثم حاول مرة أخرى.';

  @override
  String get authVerifySent => 'تم إرسال الرابط من جديد.';

  @override
  String get authForgotTitle => 'استعادة كلمة السر';

  @override
  String get authForgotBody =>
      'اكتب بريدك الإلكتروني وسنرسل لك رابطًا لإعادة تعيين كلمة السر.';

  @override
  String get authForgotSend => 'إرسال الرابط';

  @override
  String get authResetSent =>
      'لو كان البريد مسجلًا لدينا فسيصلك رابط إعادة التعيين خلال دقائق.';

  @override
  String get authBackToLogin => 'العودة لتسجيل الدخول';

  @override
  String get authSignOut => 'تسجيل الخروج';

  @override
  String get authSignOutTitle => 'تسجيل الخروج';

  @override
  String get authSignOutMessage => 'هل تريد تسجيل الخروج من حسابك؟';

  @override
  String get authSignOutFailed => 'تعذر تسجيل الخروج. حاول مرة أخرى.';

  @override
  String get authSignedInTitle => 'تم تسجيل الدخول';

  @override
  String authSignedInBody(String email) {
    return 'أنت مسجل الدخول بالحساب $email.';
  }

  @override
  String get centersCreateTitle => 'إنشاء مركز';

  @override
  String get centersCreateIntro =>
      'أنشئ مركزك لتبدأ بإدارة الطلاب والحضور. ستصبح مدير المركز تلقائيًا.';

  @override
  String get centersNameLabel => 'اسم المركز';

  @override
  String get centersYearLabel => 'السنة الدراسية';

  @override
  String get centersYearHint => 'مثال: 2026';

  @override
  String get centersCreateButton => 'إنشاء المركز';

  @override
  String get centersNameTooShort => 'اسم المركز قصير جدًا';

  @override
  String get centersNameTooLong => 'اسم المركز طويل جدًا (80 حرفًا كحد أقصى)';

  @override
  String get centersYearInvalid => 'اكتب السنة بأربعة أرقام بين 2000 و2100';

  @override
  String get centersLateInvalid => 'اكتب عدد دقائق صحيحًا من 0 إلى 180';

  @override
  String get centersSettingsTitle => 'إعدادات المركز';

  @override
  String get centersLateLabel => 'مدة التأخير (بالدقائق)';

  @override
  String get centersLateHelp =>
      'الطالب الذي يصل بعد هذه المدة من بداية الحصة يُسجَّل متأخرًا.';

  @override
  String get centersSaveButton => 'حفظ التعديلات';

  @override
  String get centersSaved => 'تم حفظ الإعدادات';

  @override
  String get centersAdminOnly => 'هذه الشاشة لمدير المركز فقط';

  @override
  String get centersEntryTitle => 'المركز';

  @override
  String get centersNoCenter => 'لم تنضم إلى مركز بعد';

  @override
  String get centersCreateCta => 'إنشاء مركز جديد';

  @override
  String get centersOpenSettings => 'إعدادات المركز';

  @override
  String get centersRoleAdmin => 'مدير المركز';

  @override
  String get centersRoleTeacher => 'معلم';

  @override
  String get centersRoleAssistant => 'مساعد';

  @override
  String centersRoleLine(String role) {
    return 'دورك: $role';
  }
}
