import 'package:flutter/material.dart';

import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/typography/app_typography.dart';

/// Ряд настроек с названием и текущим значением (режимы, переходы).
class SettingsRow extends StatelessWidget {
  /// Создаёт ряд.
  const SettingsRow({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.leading,
  });

  /// Название настройки.
  final String title;

  /// Подзаголовок/описание.
  final String? subtitle;

  /// Хвост ряда (switch, chevron и т.п.).
  final Widget? trailing;

  /// Иконка слева.
  final Widget? leading;

  /// Обработчик тапа (null — ряд не кликабельный).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Semantics(
      button: onTap != null,
      label: title,
      child: ListTile(
        onTap: onTap,
        leading: leading,
        title: Text(
          title,
          style: AppTypography.labelLarge.copyWith(color: textPrimary),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle!,
                style: AppTypography.caption.copyWith(color: textSecondary),
              ),
        trailing: onTap != null && trailing == null
            ? Icon(
                Icons.chevron_right,
                color: textSecondary,
              )
            : trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      ),
    );
  }
}
