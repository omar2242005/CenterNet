import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/digits.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../cubit/link_request_cubit.dart';
import '../models/link_request.dart';
import '../models/student_link.dart';
import '../repository/linking_repository.dart';

/// طلب ربط للأدمن: كود السنتر + رقم الطالب (+ صلة القرابة لولي الأمر).
/// بعد موافقة الأدمن بيكمّل الربط من نفس الشاشة. بترجّع `true` لو الربط تم.
class LinkRequestScreen extends StatelessWidget {
  const LinkRequestScreen({super.key, required this.kind});

  final LinkKind kind;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LinkRequestCubit(sl<LinkingRepository>(), kind),
      child: _LinkRequestView(kind: kind),
    );
  }
}

class _LinkRequestView extends StatefulWidget {
  const _LinkRequestView({required this.kind});

  final LinkKind kind;

  @override
  State<_LinkRequestView> createState() => _LinkRequestViewState();
}

class _LinkRequestViewState extends State<_LinkRequestView> {
  final _center = TextEditingController();
  final _number = TextEditingController();
  String? _relation;

  @override
  void dispose() {
    _center.dispose();
    _number.dispose();
    super.dispose();
  }

  int? get _studentNo => int.tryParse(toLatinDigits(_number.text.trim()));

  bool get _canSend =>
      _center.text.trim().isNotEmpty &&
      (_studentNo ?? 0) > 0 &&
      (widget.kind == LinkKind.student || _relation != null);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isGuardian = widget.kind == LinkKind.guardian;
    final relations = [
      l10n.relationFather,
      l10n.relationMother,
      l10n.relationBrother,
      l10n.relationSister,
      l10n.relationOther,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.linkRequestTitle)),
      body: SafeArea(
        child: BlocConsumer<LinkRequestCubit, LinkRequestState>(
          listener: (context, state) {
            if (state.done) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.linkSuccess)),
              );
              context.pop(true);
            } else if (state.failure != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.failure!.message)),
              );
            }
          },
          builder: (context, state) {
            final cubit = context.read<LinkRequestCubit>();
            final request = state.request;
            if (request != null) {
              return _StatusView(
                request: request,
                busy: state.busy,
                onRefresh: cubit.refresh,
                onComplete: cubit.complete,
                onRetry: cubit.retry,
              );
            }
            return ListView(
              padding: AppSpacing.screenPadding,
              children: [
                Text(
                  l10n.linkRequestIntro,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _center,
                  label: l10n.linkRequestCenterCode,
                  isLtr: true,
                  enabled: !state.busy,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _number,
                  label: l10n.linkRequestStudentNo,
                  keyboardType: TextInputType.number,
                  isLtr: true,
                  latinDigits: true,
                  enabled: !state.busy,
                  onChanged: (_) => setState(() {}),
                ),
                if (isGuardian) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.linkIssueRelationTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      for (final r in relations)
                        ChoiceChip(
                          label: Text(r),
                          selected: _relation == r,
                          onSelected: (_) => setState(() => _relation = r),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: l10n.linkRequestSend,
                  icon: Icons.send_outlined,
                  isLoading: state.busy,
                  onPressed: _canSend
                      ? () => cubit.send(
                            centerId: _center.text,
                            studentNo: _studentNo!,
                            relation: isGuardian ? _relation : null,
                          )
                      : null,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// حالة الطلب بعد الإرسال: انتظار / موافقة / رفض.
class _StatusView extends StatelessWidget {
  const _StatusView({
    required this.request,
    required this.busy,
    required this.onRefresh,
    required this.onComplete,
    required this.onRetry,
  });

  final LinkRequest request;
  final bool busy;
  final VoidCallback onRefresh;
  final VoidCallback onComplete;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (text, label, action) = switch (request.status) {
      LinkRequestStatus.pending => (
          l10n.linkRequestPending,
          l10n.linkRequestRefresh,
          onRefresh,
        ),
      LinkRequestStatus.approved => (
          l10n.linkRequestApproved,
          l10n.linkRequestComplete,
          onComplete,
        ),
      LinkRequestStatus.rejected => (
          l10n.linkRequestRejected,
          l10n.linkRequestRetry,
          onRetry,
        ),
    };
    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.studentNumber(request.studentNo),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(text),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton(label: label, isLoading: busy, onPressed: action),
      ],
    );
  }
}
