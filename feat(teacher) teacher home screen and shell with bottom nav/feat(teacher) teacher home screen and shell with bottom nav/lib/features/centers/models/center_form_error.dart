import '../../../l10n/app_localizations.dart';
import 'center_info.dart';

/// أخطاء تحقق فورم السنتر (نقية، من غير Flutter).
enum CenterFormError { required, nameTooLong, yearInvalid, lateInvalid }

abstract final class CenterValidators {
  static const int minYear = 2000;
  static const int maxYear = 2100;

  static CenterFormError? name(String input) {
    final n = input.trim();
    if (n.isEmpty) return CenterFormError.required;
    if (n.length > CenterInfo.maxNameLength) return CenterFormError.nameTooLong;
    return null;
  }

  /// [input] بعد تحويل الأرقام للاتينية.
  static CenterFormError? year(String input) {
    final y = int.tryParse(input.trim());
    if (input.trim().isEmpty) return CenterFormError.required;
    if (y == null || y < minYear || y > maxYear) {
      return CenterFormError.yearInvalid;
    }
    return null;
  }

  static CenterFormError? lateAfter(String input) {
    if (input.trim().isEmpty) return CenterFormError.required;
    final m = int.tryParse(input.trim());
    if (m == null || m < 0 || m > CenterInfo.maxLateAfterMinutes) {
      return CenterFormError.lateInvalid;
    }
    return null;
  }
}

extension CenterFormErrorText on CenterFormError {
  String message(AppLocalizations l10n) => switch (this) {
        CenterFormError.required => l10n.validationRequired,
        CenterFormError.nameTooLong => l10n.validationNameTooLong,
        CenterFormError.yearInvalid => l10n.centerYearInvalid,
        CenterFormError.lateInvalid => l10n.centerLateInvalid,
      };
}
