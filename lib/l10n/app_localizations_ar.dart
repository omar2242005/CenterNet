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
  String get centerCreateTitle => 'إنشاء سنتر';

  @override
  String get centerCreateButton => 'إنشاء السنتر';

  @override
  String get centerSettingsTitle => 'إعدادات السنتر';

  @override
  String get centerName => 'اسم السنتر';

  @override
  String get centerYear => 'السنة الدراسية';

  @override
  String get centerLateAfter => 'مدة التأخير (بالدقائق)';

  @override
  String get centerSave => 'حفظ';

  @override
  String get centerSaved => 'تم حفظ الإعدادات.';

  @override
  String get centerNone => 'ليس لديك سنتر بعد.';

  @override
  String get centerYearInvalid => 'السنة غير صالحة';

  @override
  String get centerLateInvalid => 'المدة لازم تكون من 0 إلى 180 دقيقة';

  @override
  String get staffInviteTitle => 'إضافة موظف';

  @override
  String get staffInviteName => 'اسم الموظف';

  @override
  String get staffInviteRole => 'الدور';

  @override
  String get staffRoleTeacher => 'معلم';

  @override
  String get staffRoleAssistant => 'مساعد';

  @override
  String get staffInvitePhone =>
      'موبايل الموظف (اختياري، لإرسال الكود عبر واتساب)';

  @override
  String get staffInviteCreate => 'إنشاء الكود';

  @override
  String get staffInviteReadyTitle => 'تم إنشاء كود الدعوة';

  @override
  String get staffInviteCodeLabel => 'كود الدعوة';

  @override
  String staffInviteValidUntil(String date) {
    return 'صالح حتى $date';
  }

  @override
  String get staffInviteNote =>
      'الكود يُستخدم مرة واحدة فقط. بعد قبوله يصبح الموظف عضوًا في السنتر بالدور المحدد.';

  @override
  String get staffInviteCopy => 'نسخ الكود';

  @override
  String get staffInviteCopied => 'تم نسخ الكود';

  @override
  String get staffInviteWhatsapp => 'إرسال عبر واتساب';

  @override
  String get staffInviteAnother => 'إضافة موظف آخر';

  @override
  String staffInviteMessage(
    String name,
    String center,
    String role,
    String code,
  ) {
    return 'مرحبًا $name، تمت دعوتك للانضمام إلى $center بصفة $role على تطبيق CenterNet.\nكود الدعوة: $code\nالكود صالح لمدة 7 أيام ويُستخدم مرة واحدة. سجّل حسابك في التطبيق ثم أدخل الكود.';
  }

  @override
  String get staffJoinEntry => 'لدي كود دعوة';

  @override
  String get staffJoinTitle => 'الانضمام بكود دعوة';

  @override
  String get staffJoinIntro => 'اكتب كود الدعوة اللي وصلك من مدير السنتر.';

  @override
  String get staffJoinCodeLabel => 'كود الدعوة';

  @override
  String get staffJoinCodeInvalid =>
      'الكود يتكون من 8 رموز (حروف إنجليزية وأرقام)';

  @override
  String get staffJoinButton => 'انضمام';

  @override
  String get staffJoinSuccessTitle => 'تم الانضمام بنجاح';

  @override
  String staffJoinSuccessBody(String center, String role) {
    return 'أصبحت عضوًا في $center بصفة $role.';
  }

  @override
  String get staffJoinContinue => 'متابعة';

  @override
  String get staffListTitle => 'الموظفون';

  @override
  String get staffListEmpty => 'لا يوجد موظفون';

  @override
  String get staffRoleAdmin => 'مدير';

  @override
  String get staffStatusActive => 'نشط';

  @override
  String get staffStatusDisabled => 'معطّل';

  @override
  String get staffMenuTooltip => 'خيارات الموظف';

  @override
  String staffActionChangeRoleTo(String role) {
    return 'تغيير الدور إلى $role';
  }

  @override
  String get staffActionDisable => 'تعطيل';

  @override
  String get staffActionEnable => 'تفعيل';

  @override
  String get staffChangeRoleTitle => 'تغيير دور الموظف';

  @override
  String staffChangeRoleMessage(String name, String role) {
    return 'هل تريد تغيير دور $name إلى $role؟';
  }

  @override
  String get staffChangeRoleConfirm => 'تغيير';

  @override
  String get staffDisableTitle => 'تعطيل الموظف';

  @override
  String staffDisableMessage(String name) {
    return '$name لن يتمكن من استخدام السنتر حتى تعيد تفعيله. هل تريد المتابعة؟';
  }

  @override
  String get staffEnableTitle => 'تفعيل الموظف';

  @override
  String staffEnableMessage(String name) {
    return 'هل تريد إعادة تفعيل $name؟';
  }

  @override
  String get scanTitle => 'مسح الحضور';

  @override
  String get scanTitleDemo => 'مسح الحضور (تجريبي)';

  @override
  String get scanHint => 'وجّه الكاميرا ناحية رمز الـ QR الخاص بالطالب';

  @override
  String get scanWaiting => 'في انتظار مسح أول رمز';

  @override
  String get scanTorch => 'الفلاش';

  @override
  String get scanSwitchCamera => 'تبديل الكاميرا';

  @override
  String get scanPermissionDenied =>
      'نحتاج إذن الكاميرا لمسح الحضور. فعّله من إعدادات الجهاز ثم ارجع للشاشة.';

  @override
  String get scanCameraUnsupported => 'الكاميرا غير متاحة على هذا الجهاز';

  @override
  String get scanCameraError => 'تعذّر تشغيل الكاميرا';

  @override
  String scanRecordedPresent(String student) {
    return 'تم تسجيل حضور $student';
  }

  @override
  String scanRecordedLate(String student) {
    return 'تم تسجيل $student متأخرًا';
  }

  @override
  String scanAlreadyRegistered(String student) {
    return '$student مسجّل بالفعل';
  }

  @override
  String scanVoidedBefore(String student) {
    return '$student ملغى سابقًا — راجع المصحح';
  }

  @override
  String scanNotRegistered(String student) {
    return '$student غير مسجّل في مجموعة هذه الحصة';
  }

  @override
  String get scanOtherCenter => 'هذا الرمز تابع لسنتر آخر';

  @override
  String get scanInvalidCode => 'رمز غير صالح';

  @override
  String get scanStorageError => 'تعذّر حفظ المسحة على الجهاز، حاول مرة أخرى';

  @override
  String get scanLocalListCorrupt => 'قائمة المسحات المحلية تالفة، المسح متوقف';

  @override
  String scanCountPresent(int count) {
    return 'حاضر $count';
  }

  @override
  String scanCountLate(int count) {
    return 'متأخر $count';
  }

  @override
  String scanCountRejected(int count) {
    return 'مرفوض $count';
  }

  @override
  String scanPendingCount(int count) {
    return '$count بانتظار المزامنة';
  }

  @override
  String get scanDemoBanner =>
      'نموذج أولي: بيانات تجريبية، والمسحات لا تُحفظ على الجهاز';

  @override
  String get scanManualTitle => 'إدخال يدوي للتجربة';

  @override
  String get scanManualHint => 'مثال: demo:s1';

  @override
  String get scanManualSubmit => 'تجربة الرمز';
}
