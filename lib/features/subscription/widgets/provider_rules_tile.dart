import 'package:fetu/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/typography/app_typography.dart';

/// Строка «Правила провайдера (N)» с кнопкой применения
/// (интеграция ФАЗ 8 + ФАЗ 9).
class ProviderRulesTile extends StatelessWidget {
  /// Создаёт строку.
  const ProviderRulesTile({
    super.key,
    required this.rulesCount,
    required this.onApply,
  });

  /// Число применимых правил.
  final int rulesCount;

  /// Обработчик применения правил.
  final VoidCallback onApply;

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
        leading: const Icon(Icons.alt_route, color: AppColors.accentCool),
        title: Text(
          l10n.providerRulesTitle(rulesCount),
          style: AppTypography.labelMedium.copyWith(color: textPrimary),
        ),
        subtitle: Text(
          l10n.providerRulesSubtitle,
          style: AppTypography.caption.copyWith(color: textSecondary),
        ),
        trailing: FilledButton.tonal(
          onPressed: onApply,
          child: Text(l10n.actionApply),
        ),
      ),
    );
  }
}
