import 'package:fetu/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../models/provider_cabinet.dart';

/// Карточка провайдера (`provider_custom_cards`): заголовок, подзаголовок
/// и опциональное копирование значения (реферальный код).
class ProviderCardTile extends StatelessWidget {
  /// Создаёт карточку.
  const ProviderCardTile({
    super.key,
    required this.card,
    required this.onCopy,
  });

  /// Данные карточки.
  final ProviderCard card;

  /// Обработчик копирования (null — кнопка не показывается).
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Card(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: const Icon(
          Icons.card_giftcard_outlined,
          color: AppColors.accentWarm,
        ),
        title: Text(
          card.title,
          style: AppTypography.labelMedium.copyWith(color: textPrimary),
        ),
        subtitle: card.subtitle == null
            ? null
            : Text(
                card.subtitle!,
                style: AppTypography.caption.copyWith(color: textSecondary),
              ),
        trailing: onCopy == null
            ? null
            : IconButton(
                icon: const Icon(Icons.copy),
                tooltip: l10n.subTooltipCopy,
                onPressed: onCopy,
              ),
      ),
    );
  }
}
