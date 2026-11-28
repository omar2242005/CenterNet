import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/search_field.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/admin_shell.dart';
import '../../students/cubit/students_list_cubit.dart';
import '../../students/models/student.dart';
import '../../students/repository/students_repository.dart';
import '../../students/student_route_names.dart';

/// شاشة "الطلاب" (للأدمن): قائمة + بحث بالتطبيع العربي + إضافة + أرشيف.
class StudentsListScreen extends StatelessWidget {
  const StudentsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StudentsListCubit(sl<StudentsRepository>())..load(),
      child: const _StudentsListView(),
    );
  }
}

class _StudentsListView extends StatelessWidget {
  const _StudentsListView();

  /// بنفتح الشاشة وبعد الرجوع بنحمّل القائمة من جديد (أي تغيير ممكن حصل).
  Future<void> _open(BuildContext context, String route, {Student? extra}) async {
    final cubit = context.read<StudentsListCubit>();
    await context.push<Student>(route, extra: extra);
    if (!cubit.isClosed) await cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AdminShell(
      current: AdminTab.students,
      title: l10n.studentsListTitle,
      actions: [
        BlocBuilder<StudentsListCubit, StudentsListState>(
          buildWhen: (a, b) => a.showArchived != b.showArchived,
          builder: (context, state) => IconButton(
            tooltip: state.showArchived
                ? l10n.studentsHideArchived
                : l10n.studentsShowArchived,
            icon: Icon(
              state.showArchived
                  ? Icons.inventory_2
                  : Icons.inventory_2_outlined,
            ),
            onPressed: () => context
                .read<StudentsListCubit>()
                .setShowArchived(!state.showArchived),
          ),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(context, StudentRoutes.create),
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(l10n.studentsAddTitle),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                0,
              ),
              child: SearchField(
                hint: l10n.studentsSearchHint,
                onChanged: context.read<StudentsListCubit>().setQuery,
              ),
            ),
            Expanded(
              child: BlocBuilder<StudentsListCubit, StudentsListState>(
                builder: (context, state) {
                  return AsyncView<List<Student>>(
                    state: state.view,
                    onRetry: context.read<StudentsListCubit>().load,
                    emptyMessage: state.query.trim().isNotEmpty
                        ? l10n.studentsNoResults
                        : l10n.studentsEmpty,
                    emptyIcon: Icons.school_outlined,
                    builder: (context, students) => ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        // مسافة تحت عشان الزر العايم مايغطيش آخر طالب.
                        AppSpacing.xl * 3,
                      ),
                      itemCount: students.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) => _StudentTile(
                        student: students[index],
                        onTap: () => _open(
                          context,
                          StudentRoutes.detail,
                          extra: students[index],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  const _StudentTile({required this.student, required this.onTap});

  final Student student;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.fullName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: student.isArchived
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  student.grade.isEmpty
                      ? l10n.studentNumber(student.studentNo)
                      : '${l10n.studentNumber(student.studentNo)} · '
                          '${student.grade}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (student.isArchived) ...[
            const SizedBox(width: AppSpacing.sm),
            StatusBadge(label: l10n.studentArchivedBadge),
          ],
        ],
      ),
    );
  }
}
