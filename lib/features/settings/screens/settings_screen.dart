import 'package:fetu/core/constants/app_constants.dart';
import 'package:fetu/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design_system/theme/app_colors.dart';
import '../../../design_system/theme/theme_controller.dart';
import '../../../design_system/typography/app_typography.dart';
import '../../diagnostics/screens/diagnostics_screen.dart';
import '../controllers/settings_controller.dart';
import '../models/ui_experience_mode.dart';
import '../widgets/settings_row.dart';
import '../widgets/settings_section.dart';
import '../widgets/subscription_keys_section.dart';

/// Экран настроек: режим интерфейса, оформление, ключи подписки,
/// диагностика (расширенный режим) и версия.
class SettingsScreen extends StatelessWidget {
  /// Создаёт экран.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final settings = context.watch<SettingsController>();
    final theme = context.watch<ThemeController>();

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.settingsTitle,
          style: AppTypography.h3.copyWith(color: textPrimary),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            SettingsSection(title: l10n.settingsSectionInterface),
            _ModeSelector(current: settings.mode),
            SettingsSection(title: l10n.settingsSectionAppearance),
            _ThemeModeSelector(current: theme.themeMode),
            SettingsSection(title: l10n.settingsSectionSubscriptionKeys),
            const SubscriptionKeysSection(),
            if (settings.mode == UiExperienceMode.advanced) ...[
              SettingsSection(title: l10n.settingsSectionAdvanced),
              SettingsRow(
                title: l10n.settingsDiagnosticsTitle,
                subtitle: l10n.settingsDiagnosticsSubtitle,
                leading: const Icon(
                  Icons.monitor_heart_outlined,
                  color: AppColors.accentCool,
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const DiagnosticsScreen(),
                  ),
                ),
              ),
            ],
            SettingsSection(title: l10n.settingsSectionAbout),
            SettingsRow(
              title: l10n.settingsVersion(AppConstants.appVersion),
              leading: Icon(
                Icons.info_outline,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Сегментированный переключатель режима интерфейса.
class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.current});

  final UiExperienceMode current;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: SegmentedButton<UiExperienceMode>(
        segments: [
          ButtonSegment(
            value: UiExperienceMode.simple,
            label: Text(l10n.modeSimpleTitle),
            icon: const Icon(Icons.sentiment_satisfied),
          ),
          ButtonSegment(
            value: UiExperienceMode.advanced,
            label: Text(l10n.modeAdvancedTitle),
            icon: const Icon(Icons.engineering),
          ),
        ],
        selected: {current},
        onSelectionChanged: (selection) =>
            context.read<SettingsController>().setMode(selection.first),
      ),
    );
  }
}

/// Сегментированный переключатель темы оформления.
class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector({required this.current});

  final AppThemeMode current;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: SegmentedButton<AppThemeMode>(
        segments: [
          ButtonSegment(
            value: AppThemeMode.light,
            label: Text(l10n.themeModeLight),
            icon: const Icon(Icons.light_mode),
          ),
          ButtonSegment(
            value: AppThemeMode.dark,
            label: Text(l10n.themeModeDark),
            icon: const Icon(Icons.dark_mode),
          ),
          ButtonSegment(
            value: AppThemeMode.system,
            label: Text(l10n.themeModeSystem),
            icon: const Icon(Icons.auto_mode),
          ),
        ],
        selected: {current},
        onSelectionChanged: (selection) =>
            context.read<ThemeController>().setThemeMode(selection.first),
      ),
    );
  }
}
