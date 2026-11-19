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
