import 'package:flutter/material.dart';

import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/typography/app_typography.dart';

/// Заголовок секции экрана настроек.
class SettingsSection extends StatelessWidget {
  /// Создаёт заголовок.
  const SettingsSection({super.key, required this.title});

  /// Название секции.
  final String title;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 4),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.overline.copyWith(
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        ),
      ),
    );
  }
}
