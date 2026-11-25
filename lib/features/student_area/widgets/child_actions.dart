import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../students/models/student.dart';
import '../child_route_names.dart';

/// أزرار الجدول والحضور والنتايج لطالب معيّن. مشتركة بين رئيسية الطالب وولي الأمر.
class ChildActions extends StatelessWidget {
  const ChildActions({super.key, required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton(
          label: l10n.areaScheduleTitle,
          icon: Icons.calendar_month_outlined,
          variant: AppButtonVariant.secondary,
          onPressed: () => context.push(ChildRoutes.schedule, extra: student),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: l10n.areaAttendanceTitle,
          icon: Icons.fact_check_outlined,
          variant: AppButtonVariant.secondary,
          onPressed: () => context.push(ChildRoutes.attendance, extra: student),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: l10n.areaResultsTitle,
          icon: Icons.grading_outlined,
          variant: AppButtonVariant.secondary,
          onPressed: () => context.push(ChildRoutes.results, extra: student),
        ),
      ],
    );
  }
}
