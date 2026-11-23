import 'package:fetu/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../../design_system/theme/app_colors.dart';
import '../../../design_system/typography/app_typography.dart';

/// Виджет кнопки «УМНЫЙ ВЫБОР СЕРВЕРА» по спецификации V4.
class SmartSelectionButton extends StatelessWidget {
  const SmartSelectionButton({
    super.key,
    required this.onTap,
    this.isSelected = false,
    this.isLoading = false,
  });

  final VoidCallback? onTap;
  final bool isSelected;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      enabled: !isLoading && onTap != null,
      selected: isSelected,
      label: l10n.smartSelectionTitle,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.smartSelectionDarkGradient
              : AppColors.smartSelectionLightGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.statusConnected
                : AppColors.accentCool.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.statusConnected.withOpacity(0.25),
                blurRadius: 12,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Material(
          color: AppColors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: isLoading ? null : onTap,
            borderRadius: BorderRadius.circular(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    // Иконка в кружочке/квадрате
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.accentCool.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.accentCool,
                              ),
                            )
                          : const Icon(
                              Icons.auto_awesome,
                              color: AppColors.accentCool,
                              size: 22,
                            ),
                    ),
                    const SizedBox(width: 12),

                    // Заголовок и подзаголовок
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  l10n.smartSelectionTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.labelLarge.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.check_circle,
                                  color: AppColors.statusConnected,
                                  size: 16,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.smartSelectionSubtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.accentCool,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
