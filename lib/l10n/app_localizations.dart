import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('ar')];

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحميل'**
  String get loading;

  /// No description provided for @emptyDefault.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بيانات لعرضها'**
  String get emptyDefault;

  /// No description provided for @confirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @searchHint.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get searchHint;

  /// No description provided for @clearSearch.
  ///
  /// In ar, this message translates to:
  /// **'مسح البحث'**
  String get clearSearch;

  /// No description provided for @showPassword.
  ///
  /// In ar, this message translates to:
  /// **'إظهار كلمة السر'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء كلمة السر'**
  String get hidePassword;

  /// No description provided for @qrSemantics.
  ///
  /// In ar, this message translates to:
  /// **'رمز QR الخاص بالطالب'**
  String get qrSemantics;

  /// No description provided for @validationRequired.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحقل مطلوب'**
  String get validationRequired;

  /// No description provided for @validationNameTooShort.
  ///
  /// In ar, this message translates to:
  /// **'الاسم قصير جدًا'**
  String get validationNameTooShort;

  /// No description provided for @validationNameTooLong.
  ///
  /// In ar, this message translates to:
  /// **'الاسم طويل جدًا'**
  String get validationNameTooLong;

  /// No description provided for @validationNameInvalid.
  ///
  /// In ar, this message translates to:
  /// **'الاسم يجب أن يحتوي على حروف فقط'**
  String get validationNameInvalid;

  /// No description provided for @validationMobileInvalid.
  ///
  /// In ar, this message translates to:
  /// **'رقم الموبايل غير صالح، مثال: 01012345678'**
  String get validationMobileInvalid;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني غير صالح'**
  String get validationEmailInvalid;

  /// No description provided for @validationPasswordTooShort.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السر يجب ألا تقل عن 8 أحرف'**
  String get validationPasswordTooShort;

  /// No description provided for @validationScoreInvalid.
  ///
  /// In ar, this message translates to:
  /// **'الدرجة غير صالحة'**
  String get validationScoreInvalid;

  /// No description provided for @validationScoreOutOfRange.
  ///
  /// In ar, this message translates to:
  /// **'الدرجة خارج النطاق المسموح'**
  String get validationScoreOutOfRange;

  /// No description provided for @validationScoreStep.
  ///
  /// In ar, this message translates to:
  /// **'الدرجة تُكتب بخطوة 0.5 فقط'**
  String get validationScoreStep;

  /// No description provided for @currencyEgp.
  ///
  /// In ar, this message translates to:
  /// **'{amount} ج.م'**
  String currencyEgp(String amount);

  /// No description provided for @dateFull.
  ///
  /// In ar, this message translates to:
  /// **'{day} {month} {year}'**
  String dateFull(int day, String month, int year);

  /// اسم الشهر. القيمة m1..m12، وأي قيمة تانية بترجّع ديسمبر.
  ///
  /// In ar, this message translates to:
  /// **'{month, select, m1{يناير} m2{فبراير} m3{مارس} m4{أبريل} m5{مايو} m6{يونيو} m7{يوليو} m8{أغسطس} m9{سبتمبر} m10{أكتوبر} m11{نوفمبر} other{ديسمبر}}'**
  String monthName(String month);

  /// No description provided for @timeFormat.
  ///
  /// In ar, this message translates to:
  /// **'{hour}:{minute} {period}'**
  String timeFormat(String hour, String minute, String period);

  /// No description provided for @am.
  ///
  /// In ar, this message translates to:
  /// **'ص'**
  String get am;

  /// No description provided for @pm.
  ///
  /// In ar, this message translates to:
  /// **'م'**
  String get pm;

  /// No description provided for @authLoginTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get authLoginTitle;

  /// No description provided for @authEmail.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السر'**
  String get authPassword;

  /// No description provided for @authLoginButton.
  ///
  /// In ar, this message translates to:
  /// **'دخول'**
  String get authLoginButton;

  /// No description provided for @authForgotPassword.
  ///
  /// In ar, this message translates to:
  /// **'نسيت كلمة السر؟'**
  String get authForgotPassword;

  /// No description provided for @authCreateAccount.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب جديد'**
  String get authCreateAccount;

  /// No description provided for @authRegisterTitle.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get authRegisterTitle;

  /// No description provided for @authName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get authName;

  /// No description provided for @authPhone.
  ///
  /// In ar, this message translates to:
  /// **'رقم الموبايل'**
  String get authPhone;

  /// No description provided for @authContinue.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get authContinue;

  /// No description provided for @authHaveAccount.
  ///
  /// In ar, this message translates to:
  /// **'لدي حساب بالفعل'**
  String get authHaveAccount;

  /// No description provided for @authAccountTypeTitle.
  ///
  /// In ar, this message translates to:
  /// **'نوع الحساب'**
  String get authAccountTypeTitle;

  /// No description provided for @authAccountTypeNotice.
  ///
  /// In ar, this message translates to:
  /// **'اختيارك لنوع الحساب لا يمنحك أي صلاحيات. تحصل على الصلاحيات بإنشاء سنتر أو بإدخال كود دعوة.'**
  String get authAccountTypeNotice;

  /// No description provided for @authCreateAccountButton.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء الحساب'**
  String get authCreateAccountButton;

  /// No description provided for @accountTypeAdmin.
  ///
  /// In ar, this message translates to:
  /// **'مدير سنتر'**
  String get accountTypeAdmin;

  /// No description provided for @accountTypeStaff.
  ///
  /// In ar, this message translates to:
  /// **'معلم أو مساعد'**
  String get accountTypeStaff;

  /// No description provided for @accountTypeGuardian.
  ///
  /// In ar, this message translates to:
  /// **'ولي أمر'**
  String get accountTypeGuardian;

  /// No description provided for @accountTypeStudent.
  ///
  /// In ar, this message translates to:
  /// **'طالب'**
  String get accountTypeStudent;

  /// No description provided for @authVerifyTitle.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد البريد الإلكتروني'**
  String get authVerifyTitle;

  /// No description provided for @authVerifyBody.
  ///
  /// In ar, this message translates to:
  /// **'أرسلنا رابط التأكيد إلى {email}. افتح الرابط ثم اضغط \"تم التأكيد\".'**
  String authVerifyBody(String email);

  /// No description provided for @authVerifyCheck.
  ///
  /// In ar, this message translates to:
  /// **'تم التأكيد'**
  String get authVerifyCheck;

  /// No description provided for @authVerifyResend.
  ///
  /// In ar, this message translates to:
  /// **'إعادة إرسال الرابط'**
  String get authVerifyResend;

  /// No description provided for @authVerifyNotYet.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم تأكيد البريد بعد. افتح الرابط في الرسالة ثم حاول مرة أخرى.'**
  String get authVerifyNotYet;

  /// No description provided for @authVerifySent.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال الرابط من جديد.'**
  String get authVerifySent;

  /// No description provided for @authForgotTitle.
  ///
  /// In ar, this message translates to:
  /// **'استعادة كلمة السر'**
  String get authForgotTitle;

  /// No description provided for @authForgotBody.
  ///
  /// In ar, this message translates to:
  /// **'اكتب بريدك الإلكتروني وسنرسل لك رابطًا لإعادة تعيين كلمة السر.'**
  String get authForgotBody;

  /// No description provided for @authForgotSend.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الرابط'**
  String get authForgotSend;

  /// No description provided for @authResetSent.
  ///
  /// In ar, this message translates to:
  /// **'لو كان البريد مسجلًا لدينا فسيصلك رابط إعادة التعيين خلال دقائق.'**
  String get authResetSent;

  /// No description provided for @authBackToLogin.
  ///
  /// In ar, this message translates to:
  /// **'العودة لتسجيل الدخول'**
  String get authBackToLogin;

  /// No description provided for @authSignOut.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get authSignOut;

  /// No description provided for @authSignOutTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get authSignOutTitle;

  /// No description provided for @authSignOutMessage.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد تسجيل الخروج من حسابك؟'**
  String get authSignOutMessage;

  /// No description provided for @authSignOutFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تسجيل الخروج. حاول مرة أخرى.'**
  String get authSignOutFailed;

  /// No description provided for @authSignedInTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الدخول'**
  String get authSignedInTitle;

  /// No description provided for @authSignedInBody.
  ///
  /// In ar, this message translates to:
  /// **'أنت مسجل الدخول بالحساب {email}.'**
  String authSignedInBody(String email);

  /// No description provided for @centerCreateTitle.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء سنتر'**
  String get centerCreateTitle;

  /// No description provided for @centerCreateButton.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء السنتر'**
  String get centerCreateButton;

  /// No description provided for @centerSettingsTitle.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات السنتر'**
  String get centerSettingsTitle;

  /// No description provided for @centerName.
  ///
  /// In ar, this message translates to:
  /// **'اسم السنتر'**
  String get centerName;

  /// No description provided for @centerYear.
  ///
  /// In ar, this message translates to:
  /// **'السنة الدراسية'**
  String get centerYear;

  /// No description provided for @centerLateAfter.
  ///
  /// In ar, this message translates to:
  /// **'مدة التأخير (بالدقائق)'**
  String get centerLateAfter;

  /// No description provided for @centerSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get centerSave;

  /// No description provided for @centerSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ الإعدادات.'**
  String get centerSaved;

  /// No description provided for @centerNone.
  ///
  /// In ar, this message translates to:
  /// **'ليس لديك سنتر بعد.'**
  String get centerNone;

  /// No description provided for @centerYearInvalid.
  ///
  /// In ar, this message translates to:
  /// **'السنة غير صالحة'**
  String get centerYearInvalid;

  /// No description provided for @centerLateInvalid.
  ///
  /// In ar, this message translates to:
  /// **'المدة لازم تكون من 0 إلى 180 دقيقة'**
  String get centerLateInvalid;

  /// No description provided for @staffInviteTitle.
  ///
  /// In ar, this message translates to:
  /// **'إضافة موظف'**
  String get staffInviteTitle;

  /// No description provided for @staffInviteName.
  ///
  /// In ar, this message translates to:
  /// **'اسم الموظف'**
  String get staffInviteName;

  /// No description provided for @staffInviteRole.
  ///
  /// In ar, this message translates to:
  /// **'الدور'**
  String get staffInviteRole;

  /// No description provided for @staffRoleTeacher.
  ///
  /// In ar, this message translates to:
  /// **'معلم'**
  String get staffRoleTeacher;

  /// No description provided for @staffRoleAssistant.
  ///
  /// In ar, this message translates to:
  /// **'مساعد'**
  String get staffRoleAssistant;

  /// No description provided for @staffInvitePhone.
  ///
  /// In ar, this message translates to:
  /// **'موبايل الموظف (اختياري، لإرسال الكود عبر واتساب)'**
  String get staffInvitePhone;

  /// No description provided for @staffInviteCreate.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء الكود'**
  String get staffInviteCreate;

  /// No description provided for @staffInviteReadyTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء كود الدعوة'**
  String get staffInviteReadyTitle;

  /// No description provided for @staffInviteCodeLabel.
  ///
  /// In ar, this message translates to:
  /// **'كود الدعوة'**
  String get staffInviteCodeLabel;

  /// No description provided for @staffInviteValidUntil.
  ///
  /// In ar, this message translates to:
  /// **'صالح حتى {date}'**
  String staffInviteValidUntil(String date);

  /// No description provided for @staffInviteNote.
  ///
  /// In ar, this message translates to:
  /// **'الكود يُستخدم مرة واحدة فقط. بعد قبوله يصبح الموظف عضوًا في السنتر بالدور المحدد.'**
  String get staffInviteNote;

  /// No description provided for @staffInviteCopy.
  ///
  /// In ar, this message translates to:
  /// **'نسخ الكود'**
  String get staffInviteCopy;

  /// No description provided for @staffInviteCopied.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ الكود'**
  String get staffInviteCopied;

  /// No description provided for @staffInviteWhatsapp.
  ///
  /// In ar, this message translates to:
  /// **'إرسال عبر واتساب'**
  String get staffInviteWhatsapp;

  /// No description provided for @staffInviteAnother.
  ///
  /// In ar, this message translates to:
  /// **'إضافة موظف آخر'**
  String get staffInviteAnother;

  /// No description provided for @staffInviteMessage.
  ///
  /// In ar, this message translates to:
  /// **'مرحبًا {name}، تمت دعوتك للانضمام إلى {center} بصفة {role} على تطبيق CenterNet.\nكود الدعوة: {code}\nالكود صالح لمدة 7 أيام ويُستخدم مرة واحدة. سجّل حسابك في التطبيق ثم أدخل الكود.'**
  String staffInviteMessage(
    String name,
    String center,
    String role,
    String code,
  );

  /// No description provided for @staffJoinEntry.
  ///
  /// In ar, this message translates to:
  /// **'لدي كود دعوة'**
  String get staffJoinEntry;

  /// No description provided for @staffJoinTitle.
  ///
  /// In ar, this message translates to:
  /// **'الانضمام بكود دعوة'**
  String get staffJoinTitle;

  /// No description provided for @staffJoinIntro.
  ///
  /// In ar, this message translates to:
  /// **'اكتب كود الدعوة اللي وصلك من مدير السنتر.'**
  String get staffJoinIntro;

  /// No description provided for @staffJoinCodeLabel.
  ///
  /// In ar, this message translates to:
  /// **'كود الدعوة'**
  String get staffJoinCodeLabel;

  /// No description provided for @staffJoinCodeInvalid.
  ///
  /// In ar, this message translates to:
  /// **'الكود يتكون من 8 رموز (حروف إنجليزية وأرقام)'**
  String get staffJoinCodeInvalid;

  /// No description provided for @staffJoinButton.
  ///
  /// In ar, this message translates to:
  /// **'انضمام'**
  String get staffJoinButton;

  /// No description provided for @staffJoinSuccessTitle.
  ///
  /// In ar, this message translates to:
  /// **'تم الانضمام بنجاح'**
  String get staffJoinSuccessTitle;

  /// No description provided for @staffJoinSuccessBody.
  ///
  /// In ar, this message translates to:
  /// **'أصبحت عضوًا في {center} بصفة {role}.'**
  String staffJoinSuccessBody(String center, String role);

  /// No description provided for @staffJoinContinue.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get staffJoinContinue;

  /// No description provided for @staffListTitle.
  ///
  /// In ar, this message translates to:
  /// **'الموظفون'**
  String get staffListTitle;

  /// No description provided for @staffListEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد موظفون'**
  String get staffListEmpty;

  /// No description provided for @staffRoleAdmin.
  ///
  /// In ar, this message translates to:
  /// **'مدير'**
  String get staffRoleAdmin;

  /// No description provided for @staffStatusActive.
  ///
  /// In ar, this message translates to:
  /// **'نشط'**
  String get staffStatusActive;

  /// No description provided for @staffStatusDisabled.
  ///
  /// In ar, this message translates to:
  /// **'معطّل'**
  String get staffStatusDisabled;

  /// No description provided for @staffMenuTooltip.
  ///
  /// In ar, this message translates to:
  /// **'خيارات الموظف'**
  String get staffMenuTooltip;

  /// No description provided for @staffActionChangeRoleTo.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الدور إلى {role}'**
  String staffActionChangeRoleTo(String role);

  /// No description provided for @staffActionDisable.
  ///
  /// In ar, this message translates to:
  /// **'تعطيل'**
  String get staffActionDisable;

  /// No description provided for @staffActionEnable.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل'**
  String get staffActionEnable;

  /// No description provided for @staffChangeRoleTitle.
  ///
  /// In ar, this message translates to:
  /// **'تغيير دور الموظف'**
  String get staffChangeRoleTitle;

  /// No description provided for @staffChangeRoleMessage.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد تغيير دور {name} إلى {role}؟'**
  String staffChangeRoleMessage(String name, String role);

  /// No description provided for @staffChangeRoleConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تغيير'**
  String get staffChangeRoleConfirm;

  /// No description provided for @staffDisableTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعطيل الموظف'**
  String get staffDisableTitle;

  /// No description provided for @staffDisableMessage.
  ///
  /// In ar, this message translates to:
  /// **'{name} لن يتمكن من استخدام السنتر حتى تعيد تفعيله. هل تريد المتابعة؟'**
  String staffDisableMessage(String name);

  /// No description provided for @staffEnableTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل الموظف'**
  String get staffEnableTitle;

  /// No description provided for @staffEnableMessage.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد إعادة تفعيل {name}؟'**
  String staffEnableMessage(String name);

  /// No description provided for @scanTitle.
  ///
  /// In ar, this message translates to:
  /// **'مسح الحضور'**
  String get scanTitle;

  /// No description provided for @scanTitleDemo.
  ///
  /// In ar, this message translates to:
  /// **'مسح الحضور (تجريبي)'**
  String get scanTitleDemo;

  /// No description provided for @scanHint.
  ///
  /// In ar, this message translates to:
  /// **'وجّه الكاميرا ناحية رمز الـ QR الخاص بالطالب'**
  String get scanHint;

  /// No description provided for @scanWaiting.
  ///
  /// In ar, this message translates to:
  /// **'في انتظار مسح أول رمز'**
  String get scanWaiting;

  /// No description provided for @scanTorch.
  ///
  /// In ar, this message translates to:
  /// **'الفلاش'**
  String get scanTorch;

  /// No description provided for @scanSwitchCamera.
  ///
  /// In ar, this message translates to:
  /// **'تبديل الكاميرا'**
  String get scanSwitchCamera;

  /// No description provided for @scanPermissionDenied.
  ///
  /// In ar, this message translates to:
  /// **'نحتاج إذن الكاميرا لمسح الحضور. فعّله من إعدادات الجهاز ثم ارجع للشاشة.'**
  String get scanPermissionDenied;

  /// No description provided for @scanCameraUnsupported.
  ///
  /// In ar, this message translates to:
  /// **'الكاميرا غير متاحة على هذا الجهاز'**
  String get scanCameraUnsupported;

  /// No description provided for @scanCameraError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر تشغيل الكاميرا'**
  String get scanCameraError;

  /// No description provided for @scanRecordedPresent.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل حضور {student}'**
  String scanRecordedPresent(String student);

  /// No description provided for @scanRecordedLate.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل {student} متأخرًا'**
  String scanRecordedLate(String student);

  /// No description provided for @scanAlreadyRegistered.
  ///
  /// In ar, this message translates to:
  /// **'{student} مسجّل بالفعل'**
  String scanAlreadyRegistered(String student);

  /// No description provided for @scanVoidedBefore.
  ///
  /// In ar, this message translates to:
  /// **'{student} ملغى سابقًا — راجع المصحح'**
  String scanVoidedBefore(String student);

  /// No description provided for @scanNotRegistered.
  ///
  /// In ar, this message translates to:
  /// **'{student} غير مسجّل في مجموعة هذه الحصة'**
  String scanNotRegistered(String student);

  /// No description provided for @scanOtherCenter.
  ///
  /// In ar, this message translates to:
  /// **'هذا الرمز تابع لسنتر آخر'**
  String get scanOtherCenter;

  /// No description provided for @scanInvalidCode.
  ///
  /// In ar, this message translates to:
  /// **'رمز غير صالح'**
  String get scanInvalidCode;

  /// No description provided for @scanStorageError.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر حفظ المسحة على الجهاز، حاول مرة أخرى'**
  String get scanStorageError;

  /// No description provided for @scanLocalListCorrupt.
  ///
  /// In ar, this message translates to:
  /// **'قائمة المسحات المحلية تالفة، المسح متوقف'**
  String get scanLocalListCorrupt;

  /// No description provided for @scanCountPresent.
  ///
  /// In ar, this message translates to:
  /// **'حاضر {count}'**
  String scanCountPresent(int count);

  /// No description provided for @scanCountLate.
  ///
  /// In ar, this message translates to:
  /// **'متأخر {count}'**
  String scanCountLate(int count);

  /// No description provided for @scanCountRejected.
  ///
  /// In ar, this message translates to:
  /// **'مرفوض {count}'**
  String scanCountRejected(int count);

  /// No description provided for @scanPendingCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} بانتظار المزامنة'**
  String scanPendingCount(int count);

  /// No description provided for @scanDemoBanner.
  ///
  /// In ar, this message translates to:
  /// **'نموذج أولي: بيانات تجريبية، والمسحات لا تُحفظ على الجهاز'**
  String get scanDemoBanner;

  /// No description provided for @scanManualTitle.
  ///
  /// In ar, this message translates to:
  /// **'إدخال يدوي للتجربة'**
  String get scanManualTitle;

  /// No description provided for @scanManualHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: demo:s1'**
  String get scanManualHint;

  /// No description provided for @scanManualSubmit.
  ///
  /// In ar, this message translates to:
  /// **'تجربة الرمز'**
  String get scanManualSubmit;

  /// No description provided for @syncTitle.
  ///
  /// In ar, this message translates to:
  /// **'مزامنة المسحات'**
  String get syncTitle;

  /// No description provided for @syncSignOutWarning.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج قبل اكتمال المزامنة قد يؤدي إلى فقد بيانات حضور الطلاب.'**
  String get syncSignOutWarning;

  /// No description provided for @syncNoConnection.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اتصال بالإنترنت'**
  String get syncNoConnection;

  /// No description provided for @syncNoConnectionHint.
  ///
  /// In ar, this message translates to:
  /// **'أعد الاتصال بالإنترنت ثم حاول المزامنة مرة أخرى.'**
  String get syncNoConnectionHint;

  /// No description provided for @syncInProgress.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ رفع المسحات'**
  String get syncInProgress;

  /// No description provided for @syncProgress.
  ///
  /// In ar, this message translates to:
  /// **'تمت مزامنة {completed} من {total}'**
  String syncProgress(int completed, int total);

  /// No description provided for @syncDone.
  ///
  /// In ar, this message translates to:
  /// **'اكتملت المزامنة'**
  String get syncDone;

  /// No description provided for @syncDoneCount.
  ///
  /// In ar, this message translates to:
  /// **'تم رفع {count} مسحة بنجاح.'**
  String syncDoneCount(int count);

  /// No description provided for @syncNeedsAction.
  ///
  /// In ar, this message translates to:
  /// **'{count} مسحة تحتاج إلى إجراء.'**
  String syncNeedsAction(int count);

  /// No description provided for @syncRetryFailed.
  ///
  /// In ar, this message translates to:
  /// **'إعادة محاولة المسحات الفاشلة'**
  String get syncRetryFailed;

  /// No description provided for @syncPending.
  ///
  /// In ar, this message translates to:
  /// **'{count} مسحة بانتظار المزامنة'**
  String syncPending(int count);

  /// No description provided for @syncStart.
  ///
  /// In ar, this message translates to:
  /// **'بدء المزامنة'**
  String get syncStart;

  /// No description provided for @syncEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مسحات بانتظار المزامنة'**
  String get syncEmpty;

  /// No description provided for @studentsListTitle.
  ///
  /// In ar, this message translates to:
  /// **'الطلاب'**
  String get studentsListTitle;

  /// No description provided for @studentsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لم تتم إضافة طلاب بعد'**
  String get studentsEmpty;

  /// No description provided for @studentsNoResults.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد طالب مطابق للبحث'**
  String get studentsNoResults;

  /// No description provided for @studentsSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث بالاسم أو الرقم أو الموبايل'**
  String get studentsSearchHint;

  /// No description provided for @studentsAddTitle.
  ///
  /// In ar, this message translates to:
  /// **'إضافة طالب'**
  String get studentsAddTitle;

  /// No description provided for @studentsEditTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل بيانات الطالب'**
  String get studentsEditTitle;

  /// No description provided for @studentsShowArchived.
  ///
  /// In ar, this message translates to:
  /// **'إظهار المؤرشفين'**
  String get studentsShowArchived;

  /// No description provided for @studentsHideArchived.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء المؤرشفين'**
  String get studentsHideArchived;

  /// No description provided for @studentFieldName.
  ///
  /// In ar, this message translates to:
  /// **'اسم الطالب'**
  String get studentFieldName;

  /// No description provided for @studentFieldPhone.
  ///
  /// In ar, this message translates to:
  /// **'رقم الموبايل'**
  String get studentFieldPhone;

  /// No description provided for @studentFieldGrade.
  ///
  /// In ar, this message translates to:
  /// **'الصف الدراسي (اختياري)'**
  String get studentFieldGrade;

  /// No description provided for @studentSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get studentSave;

  /// No description provided for @studentNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم الطالب: {no}'**
  String studentNumber(int no);

  /// No description provided for @studentDetailTitle.
  ///
  /// In ar, this message translates to:
  /// **'ملف الطالب'**
  String get studentDetailTitle;

  /// No description provided for @studentEdit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل البيانات'**
  String get studentEdit;

  /// No description provided for @studentArchive.
  ///
  /// In ar, this message translates to:
  /// **'أرشفة الطالب'**
  String get studentArchive;

  /// No description provided for @studentRestore.
  ///
  /// In ar, this message translates to:
  /// **'استرجاع الطالب'**
  String get studentRestore;

  /// No description provided for @studentArchiveTitle.
  ///
  /// In ar, this message translates to:
  /// **'أرشفة الطالب'**
  String get studentArchiveTitle;

  /// No description provided for @studentArchiveMessage.
  ///
  /// In ar, this message translates to:
  /// **'سيتم إخفاء {name} من القوائم، ولن يُحذف أي من بياناته أو سجل حضوره. هل تريد المتابعة؟'**
  String studentArchiveMessage(String name);

  /// No description provided for @studentArchiveConfirm.
  ///
  /// In ar, this message translates to:
  /// **'أرشفة'**
  String get studentArchiveConfirm;

  /// No description provided for @studentArchivedBadge.
  ///
  /// In ar, this message translates to:
  /// **'مؤرشف'**
  String get studentArchivedBadge;

  /// No description provided for @studentQrHint.
  ///
  /// In ar, this message translates to:
  /// **'يعرض الطالب هذا الرمز عند دخول الحصة'**
  String get studentQrHint;

  /// No description provided for @studentPhoneLabel.
  ///
  /// In ar, this message translates to:
  /// **'الموبايل: {phone}'**
  String studentPhoneLabel(String phone);

  /// No description provided for @studentGradeLabel.
  ///
  /// In ar, this message translates to:
  /// **'الصف: {grade}'**
  String studentGradeLabel(String grade);

  /// No description provided for @homeAdminTitle.
  ///
  /// In ar, this message translates to:
  /// **'رئيسية الأدمن'**
  String get homeAdminTitle;

  /// No description provided for @homeTeacherTitle.
  ///
  /// In ar, this message translates to:
  /// **'رئيسية المعلم'**
  String get homeTeacherTitle;

  /// No description provided for @homeAssistantTitle.
  ///
  /// In ar, this message translates to:
  /// **'رئيسية المساعد'**
  String get homeAssistantTitle;

  /// No description provided for @homeStudentTitle.
  ///
  /// In ar, this message translates to:
  /// **'رئيسية الطالب'**
  String get homeStudentTitle;

  /// No description provided for @homeGuardianTitle.
  ///
  /// In ar, this message translates to:
  /// **'رئيسية ولي الأمر'**
  String get homeGuardianTitle;

  /// No description provided for @homeComingSoon.
  ///
  /// In ar, this message translates to:
  /// **'هذه الشاشة قيد التطوير.'**
  String get homeComingSoon;

  /// No description provided for @homeInactiveTitle.
  ///
  /// In ar, this message translates to:
  /// **'الحساب معطّل'**
  String get homeInactiveTitle;

  /// No description provided for @homeInactiveBody.
  ///
  /// In ar, this message translates to:
  /// **'تم تعطيل حسابك من إدارة السنتر. تواصل مع الأدمن.'**
  String get homeInactiveBody;

  /// No description provided for @homeNoAccessTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد صلاحيات'**
  String get homeNoAccessTitle;

  /// No description provided for @homeNoAccessBody.
  ///
  /// In ar, this message translates to:
  /// **'حسابك غير مرتبط بسنتر بشكل صحيح. تواصل مع الأدمن أو سجّل الخروج.'**
  String get homeNoAccessBody;

  /// No description provided for @examsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الامتحانات'**
  String get examsTitle;

  /// No description provided for @examsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لم تتم إضافة امتحانات بعد'**
  String get examsEmpty;

  /// No description provided for @examAddTitle.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء امتحان'**
  String get examAddTitle;

  /// No description provided for @examFieldTitle.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الامتحان'**
  String get examFieldTitle;

  /// No description provided for @examFieldMax.
  ///
  /// In ar, this message translates to:
  /// **'الدرجة النهائية'**
  String get examFieldMax;

  /// No description provided for @examMaxInvalid.
  ///
  /// In ar, this message translates to:
  /// **'الدرجة النهائية لازم تكون رقمًا أكبر من صفر'**
  String get examMaxInvalid;

  /// No description provided for @examSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ الامتحان'**
  String get examSave;

  /// No description provided for @examPublished.
  ///
  /// In ar, this message translates to:
  /// **'منشور'**
  String get examPublished;

  /// No description provided for @examDraft.
  ///
  /// In ar, this message translates to:
  /// **'مسودة'**
  String get examDraft;

  /// No description provided for @examPublish.
  ///
  /// In ar, this message translates to:
  /// **'نشر الدرجات'**
  String get examPublish;

  /// No description provided for @examUnpublish.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء النشر'**
  String get examUnpublish;

  /// No description provided for @examMaxLabel.
  ///
  /// In ar, this message translates to:
  /// **'من {max}'**
  String examMaxLabel(String max);

  /// No description provided for @scoresTitle.
  ///
  /// In ar, this message translates to:
  /// **'إدخال الدرجات'**
  String get scoresTitle;

  /// No description provided for @scoresEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد طلاب في المجموعة'**
  String get scoresEmpty;

  /// No description provided for @scoresRecorded.
  ///
  /// In ar, this message translates to:
  /// **'تم رصد {done} من {total}'**
  String scoresRecorded(int done, int total);

  /// No description provided for @scoreStateScored.
  ///
  /// In ar, this message translates to:
  /// **'له درجة'**
  String get scoreStateScored;

  /// No description provided for @scoreStateAbsent.
  ///
  /// In ar, this message translates to:
  /// **'غائب'**
  String get scoreStateAbsent;

  /// No description provided for @scoreStateExcused.
  ///
  /// In ar, this message translates to:
  /// **'معفى'**
  String get scoreStateExcused;

  /// No description provided for @scoreNotYet.
  ///
  /// In ar, this message translates to:
  /// **'لسه'**
  String get scoreNotYet;

  /// No description provided for @scoreFieldScore.
  ///
  /// In ar, this message translates to:
  /// **'الدرجة'**
  String get scoreFieldScore;

  /// No description provided for @scoreFieldComment.
  ///
  /// In ar, this message translates to:
  /// **'تعليق (اختياري)'**
  String get scoreFieldComment;

  /// No description provided for @scoreSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get scoreSave;

  /// No description provided for @myGroupsTitle.
  ///
  /// In ar, this message translates to:
  /// **'مجموعاتي'**
  String get myGroupsTitle;

  /// No description provided for @myGroupsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مجموعات مسندة إليك'**
  String get myGroupsEmpty;

  /// No description provided for @groupExamsButton.
  ///
  /// In ar, this message translates to:
  /// **'الامتحانات والدرجات'**
  String get groupExamsButton;

  /// No description provided for @groupNoStudents.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد طلاب في المجموعة'**
  String get groupNoStudents;

  /// No description provided for @groupStudentsSummary.
  ///
  /// In ar, this message translates to:
  /// **'{students} طالب · {sessions} حصة سابقة'**
  String groupStudentsSummary(int students, int sessions);

  /// No description provided for @groupAbsencesBadge.
  ///
  /// In ar, this message translates to:
  /// **'غياب {count}'**
  String groupAbsencesBadge(int count);

  /// No description provided for @groupsListTitle.
  ///
  /// In ar, this message translates to:
  /// **'المجموعات'**
  String get groupsListTitle;

  /// No description provided for @groupsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مجموعات بعد'**
  String get groupsEmpty;

  /// No description provided for @groupsNoResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مجموعة مطابقة للبحث'**
  String get groupsNoResults;

  /// No description provided for @groupsSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث بالاسم أو المادة أو الصف'**
  String get groupsSearchHint;

  /// No description provided for @groupsShowArchived.
  ///
  /// In ar, this message translates to:
  /// **'عرض المؤرشفة'**
  String get groupsShowArchived;

  /// No description provided for @groupsHideArchived.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء المؤرشفة'**
  String get groupsHideArchived;

  /// No description provided for @groupArchivedBadge.
  ///
  /// In ar, this message translates to:
  /// **'مؤرشفة'**
  String get groupArchivedBadge;

  /// No description provided for @groupArchiveAction.
  ///
  /// In ar, this message translates to:
  /// **'أرشفة'**
  String get groupArchiveAction;

  /// No description provided for @groupArchiveTitle.
  ///
  /// In ar, this message translates to:
  /// **'أرشفة المجموعة؟'**
  String get groupArchiveTitle;

  /// No description provided for @groupArchiveMessage.
  ///
  /// In ar, this message translates to:
  /// **'سيتم إخفاء {name} من القوائم، ولن تُحذف بياناتها أو حصصها. هل تريد المتابعة؟'**
  String groupArchiveMessage(String name);

  /// No description provided for @groupArchiveConfirm.
  ///
  /// In ar, this message translates to:
  /// **'أرشفة'**
  String get groupArchiveConfirm;

  /// No description provided for @groupsAddTitle.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مجموعة'**
  String get groupsAddTitle;

  /// No description provided for @groupEditTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل المجموعة'**
  String get groupEditTitle;

  /// No description provided for @groupFieldName.
  ///
  /// In ar, this message translates to:
  /// **'اسم المجموعة'**
  String get groupFieldName;

  /// No description provided for @groupFieldSubject.
  ///
  /// In ar, this message translates to:
  /// **'المادة (اختياري)'**
  String get groupFieldSubject;

  /// No description provided for @groupFieldGrade.
  ///
  /// In ar, this message translates to:
  /// **'الصف (اختياري)'**
  String get groupFieldGrade;

  /// No description provided for @groupFieldRoom.
  ///
  /// In ar, this message translates to:
  /// **'القاعة (اختياري)'**
  String get groupFieldRoom;

  /// No description provided for @groupFieldTeacher.
  ///
  /// In ar, this message translates to:
  /// **'المعلم'**
  String get groupFieldTeacher;

  /// No description provided for @groupFieldAssistants.
  ///
  /// In ar, this message translates to:
  /// **'المساعدون (اختياري)'**
  String get groupFieldAssistants;

  /// No description provided for @groupFieldCapacity.
  ///
  /// In ar, this message translates to:
  /// **'السعة القصوى (اختياري)'**
  String get groupFieldCapacity;

  /// No description provided for @groupFieldFee.
  ///
  /// In ar, this message translates to:
  /// **'السعر الشهري بالجنيه (اختياري)'**
  String get groupFieldFee;

  /// No description provided for @groupSlotsTitle.
  ///
  /// In ar, this message translates to:
  /// **'المواعيد الأسبوعية'**
  String get groupSlotsTitle;

  /// No description provided for @groupSlotDay.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get groupSlotDay;

  /// No description provided for @groupSlotDuration.
  ///
  /// In ar, this message translates to:
  /// **'المدة بالدقائق'**
  String get groupSlotDuration;

  /// No description provided for @groupAddSlot.
  ///
  /// In ar, this message translates to:
  /// **'إضافة ميعاد'**
  String get groupAddSlot;

  /// No description provided for @groupSlotRemove.
  ///
  /// In ar, this message translates to:
  /// **'حذف الميعاد'**
  String get groupSlotRemove;

  /// No description provided for @groupNoTeachers.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد معلمون نشطون. أضفهم من شاشة الفريق أولًا.'**
  String get groupNoTeachers;

  /// No description provided for @groupInvalidCapacity.
  ///
  /// In ar, this message translates to:
  /// **'اكتب رقمًا صحيحًا (1 أو أكثر)'**
  String get groupInvalidCapacity;

  /// No description provided for @groupInvalidFee.
  ///
  /// In ar, this message translates to:
  /// **'اكتب سعرًا صحيحًا (0 أو أكثر)'**
  String get groupInvalidFee;

  /// No description provided for @groupInvalidDuration.
  ///
  /// In ar, this message translates to:
  /// **'المدة لازم تكون من 1 لـ 480 دقيقة'**
  String get groupInvalidDuration;

  /// No description provided for @groupStudentsMenu.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الطلاب'**
  String get groupStudentsMenu;

  /// No description provided for @groupEnrolledCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} طالب مسجّل'**
  String groupEnrolledCount(int count);

  /// No description provided for @groupFullBadge.
  ///
  /// In ar, this message translates to:
  /// **'مكتملة العدد'**
  String get groupFullBadge;

  /// No description provided for @groupStudentsSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث بالاسم أو الرقم'**
  String get groupStudentsSearchHint;

  /// No description provided for @groupStudentsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد طلاب لعرضهم'**
  String get groupStudentsEmpty;

  /// No description provided for @groupSessionsMenu.
  ///
  /// In ar, this message translates to:
  /// **'الحصص'**
  String get groupSessionsMenu;

  /// No description provided for @sessionsGenerateButton.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حصص الأسابيع الجاية'**
  String get sessionsGenerateButton;

  /// No description provided for @sessionsGenerateResult.
  ///
  /// In ar, this message translates to:
  /// **'اتكتبت {created} حصة جديدة ({skipped} موجودة بالفعل)'**
  String sessionsGenerateResult(int created, int skipped);

  /// No description provided for @sessionsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد حصص قادمة. أنشئ حصص الأسابيع الجاية من الزر بالأعلى.'**
  String get sessionsEmpty;

  /// No description provided for @sessionScheduledBadge.
  ///
  /// In ar, this message translates to:
  /// **'مجدولة'**
  String get sessionScheduledBadge;

  /// No description provided for @sessionCancelledBadge.
  ///
  /// In ar, this message translates to:
  /// **'ملغاة'**
  String get sessionCancelledBadge;

  /// No description provided for @sessionCancelAction.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الحصة'**
  String get sessionCancelAction;

  /// No description provided for @sessionCancelTitle.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الحصة؟'**
  String get sessionCancelTitle;

  /// No description provided for @sessionCancelMessage.
  ///
  /// In ar, this message translates to:
  /// **'حصة يوم {date} هتتلغي ولن تُعاد تلقائيًا. هل تريد المتابعة؟'**
  String sessionCancelMessage(String date);

  /// No description provided for @sessionCancelConfirm.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الحصة'**
  String get sessionCancelConfirm;

  /// No description provided for @myAccountTitle.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get myAccountTitle;

  /// No description provided for @myAccountName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get myAccountName;

  /// No description provided for @myAccountEmail.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get myAccountEmail;

  /// No description provided for @myAccountPhone.
  ///
  /// In ar, this message translates to:
  /// **'الموبايل'**
  String get myAccountPhone;

  /// No description provided for @myAccountType.
  ///
  /// In ar, this message translates to:
  /// **'نوع الحساب'**
  String get myAccountType;

  /// No description provided for @myAccountLoadError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل بيانات الحساب'**
  String get myAccountLoadError;

  /// No description provided for @groupRoomConflict.
  ///
  /// In ar, this message translates to:
  /// **'القاعة دي محجوزة لمجموعة «{group}» يوم {day} من {start} لـ {end}'**
  String groupRoomConflict(String group, String day, String start, String end);

  /// No description provided for @linkEnterTitle.
  ///
  /// In ar, this message translates to:
  /// **'ربط الحساب بالطالب'**
  String get linkEnterTitle;

  /// No description provided for @linkStudentIntro.
  ///
  /// In ar, this message translates to:
  /// **'اكتب كود الربط اللي استلمته من السنتر عشان تربط حسابك بملفك كطالب.'**
  String get linkStudentIntro;

  /// No description provided for @linkGuardianIntro.
  ///
  /// In ar, this message translates to:
  /// **'اكتب كود الربط اللي استلمته من السنتر عشان تتابع حضور ودرجات ابنك أو ابنتك.'**
  String get linkGuardianIntro;

  /// No description provided for @linkCodeLabel.
  ///
  /// In ar, this message translates to:
  /// **'كود الربط'**
  String get linkCodeLabel;

  /// No description provided for @linkCodeHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: AB3CD4EF'**
  String get linkCodeHint;

  /// No description provided for @linkConsentTitle.
  ///
  /// In ar, this message translates to:
  /// **'الموافقة على الربط'**
  String get linkConsentTitle;

  /// No description provided for @linkConsentStudent.
  ///
  /// In ar, this message translates to:
  /// **'بربط حسابك سيظهر لك جدولك وحضورك ونتايجك، ويقدر السنتر يربط بياناتك الدراسية بحسابك. تقدر تفك الربط في أي وقت.'**
  String get linkConsentStudent;

  /// No description provided for @linkConsentGuardian.
  ///
  /// In ar, this message translates to:
  /// **'بربط حسابك أنت توافق على عرض البيانات الدراسية للطالب لك (الحضور والدرجات والجدول). الحد الأقصى {max} أولياء أمور لكل طالب، وتقدر تفك الربط في أي وقت.'**
  String linkConsentGuardian(int max);

  /// No description provided for @linkConsentAgree.
  ///
  /// In ar, this message translates to:
  /// **'أوافق'**
  String get linkConsentAgree;

  /// No description provided for @linkSubmit.
  ///
  /// In ar, this message translates to:
  /// **'ربط'**
  String get linkSubmit;

  /// No description provided for @linkSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم الربط بنجاح'**
  String get linkSuccess;

  /// No description provided for @linkUnlink.
  ///
  /// In ar, this message translates to:
  /// **'فك الربط'**
  String get linkUnlink;

  /// No description provided for @linkUnlinkTitle.
  ///
  /// In ar, this message translates to:
  /// **'فك الربط'**
  String get linkUnlinkTitle;

  /// No description provided for @linkUnlinkMessage.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد فك ربط حسابك بالطالب {name}؟ لن تتمكن من رؤية بياناته بعد ذلك.'**
  String linkUnlinkMessage(String name);

  /// No description provided for @linkIssueStudentCode.
  ///
  /// In ar, this message translates to:
  /// **'كود ربط الطالب'**
  String get linkIssueStudentCode;

  /// No description provided for @linkIssueGuardianCode.
  ///
  /// In ar, this message translates to:
  /// **'كود ربط ولي الأمر'**
  String get linkIssueGuardianCode;

  /// No description provided for @linkIssueRelationTitle.
  ///
  /// In ar, this message translates to:
  /// **'صلة القرابة'**
  String get linkIssueRelationTitle;

  /// No description provided for @linkIssueExpires.
  ///
  /// In ar, this message translates to:
  /// **'صالح حتى {date}'**
  String linkIssueExpires(String date);

  /// No description provided for @linkIssueCopy.
  ///
  /// In ar, this message translates to:
  /// **'نسخ'**
  String get linkIssueCopy;

  /// No description provided for @linkIssueCopied.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ الكود'**
  String get linkIssueCopied;

  /// No description provided for @linkIssueClose.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get linkIssueClose;

  /// No description provided for @relationFather.
  ///
  /// In ar, this message translates to:
  /// **'أب'**
  String get relationFather;

  /// No description provided for @relationMother.
  ///
  /// In ar, this message translates to:
  /// **'أم'**
  String get relationMother;

  /// No description provided for @relationBrother.
  ///
  /// In ar, this message translates to:
  /// **'أخ'**
  String get relationBrother;

  /// No description provided for @relationSister.
  ///
  /// In ar, this message translates to:
  /// **'أخت'**
  String get relationSister;

  /// No description provided for @relationOther.
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get relationOther;

  /// No description provided for @areaNotLinked.
  ///
  /// In ar, this message translates to:
  /// **'حسابك غير مربوط بطالب بعد.'**
  String get areaNotLinked;

  /// No description provided for @areaLinkStudentButton.
  ///
  /// In ar, this message translates to:
  /// **'ربط حسابي بكود الطالب'**
  String get areaLinkStudentButton;

  /// No description provided for @areaScheduleTitle.
  ///
  /// In ar, this message translates to:
  /// **'الجدول الأسبوعي'**
  String get areaScheduleTitle;

  /// No description provided for @areaAttendanceTitle.
  ///
  /// In ar, this message translates to:
  /// **'سجل الحضور'**
  String get areaAttendanceTitle;

  /// No description provided for @areaResultsTitle.
  ///
  /// In ar, this message translates to:
  /// **'النتائج'**
  String get areaResultsTitle;

  /// No description provided for @areaScheduleEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مواعيد مسجلة'**
  String get areaScheduleEmpty;

  /// No description provided for @areaAttendanceEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد حضور مسجل بعد'**
  String get areaAttendanceEmpty;

  /// No description provided for @areaResultsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج منشورة بعد'**
  String get areaResultsEmpty;

  /// No description provided for @weekdayName.
  ///
  /// In ar, this message translates to:
  /// **'{day, select, d1{الاثنين} d2{الثلاثاء} d3{الأربعاء} d4{الخميس} d5{الجمعة} d6{السبت} other{الأحد}}'**
  String weekdayName(String day);

  /// No description provided for @scheduleRoom.
  ///
  /// In ar, this message translates to:
  /// **'القاعة: {room}'**
  String scheduleRoom(String room);

  /// No description provided for @scheduleTimeRange.
  ///
  /// In ar, this message translates to:
  /// **'{start} - {end}'**
  String scheduleTimeRange(String start, String end);

  /// No description provided for @attendanceStatusPresent.
  ///
  /// In ar, this message translates to:
  /// **'حاضر'**
  String get attendanceStatusPresent;

  /// No description provided for @attendanceStatusLate.
  ///
  /// In ar, this message translates to:
  /// **'متأخر'**
  String get attendanceStatusLate;

  /// No description provided for @attendanceStatusExcused.
  ///
  /// In ar, this message translates to:
  /// **'غائب بعذر'**
  String get attendanceStatusExcused;

  /// No description provided for @attendanceSummary.
  ///
  /// In ar, this message translates to:
  /// **'حضر {attended} من {total} حصة'**
  String attendanceSummary(int attended, int total);

  /// No description provided for @attendanceDateTime.
  ///
  /// In ar, this message translates to:
  /// **'{date} - {time}'**
  String attendanceDateTime(String date, String time);

  /// No description provided for @resultsAverage.
  ///
  /// In ar, this message translates to:
  /// **'المتوسط العام: {percent}%'**
  String resultsAverage(String percent);

  /// No description provided for @resultsScoreOf.
  ///
  /// In ar, this message translates to:
  /// **'{score} من {max}'**
  String resultsScoreOf(String score, String max);

  /// No description provided for @resultsAbsent.
  ///
  /// In ar, this message translates to:
  /// **'غائب'**
  String get resultsAbsent;

  /// No description provided for @resultsExcused.
  ///
  /// In ar, this message translates to:
  /// **'معفى'**
  String get resultsExcused;

  /// No description provided for @resultsPending.
  ///
  /// In ar, this message translates to:
  /// **'لم تُرصد بعد'**
  String get resultsPending;

  /// No description provided for @guardianNoChildren.
  ///
  /// In ar, this message translates to:
  /// **'لم تربط أي طالب بعد.'**
  String get guardianNoChildren;

  /// No description provided for @guardianLinkChild.
  ///
  /// In ar, this message translates to:
  /// **'ربط طالب بكود'**
  String get guardianLinkChild;

  /// No description provided for @guardianAddChild.
  ///
  /// In ar, this message translates to:
  /// **'ربط طالب آخر'**
  String get guardianAddChild;

  /// No description provided for @guardianRelation.
  ///
  /// In ar, this message translates to:
  /// **'صلتك: {relation}'**
  String guardianRelation(String relation);

  /// No description provided for @guardianChooseChild.
  ///
  /// In ar, this message translates to:
  /// **'اختر الطالب'**
  String get guardianChooseChild;

  /// No description provided for @appName.
  ///
  /// In ar, this message translates to:
  /// **'CenterNet'**
  String get appName;

  /// No description provided for @assistantHomeTitle.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get assistantHomeTitle;

  /// No description provided for @assistantGreeting.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً، {name}'**
  String assistantGreeting(String name);

  /// No description provided for @assistantOnline.
  ///
  /// In ar, this message translates to:
  /// **'متصل بالإنترنت'**
  String get assistantOnline;

  /// No description provided for @assistantOffline.
  ///
  /// In ar, this message translates to:
  /// **'غير متصل بالإنترنت'**
  String get assistantOffline;

  /// No description provided for @assistantTodayCount.
  ///
  /// In ar, this message translates to:
  /// **'عندك {count} حصص النهارده'**
  String assistantTodayCount(int count);

  /// No description provided for @assistantNoSessionsToday.
  ///
  /// In ar, this message translates to:
  /// **'مفيش حصص النهارده'**
  String get assistantNoSessionsToday;

  /// No description provided for @assistantCurrentSession.
  ///
  /// In ar, this message translates to:
  /// **'الحصة الجارية دلوقتي'**
  String get assistantCurrentSession;

  /// No description provided for @assistantNoCurrentSession.
  ///
  /// In ar, this message translates to:
  /// **'مفيش حصة جارية حاليًا'**
  String get assistantNoCurrentSession;

  /// No description provided for @assistantStartScanning.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ المسح'**
  String get assistantStartScanning;

  /// No description provided for @assistantSessionsTitle.
  ///
  /// In ar, this message translates to:
  /// **'حصص النهارده'**
  String get assistantSessionsTitle;

  /// No description provided for @assistantSessionDetailsTitle.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الحصة'**
  String get assistantSessionDetailsTitle;

  /// No description provided for @sessionStatusCurrent.
  ///
  /// In ar, this message translates to:
  /// **'جارية'**
  String get sessionStatusCurrent;

  /// No description provided for @sessionStatusUpcoming.
  ///
  /// In ar, this message translates to:
  /// **'قادمة'**
  String get sessionStatusUpcoming;

  /// No description provided for @sessionStatusEnded.
  ///
  /// In ar, this message translates to:
  /// **'انتهت'**
  String get sessionStatusEnded;

  /// No description provided for @sessionStatusCancelled.
  ///
  /// In ar, this message translates to:
  /// **'ملغاة'**
  String get sessionStatusCancelled;

  /// No description provided for @sessionGroupLabel.
  ///
  /// In ar, this message translates to:
  /// **'المجموعة'**
  String get sessionGroupLabel;

  /// No description provided for @sessionTimeLabel.
  ///
  /// In ar, this message translates to:
  /// **'الوقت'**
  String get sessionTimeLabel;

  /// No description provided for @sessionRoomLabel.
  ///
  /// In ar, this message translates to:
  /// **'القاعة'**
  String get sessionRoomLabel;

  /// No description provided for @sessionNoRoom.
  ///
  /// In ar, this message translates to:
  /// **'غير محددة'**
  String get sessionNoRoom;

  /// No description provided for @sessionScanStudent.
  ///
  /// In ar, this message translates to:
  /// **'مسح كود الطالب'**
  String get sessionScanStudent;

  /// No description provided for @sessionAttendanceSummary.
  ///
  /// In ar, this message translates to:
  /// **'حضر {attended} من {total} طالب'**
  String sessionAttendanceSummary(int attended, int total);

  /// No description provided for @sessionAttendanceWaiting.
  ///
  /// In ar, this message translates to:
  /// **'{count} بانتظار المزامنة'**
  String sessionAttendanceWaiting(int count);

  /// No description provided for @sessionAttendanceNotYetLabel.
  ///
  /// In ar, this message translates to:
  /// **'لسه ما حضروش'**
  String get sessionAttendanceNotYetLabel;

  /// No description provided for @sessionAttendanceNotYet.
  ///
  /// In ar, this message translates to:
  /// **'{count} طالب'**
  String sessionAttendanceNotYet(int count);

  /// No description provided for @sessionLastScansTitle.
  ///
  /// In ar, this message translates to:
  /// **'آخر عمليات المسح'**
  String get sessionLastScansTitle;

  /// No description provided for @sessionAttendanceListButton.
  ///
  /// In ar, this message translates to:
  /// **'قائمة الحضور'**
  String get sessionAttendanceListButton;

  /// No description provided for @assistantAttendanceTitle.
  ///
  /// In ar, this message translates to:
  /// **'قائمة الحضور'**
  String get assistantAttendanceTitle;

  /// No description provided for @assistantAttendanceNoSessions.
  ///
  /// In ar, this message translates to:
  /// **'مفيش حصص النهارده'**
  String get assistantAttendanceNoSessions;

  /// No description provided for @attendanceSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث بالاسم أو الكود'**
  String get attendanceSearchHint;

  /// No description provided for @attendanceFilterAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get attendanceFilterAll;

  /// No description provided for @attendanceFilterWaiting.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار المزامنة'**
  String get attendanceFilterWaiting;

  /// No description provided for @attendanceFilterFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشلت المزامنة'**
  String get attendanceFilterFailed;

  /// No description provided for @attendanceEmpty.
  ///
  /// In ar, this message translates to:
  /// **'مفيش حضور مسجل في الحصة دي لحد دلوقتي'**
  String get attendanceEmpty;

  /// No description provided for @attendanceNoResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج مطابقة للبحث'**
  String get attendanceNoResults;

  /// No description provided for @attendanceSyncSynced.
  ///
  /// In ar, this message translates to:
  /// **'تمت المزامنة'**
  String get attendanceSyncSynced;

  /// No description provided for @attendanceSyncWaiting.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار المزامنة'**
  String get attendanceSyncWaiting;

  /// No description provided for @attendanceSyncFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشلت المزامنة'**
  String get attendanceSyncFailed;

  /// No description provided for @attendanceUnknownStudent.
  ///
  /// In ar, this message translates to:
  /// **'طالب مش في المجموعة'**
  String get attendanceUnknownStudent;

  /// No description provided for @attendanceStudentCode.
  ///
  /// In ar, this message translates to:
  /// **'كود {code}'**
  String attendanceStudentCode(int code);

  /// No description provided for @assistantNavHome.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get assistantNavHome;

  /// No description provided for @assistantNavSessions.
  ///
  /// In ar, this message translates to:
  /// **'الحصص'**
  String get assistantNavSessions;

  /// No description provided for @assistantNavAttendance.
  ///
  /// In ar, this message translates to:
  /// **'الحضور'**
  String get assistantNavAttendance;

  /// No description provided for @assistantNavSync.
  ///
  /// In ar, this message translates to:
  /// **'المزامنة'**
  String get assistantNavSync;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
