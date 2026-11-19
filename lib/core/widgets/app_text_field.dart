import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../utils/latin_digits_formatter.dart';

/// حقل نص موحّد (TextFormField بشكل الثيم).
///
/// * [obscureText] = true بيضيف زر إظهار/إخفاء كلمة السر.
/// * [isLtr] للموبايل والإيميل والأكواد: الكتابة LTR بس الحقل فاضل على اليمين.
/// * [latinDigits] بيحوّل الأرقام الهندية للاتينية وقت الكتابة.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.validator,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.prefixIcon,
    this.errorText,
    this.obscureText = false,
    this.enabled = true,
    this.isLtr = false,
    this.latinDigits = false,
    this.maxLines = 1,
    this.maxLength,
    this.autofocus = false,
    this.autovalidateMode,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final IconData? prefixIcon;
  final String? errorText;
  final bool obscureText;
  final bool enabled;
  final bool isLtr;
  final bool latinDigits;
  final int maxLines;
  final int? maxLength;
  final bool autofocus;
  final AutovalidateMode? autovalidateMode;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final formatters = <TextInputFormatter>[
      if (widget.latinDigits) const LatinDigitsFormatter(),
      ...?widget.inputFormatters,
    ];

    Widget? suffix;
    if (widget.obscureText) {
      suffix = IconButton(
        tooltip: _obscured ? l10n.showPassword : l10n.hidePassword,
        icon: Icon(_obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined),
        onPressed: () => setState(() => _obscured = !_obscured),
      );
    }

    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      onChanged: widget.onChanged,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      inputFormatters: formatters.isEmpty ? null : formatters,
      obscureText: _obscured,
      enabled: widget.enabled,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      maxLength: widget.maxLength,
      autofocus: widget.autofocus,
      autovalidateMode: widget.autovalidateMode,
      textDirection: widget.isLtr ? TextDirection.ltr : null,
      textAlign: widget.isLtr ? TextAlign.right : TextAlign.start,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        errorText: widget.errorText,
        prefixIcon: widget.prefixIcon == null ? null : Icon(widget.prefixIcon),
        suffixIcon: suffix,
      ),
    );
  }
}
