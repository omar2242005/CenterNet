import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../l10n/app_localizations.dart';
import '../../assistant/services/cairo_time.dart';
import '../cubit/teacher_home_cubit.dart';
import '../models/teacher_home_data.dart';
import '../teacher_route_names.dart';
import '../widgets/teacher_shell.dart';

/// رئيسية المعلم: تحية + كارت مجموعاته النشطة + الحصة القادمة + زر "عرض
/// مجموعاتي".
class TeacherHomeScreen extends StatelessWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocProvider(
      create: (_) => sl<TeacherHomeCubit>()..load(),
      child: TeacherShell(
        current: TeacherTab.home,
        title: l10n.homeTeacherTitle,
        body: BlocBuilder<TeacherHomeCubit, TeacherHomeState>(
          builder: (context, state) => AsyncView<TeacherHomeData>(
            state: state.status,
            onRetry: () => context.read<TeacherHomeCubit>().load(),
            emptyMessage: l10n.myGroupsEmpty,
            emptyIcon: Icons.groups_outlined,
            builder: (context, data) => _HomeBody(data: data),
          ),
        ),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.data});

  final TeacherHomeData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        Text(
          data.name.isEmpty
              ? l10n.homeTeacherTitle
              : l10n.teacherGreeting(data.name),
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          formatDate(l10n, toCairoWallTime(data.now)),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        _StatsCard(data: data),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.teacherNextSession, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        _NextSessionCard(data: data),
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: l10n.teacherViewMyGroups,
          icon: Icons.groups_outlined,
          onPressed: () => context.go(TeacherRoutes.groups),
        ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.data});

  final TeacherHomeData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final subjects = data.subjects.join('، ');
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.teacherActiveGroups, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.teacherAcademicYear(
              data.academicYearStart.toString(),
              (data.academicYearStart + 1).toString(),
            ),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                data.groupsCount.toString(),
                style: theme.textTheme.displaySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(l10n.teacherGroupUnit, style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            [
              l10n.teacherStudentsCount(data.studentsCount),
              if (subjects.isNotEmpty) l10n.teacherSubjects(subjects),
            ].join(' · '),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _NextSessionCard extends StatelessWidget {
  const _NextSessionCard({required this.data});

  final TeacherHomeData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final next = data.nextSession;
    if (next == null) {
      return AppCard(
        child: Row(
          children: [
            const Icon(
              Icons.event_busy_outlined,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(l10n.teacherNoNextSession)),
          ],
        ),
      );
    }

    final start = toCairoWallTime(next.session.startAt);
    final end = toCairoWallTime(next.session.endAt);
    final today = toCairoWallTime(data.now);
    final dayDiff = DateTime(
      start.year,
      start.month,
      start.day,
    ).difference(DateTime(today.year, today.month, today.day)).inDays;
    final dayLabel = switch (dayDiff) {
      0 => l10n.teacherToday,
      1 => l10n.teacherTomorrow,
      _ => formatDate(l10n, start),
    };
    final isCurrent = !data.now.isBefore(next.session.startAt);
    final room = next.group.room.trim();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  next.group.subject.isEmpty
                      ? next.group.name
                      : '${next.group.subject} · ${next.group.name}',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              StatusBadge(
                label: isCurrent
                    ? l10n.sessionStatusCurrent
                    : l10n.sessionStatusUpcoming,
                tone: isCurrent ? StatusTone.success : StatusTone.info,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$dayLabel · ${formatTime(l10n, start)} - ${formatTime(l10n, end)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            [
              if (room.isNotEmpty) '${l10n.sessionRoomLabel}: $room',
              l10n.teacherStudentsCount(next.studentCount),
            ].join(' · '),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
