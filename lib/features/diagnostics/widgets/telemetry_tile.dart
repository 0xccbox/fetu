import 'package:flutter/material.dart';

import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/typography/app_typography.dart';

/// Плитка метрики телеметрии (label → value) для экрана диагностики.
class TelemetryTile extends StatelessWidget {
  /// Создаёт плитку.
  const TelemetryTile({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  /// Подпись метрики.
  final String label;

  /// Значение метрики.
  final String value;

  /// Акцентный цвет значения (по умолчанию — основной текст).
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(color: textSecondary),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: valueColor ??
                  (isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
