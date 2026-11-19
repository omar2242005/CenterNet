import '../../../l10n/app_localizations.dart';
import 'center_validators.dart';

/// بيحوّل [CenterFieldError] لرسالة عربية من `app_ar.arb`.
extension CenterFieldErrorText on CenterFieldError {
  String message(AppLocalizations l10n) => switch (this) {
    CenterFieldError.required => l10n.validationRequired,
    CenterFieldError.nameTooShort => l10n.centersNameTooShort,
    CenterFieldError.nameTooLong => l10n.centersNameTooLong,
    CenterFieldError.yearInvalid => l10n.centersYearInvalid,
    CenterFieldError.lateInvalid => l10n.centersLateInvalid,
  };
}
