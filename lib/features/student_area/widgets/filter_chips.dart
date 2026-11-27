import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// صف فلاتر (اختيار واحد). [options] = القيمة ونص الزر.
class FilterChips<T> extends StatelessWidget {
  const FilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final Map<T, String> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        for (final e in options.entries)
          ChoiceChip(
            label: Text(e.value),
            selected: e.key == selected,
            onSelected: (_) => onSelected(e.key),
          ),
      ],
    );
  }
}
