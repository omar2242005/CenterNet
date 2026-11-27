import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../core/state/view_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../l10n/app_localizations.dart';
import '../../linking/cubit/my_students_cubit.dart';
import '../../linking/link_route_names.dart';
import '../../linking/models/linked_student.dart';
import '../../linking/models/student_link.dart';
import '../../linking/repository/linking_repository.dart';
import '../../student_area/child_route_names.dart';
import '../../student_area/models/updates_args.dart';
import '../../student_area/widgets/child_shell.dart';
import '../../student_area/widgets/summary_cards.dart';

/// رئيسية ولي الأمر: اختيار الابن (لو أكتر من واحد) + كروت الابن المختار
/// + ربط طالب آخر (بكود أو بطلب للسنتر) + فك الربط.
/// [initialStudentId] هو الابن المفتوح لما نرجع للرئيسية من تبويب تاني.
class GuardianHomeScreen extends StatelessWidget {
  const GuardianHomeScreen({super.key, this.initialStudentId});

  final String? initialStudentId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MyStudentsCubit(sl<LinkingRepository>())..load(),
      child: _GuardianHomeView(initialStudentId: initialStudentId),
    );
  }
}

class _GuardianHomeView extends StatefulWidget {
  const _GuardianHomeView({this.initialStudentId});

  final String? initialStudentId;

  @override
  State<_GuardianHomeView> createState() => _GuardianHomeViewState();
}

class _GuardianHomeViewState extends State<_GuardianHomeView> {
  /// الابن المختار (بالـ id). لو اختفى بعد فك ربط بنرجع لأول واحد.
  late String? _selectedId = widget.initialStudentId;

  Future<void> _link(BuildContext context, String route) async {
    final cubit = context.read<MyStudentsCubit>();
    final ok = await context.push<bool>(route, extra: LinkKind.guardian);
    if (ok == true && !cubit.isClosed) await cubit.load();
  }

  Future<void> _unlink(BuildContext context, LinkedStudent item) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<MyStudentsCubit>();
    final ok = await showConfirmDialog(
      context,
      title: l10n.linkUnlinkTitle,
      message: l10n.linkUnlinkMessage(item.student.fullName),
      confirmLabel: l10n.linkUnlink,
      destructive: true,
    );
    if (ok) await cubit.unlink(item);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return BlocConsumer<MyStudentsCubit, MyStudentsState>(
      listenWhen: (a, b) => b.failure != null && b.failure != a.failure,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.failure!.message)),
        );
      },
      builder: (context, state) {
        final cubit = context.read<MyStudentsCubit>();
        final view = state.view;
        final all = view is ViewSuccess<List<LinkedStudent>> ? view.data : null;
        // الابن المختار؛ لو اختفى بعد فك ربط بنرجع لأول واحد.
        final selected = all?.firstWhere(
          (i) => i.student.id == _selectedId,
          orElse: () => all.first,
        );
        return ChildShell(
          current: ChildTab.home,
          title: l10n.homeGuardianTitle,
          student: selected?.student,
          actions: [
            if (all != null)
              IconButton(
                tooltip: l10n.updatesBellGuardian,
                icon: const Icon(Icons.notifications_none),
                onPressed: () => context.push(
                  ChildRoutes.updates,
                  extra: UpdatesArgs(
                    students: [for (final i in all) i.student],
                    guardian: true,
                  ),
                ),
              ),
          ],
          body: AsyncView<List<LinkedStudent>>(
            state: view,
            onRetry: cubit.load,
            emptyMessage: l10n.guardianNoChildren,
            emptyIcon: Icons.family_restroom,
            emptyAction: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppButton(
                  label: l10n.guardianLinkChild,
                  icon: Icons.link,
                  expand: false,
                  onPressed: () => _link(context, LinkRoutes.enter),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: l10n.linkRequestOpen,
                  icon: Icons.send_outlined,
                  variant: AppButtonVariant.secondary,
                  expand: false,
                  onPressed: () => _link(context, LinkRoutes.request),
                ),
              ],
            ),
            builder: (context, items) {
              final item = selected!;
              final s = item.student;
              return ListView(
                padding: AppSpacing.screenPadding,
                children: [
                  if (items.length > 1) ...[
                    Text(
                      l10n.guardianChooseChild,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final i in items)
                          ChoiceChip(
                            label: Text(i.student.fullName),
                            selected: i.student.id == s.id,
                            onSelected: (_) =>
                                setState(() => _selectedId = i.student.id),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.fullName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.studentNumber(s.studentNo),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (s.grade.isNotEmpty)
                          Text(
                            l10n.studentGradeLabel(s.grade),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        if ((item.link.relation ?? '').isNotEmpty)
                          Text(
                            l10n.guardianRelation(item.link.relation!),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SummaryCards(key: ValueKey(s.id), student: s),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: l10n.childOverviewTitle,
                    icon: Icons.insights_outlined,
                    variant: AppButtonVariant.secondary,
                    onPressed: () =>
                        context.push(ChildRoutes.overview, extra: s),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: l10n.guardianAddChild,
                    icon: Icons.add_link,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => _link(context, LinkRoutes.enter),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: l10n.linkRequestOpen,
                    icon: Icons.send_outlined,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => _link(context, LinkRoutes.request),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: l10n.linkUnlink,
                    icon: Icons.link_off,
                    variant: AppButtonVariant.destructive,
                    isLoading: state.busy,
                    onPressed: () => _unlink(context, item),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
