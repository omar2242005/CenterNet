import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/di.dart';
import '../../../core/errors/failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../students/models/student.dart';
import '../models/invite_code.dart';
import '../repository/linking_repository.dart';

/// (أدمن) زرّين في ملف الطالب: كود ربط للطالب، وكود ربط لولي الأمر (بصلة القرابة).
class IssueLinkCodeSection extends StatefulWidget {
  const IssueLinkCodeSection({super.key, required this.student});

  final Student student;

  @override
  State<IssueLinkCodeSection> createState() => _IssueLinkCodeSectionState();
}

class _IssueLinkCodeSectionState extends State<IssueLinkCodeSection> {
  bool _busy = false;

  Future<String?> _pickRelation(AppLocalizations l10n) {
    final options = <String>[
      l10n.relationFather,
      l10n.relationMother,
      l10n.relationBrother,
      l10n.relationSister,
      l10n.relationOther,
    ];
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(l10n.linkIssueRelationTitle),
        children: [
          for (final o in options)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(o),
              child: Text(o),
            ),
        ],
      ),
    );
  }

  Future<void> _issue({required bool guardian}) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    String? relation;
    if (guardian) {
      relation = await _pickRelation(l10n);
      if (relation == null || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      final invite = await sl<LinkingRepository>().issueCode(
        widget.student,
        relation: relation,
      );
      if (!mounted) return;
      setState(() => _busy = false);
      await _showCode(invite);
    } on Failure catch (f) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(f.message)));
    }
  }

  Future<void> _showCode(InviteCode invite) {
    final l10n = AppLocalizations.of(context);
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          invite.kind == InviteKind.guardian
              ? l10n.linkIssueGuardianCode
              : l10n.linkIssueStudentCode,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Directionality(
              textDirection: TextDirection.ltr,
              child: SelectableText(
                invite.id,
                style: Theme.of(dialogContext).textTheme.headlineMedium
                    ?.copyWith(letterSpacing: 4, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.linkIssueExpires(formatDate(l10n, invite.expiresAt)),
              style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await Clipboard.setData(ClipboardData(text: invite.id));
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(content: Text(l10n.linkIssueCopied)),
              );
            },
            child: Text(l10n.linkIssueCopy),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.linkIssueClose),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (widget.student.isArchived) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton(
          label: l10n.linkIssueStudentCode,
          icon: Icons.qr_code_2,
          variant: AppButtonVariant.secondary,
          isLoading: _busy,
          onPressed: () => _issue(guardian: false),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: l10n.linkIssueGuardianCode,
          icon: Icons.family_restroom,
          variant: AppButtonVariant.secondary,
          isLoading: _busy,
          onPressed: () => _issue(guardian: true),
        ),
      ],
    );
  }
}
