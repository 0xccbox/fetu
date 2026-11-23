import 'package:fetu/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../../settings/models/ui_experience_mode.dart';

/// Карточка выбора режима интерфейса (простой/расширенный).
///
/// Показывает иконку, название и описание; тап выбирает режим.
class ModeOptionCard extends StatelessWidget {
  /// Создаёт карточку.
  const ModeOptionCard({
    super.key,
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  /// Режим, который выбирает карточка.
  final UiExperienceMode mode;

  /// Выбран ли режим сейчас.
  final bool selected;

  /// Обработчик выбора.
  final VoidCallback onTap;

  bool get _isSimple => mode == UiExperienceMode.simple;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent = selected ? AppColors.accentCool : null;

    return Semantics(
      button: true,
      selected: selected,
      label: _isSimple ? l10n.modeSimpleTitle : l10n.modeAdvancedTitle,
      child: Card(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: accent ??
                (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: selected ? 2 : 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _isSimple ? Icons.sentiment_satisfied : Icons.engineering,
                  size: 32,
                  color: accent ?? AppColors.accentCool,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isSimple
                            ? l10n.modeSimpleTitle
                            : l10n.modeAdvancedTitle,
                        style: AppTypography.h4.copyWith(color: textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isSimple
                            ? l10n.modeSimpleDescription
                            : l10n.modeAdvancedDescription,
                        style: AppTypography.bodySmall.copyWith(
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
