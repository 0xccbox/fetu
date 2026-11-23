import 'package:fetu/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../models/provider_cabinet.dart';

/// Баннер объявления провайдера (верх списка кабинета).
class ProviderAnnouncementBanner extends StatelessWidget {
  /// Создаёт баннер.
  const ProviderAnnouncementBanner({
    super.key,
    required this.announcement,
    required this.onDismiss,
  });

  /// Объявление.
  final Announcement announcement;

  /// Обработчик скрытия (только для dismissible).
  final VoidCallback onDismiss;

  Color get _accent => switch (announcement.type) {
        'warning' => AppColors.statusWarning,
        'critical' => AppColors.statusError,
        _ => AppColors.accentCool,
      };

  IconData get _icon => switch (announcement.type) {
        'warning' => Icons.warning_amber_outlined,
        'critical' => Icons.error_outline,
        _ => Icons.campaign_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _accent.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, color: _accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  announcement.title,
                  style: AppTypography.labelMedium.copyWith(color: _accent),
                ),
                if (announcement.message != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    announcement.message!,
                    style: AppTypography.bodySmall.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
                if (announcement.actionLabel != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${announcement.actionLabel} →',
                    style: AppTypography.labelSmall.copyWith(color: _accent),
                  ),
                ],
              ],
            ),
          ),
          if (announcement.dismissible)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: l10n.subTooltipHideAnnouncement,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: onDismiss,
            ),
        ],
      ),
    );
  }
}
