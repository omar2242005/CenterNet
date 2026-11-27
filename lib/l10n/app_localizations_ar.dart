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
  String get accountTypeTeacher => 'معلم';

  @override
  String get accountTypeAssistant => 'مساعد';

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
  String get staffInviteTeacherTitle => 'إضافة معلم';

  @override
  String get staffInviteAssistantTitle => 'إضافة مساعد';

  @override
  String get staffInviteTeacherName => 'اسم المعلم';

  @override
  String get staffInviteAssistantName => 'اسم المساعد';

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
  String get staffJoinCheckButton => 'متابعة';

  @override
  String get staffJoinConfirmTitle => 'راجع بيانات الدعوة';

  @override
  String staffJoinConfirmBody(String role) {
    return 'الكود ده هيضيفك للسنتر بصفة $role.';
  }

  @override
  String get staffJoinConfirmNote =>
      'هيظهر اسم السنتر بعد ما تنضم. لو الدور مش اللي المفروض يوصلك، اطلب كود تاني من مدير السنتر.';

  @override
  String get staffJoinConfirmButton => 'تأكيد الانضمام';

  @override
  String get staffJoinChangeCode => 'تعديل الكود';

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
  String get staffActionDisable => 'تعطيل';

  @override
  String get staffActionEnable => 'تفعيل';

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

  @override
  String get syncTitle => 'مزامنة المسحات';

  @override
  String get syncSignOutWarning =>
      'تسجيل الخروج قبل اكتمال المزامنة قد يؤدي إلى فقد بيانات حضور الطلاب.';

  @override
  String get syncNoConnection => 'لا يوجد اتصال بالإنترنت';

  @override
  String get syncNoConnectionHint =>
      'أعد الاتصال بالإنترنت ثم حاول المزامنة مرة أخرى.';

  @override
  String get syncInProgress => 'جارٍ رفع المسحات';

  @override
  String syncProgress(int completed, int total) {
    return 'تمت مزامنة $completed من $total';
  }

  @override
  String get syncDone => 'اكتملت المزامنة';

  @override
  String syncDoneCount(int count) {
    return 'تم رفع $count مسحة بنجاح.';
  }

  @override
  String syncNeedsAction(int count) {
    return '$count مسحة تحتاج إلى إجراء.';
  }

  @override
  String get syncRetryFailed => 'إعادة محاولة المسحات الفاشلة';

  @override
  String syncPending(int count) {
    return '$count مسحة بانتظار المزامنة';
  }

  @override
  String get syncStart => 'بدء المزامنة';

  @override
  String get syncEmpty => 'لا توجد مسحات بانتظار المزامنة';

  @override
  String get studentsListTitle => 'الطلاب';

  @override
  String get studentsEmpty => 'لم تتم إضافة طلاب بعد';

  @override
  String get studentsNoResults => 'لا يوجد طالب مطابق للبحث';

  @override
  String get studentsSearchHint => 'ابحث بالاسم أو الرقم أو الموبايل';

  @override
  String get studentsAddTitle => 'إضافة طالب';

  @override
  String get studentsEditTitle => 'تعديل بيانات الطالب';

  @override
  String get studentsShowArchived => 'إظهار المؤرشفين';

  @override
  String get studentsHideArchived => 'إخفاء المؤرشفين';

  @override
  String get studentFieldName => 'اسم الطالب';

  @override
  String get studentFieldPhone => 'رقم الموبايل';

  @override
  String get studentFieldGrade => 'الصف الدراسي (اختياري)';

  @override
  String get studentSave => 'حفظ';

  @override
  String studentNumber(int no) {
    return 'رقم الطالب: $no';
  }

  @override
  String get studentDetailTitle => 'ملف الطالب';

  @override
  String get studentEdit => 'تعديل البيانات';

  @override
  String get studentArchive => 'أرشفة الطالب';

  @override
  String get studentRestore => 'استرجاع الطالب';

  @override
  String get studentArchiveTitle => 'أرشفة الطالب';

  @override
  String studentArchiveMessage(String name) {
    return 'سيتم إخفاء $name من القوائم، ولن يُحذف أي من بياناته أو سجل حضوره. هل تريد المتابعة؟';
  }

  @override
  String get studentArchiveConfirm => 'أرشفة';

  @override
  String get studentArchivedBadge => 'مؤرشف';

  @override
  String get studentQrHint => 'يعرض الطالب هذا الرمز عند دخول الحصة';

  @override
  String studentPhoneLabel(String phone) {
    return 'الموبايل: $phone';
  }

  @override
  String studentGradeLabel(String grade) {
    return 'الصف: $grade';
  }

  @override
  String get homeAdminTitle => 'رئيسية الأدمن';

  @override
  String get adminNavHome => 'الرئيسية';

  @override
  String get adminHomeTitle => 'إدارة السنتر';

  @override
  String adminGreeting(String name) {
    return 'أهلاً، $name';
  }

  @override
  String get adminShortcuts => 'الاختصارات';

  @override
  String get homeTeacherTitle => 'رئيسية المعلم';

  @override
  String get homeAssistantTitle => 'رئيسية المساعد';

  @override
  String get homeStudentTitle => 'رئيسية الطالب';

  @override
  String get homeGuardianTitle => 'رئيسية ولي الأمر';

  @override
  String get homeComingSoon => 'هذه الشاشة قيد التطوير.';

  @override
  String get homeInactiveTitle => 'الحساب معطّل';

  @override
  String get homeInactiveBody =>
      'تم تعطيل حسابك من إدارة السنتر. تواصل مع الأدمن.';

  @override
  String get homeNoAccessTitle => 'لا توجد صلاحيات';

  @override
  String get homeNoAccessBody =>
      'حسابك غير مرتبط بسنتر بشكل صحيح. تواصل مع الأدمن أو سجّل الخروج.';

  @override
  String get examsTitle => 'الامتحانات';

  @override
  String get examsEmpty => 'لم تتم إضافة امتحانات بعد';

  @override
  String get examAddTitle => 'إنشاء امتحان';

  @override
  String get examFieldTitle => 'عنوان الامتحان';

  @override
  String get examFieldMax => 'الدرجة النهائية';

  @override
  String get examMaxInvalid => 'الدرجة النهائية لازم تكون رقمًا أكبر من صفر';

  @override
  String get examSave => 'حفظ الامتحان';

  @override
  String get examPublished => 'منشور';

  @override
  String get examDraft => 'مسودة';

  @override
  String get examPublish => 'نشر الدرجات';

  @override
  String get examUnpublish => 'إلغاء النشر';

  @override
  String examMaxLabel(String max) {
    return 'من $max';
  }

  @override
  String get scoresTitle => 'إدخال الدرجات';

  @override
  String get scoresEmpty => 'لا يوجد طلاب في المجموعة';

  @override
  String scoresRecorded(int done, int total) {
    return 'تم رصد $done من $total';
  }

  @override
  String get scoreStateScored => 'له درجة';

  @override
  String get scoreStateAbsent => 'غائب';

  @override
  String get scoreStateExcused => 'معفى';

  @override
  String get scoreNotYet => 'لسه';

  @override
  String get scoreFieldScore => 'الدرجة';

  @override
  String get scoreFieldComment => 'تعليق (اختياري)';

  @override
  String get scoreSave => 'حفظ';

  @override
  String get myGroupsTitle => 'مجموعاتي';

  @override
  String get myGroupsEmpty => 'لا توجد مجموعات مسندة إليك';

  @override
  String get teacherGroupsAdd => 'إنشاء مجموعة جديدة';

  @override
  String get groupExamsButton => 'الامتحانات والدرجات';

  @override
  String get groupNoStudents => 'لا يوجد طلاب في المجموعة';

  @override
  String groupStudentsSummary(int students, int sessions) {
    return '$students طالب · $sessions حصة سابقة';
  }

  @override
  String groupAbsencesBadge(int count) {
    return 'غياب $count';
  }

  @override
  String get groupsListTitle => 'المجموعات';

  @override
  String get groupsEmpty => 'لا توجد مجموعات بعد';

  @override
  String get groupsNoResults => 'لا توجد مجموعة مطابقة للبحث';

  @override
  String get groupsSearchHint => 'ابحث بالاسم أو المادة أو الصف';

  @override
  String get groupsShowArchived => 'عرض المؤرشفة';

  @override
  String get groupsHideArchived => 'إخفاء المؤرشفة';

  @override
  String get groupArchivedBadge => 'مؤرشفة';

  @override
  String get groupArchiveAction => 'أرشفة';

  @override
  String get groupArchiveTitle => 'أرشفة المجموعة؟';

  @override
  String groupArchiveMessage(String name) {
    return 'سيتم إخفاء $name من القوائم، ولن تُحذف بياناتها أو حصصها. هل تريد المتابعة؟';
  }

  @override
  String get groupArchiveConfirm => 'أرشفة';

  @override
  String get groupsAddTitle => 'إضافة مجموعة';

  @override
  String get groupEditTitle => 'تعديل المجموعة';

  @override
  String get groupFieldName => 'اسم المجموعة';

  @override
  String get groupFieldSubject => 'المادة (اختياري)';

  @override
  String get groupFieldGrade => 'الصف (اختياري)';

  @override
  String get groupFieldRoom => 'القاعة (اختياري)';

  @override
  String get groupFieldTeacher => 'المعلم';

  @override
  String get groupFieldAssistants => 'المساعدون (اختياري)';

  @override
  String get groupFieldCapacity => 'السعة القصوى (اختياري)';

  @override
  String get groupFieldFee => 'السعر الشهري بالجنيه (اختياري)';

  @override
  String get groupSlotsTitle => 'المواعيد الأسبوعية';

  @override
  String get groupSlotDay => 'اليوم';

  @override
  String get groupSlotDuration => 'المدة بالدقائق';

  @override
  String get groupAddSlot => 'إضافة ميعاد';

  @override
  String get groupSlotRemove => 'حذف الميعاد';

  @override
  String get groupNoTeachers =>
      'لا يوجد معلمون نشطون. أضفهم من شاشة الفريق أولًا.';

  @override
  String get groupInvalidCapacity => 'اكتب رقمًا صحيحًا (1 أو أكثر)';

  @override
  String get groupInvalidFee => 'اكتب سعرًا صحيحًا (0 أو أكثر)';

  @override
  String get groupInvalidDuration => 'المدة لازم تكون من 1 لـ 480 دقيقة';

  @override
  String get groupStudentsMenu => 'تسجيل الطلاب';

  @override
  String groupEnrolledCount(int count) {
    return '$count طالب مسجّل';
  }

  @override
  String get groupFullBadge => 'مكتملة العدد';

  @override
  String get groupStudentsSearchHint => 'ابحث بالاسم أو الرقم';

  @override
  String get groupStudentsEmpty => 'لا يوجد طلاب لعرضهم';

  @override
  String get groupSessionsMenu => 'الحصص';

  @override
  String get sessionsGenerateButton => 'إنشاء حصص الأسابيع الجاية';

  @override
  String sessionsGenerateResult(int created, int skipped) {
    return 'اتكتبت $created حصة جديدة ($skipped موجودة بالفعل)';
  }

  @override
  String get sessionsEmpty =>
      'لا توجد حصص قادمة. أنشئ حصص الأسابيع الجاية من الزر بالأعلى.';

  @override
  String get sessionScheduledBadge => 'مجدولة';

  @override
  String get sessionCancelledBadge => 'ملغاة';

  @override
  String get sessionCancelAction => 'إلغاء الحصة';

  @override
  String get sessionCancelTitle => 'إلغاء الحصة؟';

  @override
  String sessionCancelMessage(String date) {
    return 'حصة يوم $date هتتلغي ولن تُعاد تلقائيًا. هل تريد المتابعة؟';
  }

  @override
  String get sessionDeleteAction => 'مسح الحصة نهائيًا';

  @override
  String get sessionDeleteTitle => 'مسح الحصة نهائيًا؟';

  @override
  String sessionDeleteMessage(String date) {
    return 'حصة يوم $date الملغاة هتتمسح من التطبيق ومن قاعدة البيانات ومش هترجع. هل تريد المتابعة؟';
  }

  @override
  String get sessionDeleteConfirm => 'مسح نهائيًا';

  @override
  String get sessionDeleted => 'تم مسح الحصة.';

  @override
  String get sessionCancelConfirm => 'إلغاء الحصة';

  @override
  String get myAccountTitle => 'حسابي';

  @override
  String get myAccountName => 'الاسم';

  @override
  String get myAccountEmail => 'البريد الإلكتروني';

  @override
  String get myAccountPhone => 'الموبايل';

  @override
  String get myAccountType => 'نوع الحساب';

  @override
  String get myAccountLoadError => 'تعذر تحميل بيانات الحساب';

  @override
  String get accountDeleteAction => 'حذف الحساب نهائيًا';

  @override
  String get accountDeleteTitle => 'حذف الحساب نهائيًا';

  @override
  String get accountDeleteMessage =>
      'هيتحذف حسابك وبياناته نهائيًا ومش هينفع ترجع. اكتب كلمة السر للتأكيد.';

  @override
  String get accountDeleteConfirm => 'حذف نهائي';

  @override
  String get accountDeleteFailed => 'تعذر حذف الحساب. حاول مرة أخرى.';

  @override
  String groupRoomConflict(String group, String day, String start, String end) {
    return 'القاعة دي محجوزة لمجموعة «$group» يوم $day من $start لـ $end';
  }

  @override
  String get groupUnarchiveAction => 'استرجاع';

  @override
  String get groupDeleteAction => 'حذف نهائي';

  @override
  String get groupDeleteTitle => 'حذف نهائي للمجموعة؟';

  @override
  String groupDeleteMessage(String name) {
    return '«$name» هتتحذف نهائيًا ومش هينفع ترجع. الحذف ممكن بس لمجموعة ملهاش حصص (مجدولة أو ملغية) ولا طلاب مسجلين — الأرشفة أأمن.';
  }

  @override
  String get groupDeleteConfirm => 'حذف نهائي';

  @override
  String get linkEnterTitle => 'ربط الحساب بالطالب';

  @override
  String get linkStudentIntro =>
      'اكتب كود الربط اللي استلمته من السنتر عشان تربط حسابك بملفك كطالب.';

  @override
  String get linkGuardianIntro =>
      'اكتب كود الربط اللي استلمته من السنتر عشان تتابع حضور ودرجات ابنك أو ابنتك.';

  @override
  String get linkCodeLabel => 'كود الربط';

  @override
  String get linkCodeHint => 'مثال: AB3CD4EF';

  @override
  String get linkConsentTitle => 'الموافقة على الربط';

  @override
  String get linkConsentStudent =>
      'بربط حسابك سيظهر لك جدولك وحضورك ونتايجك، ويقدر السنتر يربط بياناتك الدراسية بحسابك. تقدر تفك الربط في أي وقت.';

  @override
  String linkConsentGuardian(int max) {
    return 'بربط حسابك أنت توافق على عرض البيانات الدراسية للطالب لك (الحضور والدرجات والجدول). الحد الأقصى $max أولياء أمور لكل طالب، وتقدر تفك الربط في أي وقت.';
  }

  @override
  String get linkConsentAgree => 'أوافق';

  @override
  String get linkSubmit => 'ربط';

  @override
  String get linkSuccess => 'تم الربط بنجاح';

  @override
  String get linkUnlink => 'فك الربط';

  @override
  String get linkUnlinkTitle => 'فك الربط';

  @override
  String linkUnlinkMessage(String name) {
    return 'هل تريد فك ربط حسابك بالطالب $name؟ لن تتمكن من رؤية بياناته بعد ذلك.';
  }

  @override
  String get linkIssueStudentCode => 'كود ربط الطالب';

  @override
  String get linkIssueGuardianCode => 'كود ربط ولي الأمر';

  @override
  String get linkIssueRelationTitle => 'صلة القرابة';

  @override
  String linkIssueExpires(String date) {
    return 'صالح حتى $date';
  }

  @override
  String get linkIssueCopy => 'نسخ';

  @override
  String get linkIssueCopied => 'تم نسخ الكود';

  @override
  String get linkIssueClose => 'إغلاق';

  @override
  String get relationFather => 'أب';

  @override
  String get relationMother => 'أم';

  @override
  String get relationBrother => 'أخ';

  @override
  String get relationSister => 'أخت';

  @override
  String get relationOther => 'أخرى';

  @override
  String get areaNotLinked => 'حسابك غير مربوط بطالب بعد.';

  @override
  String get areaLinkStudentButton => 'ربط حسابي بكود الطالب';

  @override
  String get areaScheduleTitle => 'الجدول الأسبوعي';

  @override
  String get areaAttendanceTitle => 'سجل الحضور';

  @override
  String get areaResultsTitle => 'النتائج';

  @override
  String get areaScheduleEmpty => 'لا توجد مواعيد مسجلة';

  @override
  String get areaAttendanceEmpty => 'لا يوجد حضور مسجل بعد';

  @override
  String get areaResultsEmpty => 'لا توجد نتائج منشورة بعد';

  @override
  String weekdayName(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      'd1': 'الاثنين',
      'd2': 'الثلاثاء',
      'd3': 'الأربعاء',
      'd4': 'الخميس',
      'd5': 'الجمعة',
      'd6': 'السبت',
      'other': 'الأحد',
    });
    return '$_temp0';
  }

  @override
  String scheduleRoom(String room) {
    return 'القاعة: $room';
  }

  @override
  String scheduleTimeRange(String start, String end) {
    return '$start - $end';
  }

  @override
  String get attendanceStatusPresent => 'حاضر';

  @override
  String get attendanceStatusLate => 'متأخر';

  @override
  String get attendanceStatusExcused => 'غائب بعذر';

  @override
  String attendanceSummary(int attended, int total) {
    return 'حضر $attended من $total حصة';
  }

  @override
  String attendanceDateTime(String date, String time) {
    return '$date - $time';
  }

  @override
  String resultsAverage(String percent) {
    return 'المتوسط العام: $percent%';
  }

  @override
  String resultsScoreOf(String score, String max) {
    return '$score من $max';
  }

  @override
  String get resultsAbsent => 'غائب';

  @override
  String get resultsExcused => 'معفى';

  @override
  String get resultsPending => 'لم تُرصد بعد';

  @override
  String get guardianNoChildren => 'لم تربط أي طالب بعد.';

  @override
  String get guardianLinkChild => 'ربط طالب بكود';

  @override
  String get guardianAddChild => 'ربط طالب آخر';

  @override
  String guardianRelation(String relation) {
    return 'صلتك: $relation';
  }

  @override
  String get guardianChooseChild => 'اختر الطالب';

  @override
  String get appName => 'CenterNet';

  @override
  String get assistantHomeTitle => 'لوحة المساعد';

  @override
  String assistantGreeting(String name) {
    return 'أهلاً، $name';
  }

  @override
  String get assistantOnline => 'متصل بالإنترنت';

  @override
  String get assistantOffline => 'غير متصل بالإنترنت';

  @override
  String assistantTodayCount(int count) {
    return 'عندك $count حصص النهارده';
  }

  @override
  String get assistantNoSessionsToday => 'مفيش حصص النهارده';

  @override
  String get assistantCurrentSession => 'الحصة الجارية دلوقتي';

  @override
  String get assistantNoCurrentSession => 'مفيش حصة جارية حاليًا';

  @override
  String get assistantStartScanning => 'ابدأ المسح';

  @override
  String get assistantSessionsTitle => 'حصص النهارده';

  @override
  String get assistantSessionDetailsTitle => 'تفاصيل الحصة';

  @override
  String get sessionStatusCurrent => 'جارية';

  @override
  String get sessionStatusUpcoming => 'قادمة';

  @override
  String get sessionStatusEnded => 'انتهت';

  @override
  String get sessionStatusCancelled => 'ملغاة';

  @override
  String get sessionGroupLabel => 'المجموعة';

  @override
  String get sessionTimeLabel => 'الوقت';

  @override
  String get sessionRoomLabel => 'القاعة';

  @override
  String get sessionNoRoom => 'غير محددة';

  @override
  String get sessionScanStudent => 'مسح كود الطالب';

  @override
  String sessionAttendanceSummary(int attended, int total) {
    return 'حضر $attended من $total طالب';
  }

  @override
  String sessionAttendanceWaiting(int count) {
    return '$count بانتظار المزامنة';
  }

  @override
  String get sessionAttendanceNotYetLabel => 'لسه ما حضروش';

  @override
  String sessionAttendanceNotYet(int count) {
    return '$count طالب';
  }

  @override
  String get sessionLastScansTitle => 'آخر عمليات المسح';

  @override
  String get sessionAttendanceListButton => 'قائمة الحضور';

  @override
  String get assistantAttendanceTitle => 'قائمة الحضور';

  @override
  String get assistantAttendanceNoSessions => 'مفيش حصص النهارده';

  @override
  String get attendanceSearchHint => 'ابحث بالاسم أو الكود';

  @override
  String get attendanceFilterAll => 'الكل';

  @override
  String get attendanceFilterWaiting => 'بانتظار المزامنة';

  @override
  String get attendanceFilterFailed => 'فشلت المزامنة';

  @override
  String get attendanceEmpty => 'مفيش حضور مسجل في الحصة دي لحد دلوقتي';

  @override
  String get attendanceNoResults => 'لا توجد نتائج مطابقة للبحث';

  @override
  String get attendanceSyncSynced => 'تمت المزامنة';

  @override
  String get attendanceSyncWaiting => 'بانتظار المزامنة';

  @override
  String get attendanceSyncFailed => 'فشلت المزامنة';

  @override
  String get attendanceUnknownStudent => 'طالب مش في المجموعة';

  @override
  String attendanceStudentCode(int code) {
    return 'كود $code';
  }

  @override
  String get assistantNavHome => 'الرئيسية';

  @override
  String get assistantNavSessions => 'الحصص';

  @override
  String get assistantNavAttendance => 'الحضور';

  @override
  String get assistantNavSync => 'المزامنة';

  @override
  String get teacherNavHome => 'الرئيسية';

  @override
  String teacherGreeting(String name) {
    return 'أهلاً، $name';
  }

  @override
  String get teacherActiveGroups => 'مجموعاتك النشطة';

  @override
  String teacherAcademicYear(String from, String to) {
    return 'العام الدراسي $from – $to';
  }

  @override
  String get teacherGroupUnit => 'مجموعة';

  @override
  String teacherStudentsCount(int count) {
    return '$count طالبًا';
  }

  @override
  String teacherSubjects(String subjects) {
    return 'المواد: $subjects';
  }

  @override
  String get teacherNextSession => 'الحصة القادمة';

  @override
  String get teacherNoNextSession => 'مفيش حصص قادمة في جدولك دلوقتي.';

  @override
  String get teacherToday => 'اليوم';

  @override
  String get teacherTomorrow => 'غدًا';

  @override
  String get teacherViewMyGroups => 'عرض مجموعاتي';

  @override
  String get teacherNavExams => 'الامتحانات';

  @override
  String get teacherExamsTitle => 'قائمة الاختبارات';

  @override
  String teacherExamsOfSubject(String subject) {
    return 'اختبارات $subject';
  }

  @override
  String get teacherExamsOther => 'اختبارات أخرى';

  @override
  String get teacherExamsEmpty => 'لسه مفيش اختبارات. أنشئ أول اختبار.';

  @override
  String get teacherExamCreateButton => 'إنشاء اختبار جديد';

  @override
  String get teacherExamStatusGraded => 'تم الرصد';

  @override
  String get teacherExamStatusInProgress => 'قيد الرصد';

  @override
  String get teacherExamStatusUpcoming => 'قادم';

  @override
  String teacherExamSummaryLine(int recorded, int total, String max) {
    return '$recorded من $total درجة مسجلة · من $max';
  }

  @override
  String get teacherExamFormTitle => 'إنشاء اختبار';

  @override
  String get teacherExamFieldName => 'اسم الاختبار';

  @override
  String get teacherExamFieldGroup => 'المجموعة';

  @override
  String get teacherExamFieldDate => 'تاريخ الاختبار';

  @override
  String get teacherExamFieldStart => 'وقت البداية';

  @override
  String get teacherExamGroupRequired => 'اختر المجموعة';

  @override
  String get teacherExamNoGroups => 'مفيش مجموعات نشطة تقدر تعمل فيها اختبار.';

  @override
  String get teacherExamDetailsTitle => 'تفاصيل الاختبار';

  @override
  String get teacherExamAverage => 'المتوسط';

  @override
  String teacherExamRecordedCount(int done, int total) {
    return 'تم رصد $done من $total';
  }

  @override
  String get teacherExamStudentScores => 'درجات الطلاب';

  @override
  String get teacherExamScoreRecorded => 'تم رصد الدرجة';

  @override
  String get teacherExamNotRecorded => 'لم تُرصد بعد';

  @override
  String get teacherExamRecordButton => 'رصد الدرجات';

  @override
  String teacherStudentNo(String no) {
    return 'رقم الطالب: $no';
  }

  @override
  String get teacherScoresTitle => 'رصد الدرجات';

  @override
  String get teacherScoresSearchHint => 'الاسم أو رقم الطالب';

  @override
  String get teacherScoresSaveAll => 'حفظ الدرجات';

  @override
  String get teacherScoresNote =>
      'الخانة الفاضية لا تُحسب صفرًا. أي درجة أكبر من الدرجة النهائية تُرفض.';

  @override
  String teacherScoresFinal(String max) {
    return 'الدرجة النهائية: $max';
  }

  @override
  String teacherScoresSaved(int count) {
    return 'تم حفظ $count درجة';
  }

  @override
  String get teacherScoresNothing => 'مفيش درجات جديدة للحفظ';

  @override
  String teacherScoresSomeFailed(int count) {
    return 'تعذر حفظ $count درجة. راجع الخانات الحمراء.';
  }

  @override
  String get teacherScoresNoMatch => 'مفيش طالب بالاسم أو الرقم ده';

  @override
  String get linkRequestOpen => 'طلب الربط من السنتر';

  @override
  String get linkRequestTitle => 'طلب ربط';

  @override
  String get linkRequestIntro =>
      'أرسل طلبًا للسنتر برقم الطالب. بعد موافقة الأدمن تكمل الربط من هنا.';

  @override
  String get linkRequestCenterCode => 'كود السنتر (من الأدمن)';

  @override
  String get linkRequestStudentNo => 'رقم الطالب';

  @override
  String get linkRequestSend => 'إرسال الطلب';

  @override
  String get linkRequestPending => 'تم إرسال طلبك وبانتظار موافقة الأدمن.';

  @override
  String get linkRequestApproved => 'تمت الموافقة على طلبك. أكمل الربط الآن.';

  @override
  String get linkRequestRejected =>
      'تم رفض الطلب. تأكد من البيانات وحاول مرة أخرى.';

  @override
  String get linkRequestRefresh => 'تحديث الحالة';

  @override
  String get linkRequestComplete => 'إكمال الربط';

  @override
  String get linkRequestRetry => 'طلب جديد';

  @override
  String get linkRequestsTitle => 'طلبات الربط';

  @override
  String get linkRequestsEmpty => 'لا توجد طلبات معلقة';

  @override
  String get linkRequestApprove => 'موافقة';

  @override
  String get linkRequestReject => 'رفض';

  @override
  String linkRequestRelation(String relation) {
    return 'الصلة: $relation';
  }

  @override
  String adminCenterCode(String code) {
    return 'كود السنتر: $code';
  }

  @override
  String get childNavHome => 'الرئيسية';

  @override
  String get childNavSchedule => 'الجدول';

  @override
  String get studentNavGrades => 'درجاتي';

  @override
  String get guardianNavGrades => 'الدرجات';

  @override
  String get guardianNavProfile => 'ملف الابن';

  @override
  String get childNextSession => 'الحصة القادمة';

  @override
  String get childNoNextSession => 'لا توجد حصص قادمة';

  @override
  String get childLatestResult => 'آخر نتيجة';

  @override
  String get childOverviewTitle => 'متابعة الشهر';

  @override
  String get childMonthAttendance => 'الحضور هذا الشهر';

  @override
  String get childMonthResults => 'نتائج هذا الشهر';

  @override
  String get childProfileGroups => 'المجموعات';

  @override
  String get childProfileNoGroups => 'غير مسجل في أي مجموعة';

  @override
  String get updatesBell => 'آخر التحديثات';

  @override
  String get updatesBellGuardian => 'تحديثات الأبناء';

  @override
  String get updatesStudentTitle => 'آخر التحديثات';

  @override
  String get updatesGuardianTitle => 'تحديثات الأبناء';

  @override
  String get updatesEmpty => 'لا توجد تحديثات';

  @override
  String get updatesGrades => 'أحدث الدرجات';

  @override
  String get updatesSessions => 'حصص اليوم والقادمة';

  @override
  String get updatesAttendance => 'آخر حضور';

  @override
  String get updatesAbsence => 'آخر غياب';

  @override
  String get updatesToday => 'اليوم';

  @override
  String get filterAll => 'الكل';

  @override
  String get filterThisWeek => 'هذا الأسبوع';

  @override
  String get filterNextWeek => 'الأسبوع القادم';

  @override
  String get filterPresent => 'حضور';

  @override
  String get filterAbsent => 'غياب';

  @override
  String get attendanceStatusAbsent => 'غائب';

  @override
  String get examDetailsTitle => 'تفاصيل الامتحان';

  @override
  String get examYourScore => 'الدرجة';

  @override
  String examMaxScore(String max) {
    return 'الدرجة النهائية: $max';
  }

  @override
  String get examTeacherComment => 'تعليق المعلم';

  @override
  String get examNoComment => 'لا يوجد تعليق';

  @override
  String get editContactTitle => 'تعديل بيانات التواصل';

  @override
  String get editContactAction => 'تعديل بيانات التواصل';

  @override
  String get paymentsSectionTitle => 'حساب الرسوم';

  @override
  String get paymentsEmpty => 'مفيش دفعات مسجلة لسه.';

  @override
  String get paymentsRecord => 'تسجيل دفعة';

  @override
  String get paymentsGroupLabel => 'المجموعة';

  @override
  String get paymentsMonthLabel => 'الشهر';

  @override
  String get paymentsAmountLabel => 'المبلغ';

  @override
  String get paymentsNoteLabel => 'ملاحظة (اختياري)';

  @override
  String get paymentsSave => 'حفظ الدفعة';

  @override
  String get paymentsInvalidAmount => 'اختار المجموعة واكتب مبلغ أكبر من صفر.';

  @override
  String get paymentsStatusPaid => 'مدفوعة';

  @override
  String get paymentsStatusCancelled => 'ملغاة';

  @override
  String get paymentsCancelAction => 'إلغاء';

  @override
  String get paymentsCancelTitle => 'إلغاء الدفعة';

  @override
  String get paymentsCancelReasonLabel => 'سبب الإلغاء';

  @override
  String get paymentsCancelReasonRequired => 'سبب الإلغاء مطلوب.';

  @override
  String get paymentsCancelConfirm => 'تأكيد الإلغاء';

  @override
  String get paymentsBack => 'رجوع';

  @override
  String get paymentsNoGroups => 'الطالب مش مسجل في أي مجموعة.';

  @override
  String paymentsCancelledReason(String reason) {
    return 'السبب: $reason';
  }

  @override
  String get paymentsScreenTitle => 'المدفوعات';

  @override
  String get paymentsSearchHint => 'ابحث باسم الطالب';

  @override
  String get paymentsFilterAll => 'الكل';

  @override
  String get paymentsFilterPaid => 'مدفوع';

  @override
  String get paymentsFilterUnpaid => 'غير مدفوع';

  @override
  String get paymentsAllGroups => 'كل المجموعات';

  @override
  String get paymentsStatusUnknown => 'السداد غير معروف';

  @override
  String get paymentsEmptyMonth => 'مفيش طلاب مسجلين في مجموعات نشطة.';

  @override
  String get paymentsNoResults => 'مفيش نتايج مطابقة للبحث أو الفلاتر.';

  @override
  String paymentsPaidOn(String date) {
    return 'اتدفع $date';
  }
}
