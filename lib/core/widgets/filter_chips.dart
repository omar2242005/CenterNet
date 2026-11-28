import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// صف فلاتر (اختيار واحد) بيستخدم في كل الشاشات: [options] = القيمة ونص الزر.
///
/// الافتراضي [Wrap] بيلتف على سطرين لو المساحة ما كفتش. لو الفلاتر كتير
/// (زي فلاتر الحضور) خلي [scrollable] true فيبقى صف أفقي بيتسحب.
class FilterChips<T> extends StatelessWidget {
  const FilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.scrollable = false,
    this.padding,
  });

  final Map<T, String> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final bool scrollable;

  /// بيتطبق على الصف بس (في حالة [scrollable]).
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final entries = options.entries.toList();
    if (!scrollable) {
      return Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final e in entries)
            ChoiceChip(
              label: Text(e.value),
              selected: e.key == selected,
              onSelected: (_) => onSelected(e.key),
            ),
        ],
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            ChoiceChip(
              label: Text(entries[i].value),
              selected: entries[i].key == selected,
              onSelected: (_) => onSelected(entries[i].key),
            ),
            if (i != entries.length - 1) const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
