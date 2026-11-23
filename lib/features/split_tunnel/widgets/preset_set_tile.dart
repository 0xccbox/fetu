import 'package:fetu/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../services/preset_rule_sets.dart';
import 'rule_l10n.dart';

/// Карточка предустановленного набора правил Split Tunneling.
///
/// Показывает локализованное название, описание и число правил;
/// позволяет применить набор или убрать его правила.
class PresetSetTile extends StatelessWidget {
  /// Создаёт карточку пресета.
  const PresetSetTile({
    super.key,
    required this.preset,
    required this.applied,
    required this.onApply,
    required this.onRemove,
  });

  /// Отображаемый набор.
  final PresetRuleSet preset;

  /// Полностью ли применён набор.
  final bool applied;

  /// Обработчик применения набора.
  final VoidCallback onApply;

  /// Обработчик удаления правил набора.
  final VoidCallback onRemove;

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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        onTap: applied ? onRemove : onApply,
        leading: Icon(
          applied ? Icons.check_circle : Icons.playlist_add,
          color: applied ? AppColors.statusConnected : AppColors.accentCool,
        ),
        title: Text(
          preset.id.presetTitle(l10n),
          style: AppTypography.labelLarge.copyWith(color: textPrimary),
        ),
        subtitle: Text(
          '${preset.id.presetDescription(l10n)} · '
          '${l10n.presetDomainsSuffix(preset.rules.length)}',
          style: AppTypography.caption.copyWith(color: textSecondary),
        ),
        trailing: applied
            ? IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: l10n.splitTooltipRemovePreset,
                onPressed: onRemove,
              )
            : IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: l10n.splitTooltipApplyPreset,
                onPressed: onApply,
              ),
      ),
    );
  }
}
