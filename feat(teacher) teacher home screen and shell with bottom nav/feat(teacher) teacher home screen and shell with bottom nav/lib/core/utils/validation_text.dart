import '../../l10n/app_localizations.dart';
import 'validation_error.dart';

/// بيحوّل [ValidationError] لرسالة عربية من `app_ar.arb`.
///
/// الاستخدام في حقل: `validator: (v) => Validators.mobile(v ?? '')?.message(l10n)`
extension ValidationErrorText on ValidationError {
  String message(AppLocalizations l10n) => switch (this) {
        ValidationError.required => l10n.validationRequired,
        ValidationError.nameTooShort => l10n.validationNameTooShort,
        ValidationError.nameTooLong => l10n.validationNameTooLong,
        ValidationError.nameInvalid => l10n.validationNameInvalid,
        ValidationError.mobileInvalid => l10n.validationMobileInvalid,
        ValidationError.emailInvalid => l10n.validationEmailInvalid,
        ValidationError.passwordTooShort => l10n.validationPasswordTooShort,
        ValidationError.scoreInvalid => l10n.validationScoreInvalid,
        ValidationError.scoreOutOfRange => l10n.validationScoreOutOfRange,
        ValidationError.scoreStep => l10n.validationScoreStep,
      };
}
