import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// حقل بحث بأيقونة وزر مسح. بيستدعي [onChanged] بالنص الخام؛ التطبيع
/// (`normalizeArabic` / `matchesSearch`) مسؤولية اللي بيفلتر.
class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    required this.onChanged,
    this.controller,
    this.hint,
    this.autofocus = false,
  });

  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  /// الافتراضي "بحث" من arb.
  final String? hint;
  final bool autofocus;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  TextEditingController? _own;

  TextEditingController get _controller =>
      widget.controller ?? (_own ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _own)?.removeListener(_onTextChanged);
      _controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _own?.dispose();
    super.dispose();
  }

  // بيعيد بناء الحقل عشان زر المسح يظهر ويختفي.
  void _onTextChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasText = _controller.text.isNotEmpty;

    return TextField(
      controller: _controller,
      autofocus: widget.autofocus,
      textInputAction: TextInputAction.search,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: widget.hint ?? l10n.searchHint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: hasText
            ? IconButton(
                tooltip: l10n.clearSearch,
                icon: const Icon(Icons.close),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                },
              )
            : null,
      ),
    );
  }
}
