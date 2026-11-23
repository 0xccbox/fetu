import 'package:fetu/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design_system/theme/app_colors.dart';
import '../../../design_system/typography/app_typography.dart';
import '../../settings/controllers/settings_controller.dart';
import '../../settings/models/ui_experience_mode.dart';
import '../widgets/mode_option_card.dart';

/// Экран выбора режима интерфейса при первом запуске.
///
/// Одна страница без карусели (AGENTS.md, правило 19): выбор
/// «Простой»/«Расширенный» сохраняется через [SettingsController].
class ModeSelectionScreen extends StatelessWidget {
  /// Создаёт экран.
  const ModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shield,
                  size: 72,
                  color: AppColors.accentCool.withOpacity(0.8),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.modeSelectionTitle,
                  style: AppTypography.h3.copyWith(color: textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.modeSelectionSubtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                ModeOptionCard(
                  mode: UiExperienceMode.simple,
                  selected: false,
                  onTap: () => context
                      .read<SettingsController>()
                      .setMode(UiExperienceMode.simple),
                ),
                ModeOptionCard(
                  mode: UiExperienceMode.advanced,
                  selected: false,
                  onTap: () => context
                      .read<SettingsController>()
                      .setMode(UiExperienceMode.advanced),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.modeSelectionHint,
                  style: AppTypography.caption.copyWith(
                    color: textSecondary.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
