import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_card.dart';

/// كارت الـ QR بتاع الطالب: الرمز + الاسم + الرقم. بيشتغل من غير نت.
///
/// [data] نص الـ QR الجاهز (من دالة paths_firestore، مش بيتبني هنا).
/// الرمز دايمًا أسود على أبيض مهما كان الثيم عشان الـ scanner يقراه.
/// [footer] مكان لزر مشاركة أو أي حاجة تحت الكارت.
class QrCard extends StatelessWidget {
  const QrCard({
    super.key,
    required this.data,
    this.title,
    this.subtitle,
    this.size = 240,
    this.footer,
  });

  final String data;
  final String? title;
  final String? subtitle;
  final double size;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: l10n.qrSemantics,
            image: true,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: QrImageView(
                data: data,
                version: QrVersions.auto,
                size: size,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          if (title != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              title!,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.md),
            footer!,
          ],
        ],
      ),
    );
  }
}
