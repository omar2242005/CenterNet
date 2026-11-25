import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../core/firestore_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/qr_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/sign_out_action.dart';
import '../../linking/cubit/my_students_cubit.dart';
import '../../linking/link_route_names.dart';
import '../../linking/models/linked_student.dart';
import '../../linking/models/student_link.dart';
import '../../linking/repository/linking_repository.dart';
import '../widgets/child_actions.dart';

/// رئيسية الطالب: كارت الـ QR + الجدول والحضور والنتايج + فك الربط.
/// لو الحساب لسه مش مربوط: زر إدخال كود الربط.
class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MyStudentsCubit(sl<LinkingRepository>())..load(),
      child: const _StudentHomeView(),
    );
  }
}

class _StudentHomeView extends StatelessWidget {
  const _StudentHomeView();

  Future<void> _link(BuildContext context) async {
    final cubit = context.read<MyStudentsCubit>();
    final ok = await context.push<bool>(
      LinkRoutes.enter,
      extra: LinkKind.student,
    );
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeStudentTitle),
        actions: [
          IconButton(
            tooltip: l10n.authSignOut,
            icon: const Icon(Icons.logout),
            onPressed: () => confirmAndSignOut(context),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<MyStudentsCubit, MyStudentsState>(
          listenWhen: (a, b) => b.failure != null && b.failure != a.failure,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.failure!.message)),
            );
          },
          builder: (context, state) {
            final cubit = context.read<MyStudentsCubit>();
            return AsyncView<List<LinkedStudent>>(
              state: state.view,
              onRetry: cubit.load,
              emptyMessage: l10n.areaNotLinked,
              emptyIcon: Icons.link_off,
              emptyAction: AppButton(
                label: l10n.areaLinkStudentButton,
                icon: Icons.link,
                expand: false,
                onPressed: () => _link(context),
              ),
              builder: (context, items) {
                final item = items.first;
                final s = item.student;
                return ListView(
                  padding: AppSpacing.screenPadding,
                  children: [
                    QrCard(
                      data: FirestoreIds.qr(s.centerId, s.id),
                      title: s.fullName,
                      subtitle: l10n.studentNumber(s.studentNo),
                      footer: Text(
                        l10n.studentQrHint,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ChildActions(student: s),
                    const SizedBox(height: AppSpacing.lg),
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
            );
          },
        ),
      ),
    );
  }
}
