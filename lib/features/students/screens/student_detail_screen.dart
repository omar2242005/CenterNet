import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../core/firestore_paths.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/qr_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../cubit/student_detail_cubit.dart';
import '../models/student.dart';
import '../repository/students_repository.dart';
import '../student_route_names.dart';

/// ملف الطالب: كارت الـ QR (من غير نت) + البيانات + تعديل + أرشفة/استرجاع.
class StudentDetailScreen extends StatelessWidget {
  const StudentDetailScreen({super.key, required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StudentDetailCubit(sl<StudentsRepository>(), student),
      child: const _StudentDetailView(),
    );
  }
}

class _StudentDetailView extends StatelessWidget {
  const _StudentDetailView();

  Future<void> _edit(BuildContext context, Student student) async {
    final cubit = context.read<StudentDetailCubit>();
    final updated = await context.push<Student>(
      StudentRoutes.edit,
      extra: student,
    );
    if (updated != null && !cubit.isClosed) cubit.replaceStudent(updated);
  }

  Future<void> _archive(BuildContext context, Student student) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<StudentDetailCubit>();
    final ok = await showConfirmDialog(
      context,
      title: l10n.studentArchiveTitle,
      message: l10n.studentArchiveMessage(student.fullName),
      confirmLabel: l10n.studentArchiveConfirm,
      destructive: true,
    );
    if (ok) await cubit.setArchived(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.studentDetailTitle)),
      body: SafeArea(
        child: BlocConsumer<StudentDetailCubit, StudentDetailState>(
          listenWhen: (a, b) => b.failure != null && b.failure != a.failure,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.failure!.message)),
            );
          },
          builder: (context, state) {
            final s = state.student;
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
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (s.isArchived) ...[
                        StatusBadge(label: l10n.studentArchivedBadge),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      Text(
                        l10n.studentPhoneLabel(s.phone),
                        style: theme.textTheme.bodyLarge,
                      ),
                      if (s.grade.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.studentGradeLabel(s.grade),
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: l10n.studentEdit,
                  icon: Icons.edit_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: state.busy ? null : () => _edit(context, s),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (s.isArchived)
                  AppButton(
                    label: l10n.studentRestore,
                    icon: Icons.unarchive_outlined,
                    isLoading: state.busy,
                    onPressed: () =>
                        context.read<StudentDetailCubit>().setArchived(false),
                  )
                else
                  AppButton(
                    label: l10n.studentArchive,
                    icon: Icons.archive_outlined,
                    variant: AppButtonVariant.destructive,
                    isLoading: state.busy,
                    onPressed: () => _archive(context, s),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
