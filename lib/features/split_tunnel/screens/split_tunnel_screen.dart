import 'package:fetu/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/split_tunnel_constants.dart';
import '../../../design_system/theme/app_colors.dart';
import '../../../design_system/typography/app_typography.dart';
import '../../settings/services/ux_terminology_translator.dart';
import '../controllers/split_tunnel_controller.dart';
import '../models/split_rule.dart';
import '../services/preset_rule_sets.dart';
import '../widgets/add_rule_dialog.dart';
import '../widgets/preset_set_tile.dart';
import '../widgets/rule_list_item.dart';

/// Экран управления правилами раздельного туннелирования.
///
/// Тонкий оркестратор: показывает пресеты и список правил,
/// делегирует всю логику [SplitTunnelController].
class SplitTunnelScreen extends StatelessWidget {
  /// Создаёт экран правил.
  const SplitTunnelScreen({super.key});

  Future<void> _openRuleDialog(
    BuildContext context,
    SplitTunnelController controller, {
    SplitRule? initial,
  }) async {
    final result = await showDialog<RuleFormResult>(
      context: context,
      builder: (_) => AddRuleDialog(initial: initial),
    );
    if (result == null) return;

    final (type, pattern, action) = result;
    if (initial == null) {
      await controller.addRule(type: type, pattern: pattern, action: action);
    } else {
      await controller.updateRule(
        initial.id,
        type: type,
        pattern: pattern,
        action: action,
      );
    }
    if (context.mounted) _showErrorIfAny(context, controller);
  }

  void _showErrorIfAny(
    BuildContext context,
    SplitTunnelController controller,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final code = controller.errorCode;
    if (code == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            UxTerminologyTranslator.splitTunnelErrorLabel(l10n, code),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = context.watch<SplitTunnelController>();
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          l10n.splitTitle,
          style: AppTypography.h3.copyWith(color: textPrimary),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accentCool,
        foregroundColor: AppColors.darkTextPrimary,
        tooltip: l10n.splitTooltipAddRule,
        onPressed: () => _openRuleDialog(context, controller),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(
            top: 8,
            bottom: SplitTunnelConstants.rulesListBottomPadding,
          ),
          children: [
            if (controller.errorCode != null)
              _ErrorBanner(
                message: UxTerminologyTranslator.splitTunnelErrorLabel(
                  l10n,
                  controller.errorCode!,
                ),
              ),
            _SectionHeader(l10n.splitSectionPresets),
            for (final preset in PresetRuleSets.all)
              PresetSetTile(
                preset: preset,
                applied: controller.isPresetApplied(preset.id),
                onApply: () async {
                  await controller.applyPreset(preset.id);
                  if (context.mounted) _showErrorIfAny(context, controller);
                },
                onRemove: () async {
                  await controller.removePreset(preset.id);
                  if (context.mounted) _showErrorIfAny(context, controller);
                },
              ),
            _SectionHeader(l10n.splitSectionMyRules),
            if (!controller.hasRules)
              _EmptyRulesHint(message: l10n.splitEmptyRules)
            else
              for (final rule in controller.rules)
                RuleListItem(
                  rule: rule,
                  onTap: () =>
                      _openRuleDialog(context, controller, initial: rule),
                  onToggle: (value) async {
                    await controller.setRuleEnabled(rule.id, value);
                    if (context.mounted) {
                      _showErrorIfAny(context, controller);
                    }
                  },
                  onDelete: () async {
                    await controller.removeRule(rule.id);
                    if (context.mounted) _showErrorIfAny(context, controller);
                  },
                ),
          ],
        ),
      ),
    );
  }
}

/// Баннер ошибки операции (персистентность, reload и т.п.).
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.statusError
            .withOpacity(SplitTunnelConstants.errorBannerBackgroundOpacity),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.statusError
              .withOpacity(SplitTunnelConstants.errorBannerBorderOpacity),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.statusError),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.statusError,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Заголовок секции экрана.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
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

/// Подсказка пустого списка правил.
class _EmptyRulesHint extends StatelessWidget {
  const _EmptyRulesHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        children: [
          Icon(
            Icons.alt_route,
            size: SplitTunnelConstants.emptyStateIconSize,
            color: (isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary)
                .withOpacity(SplitTunnelConstants.emptyStateIconOpacity),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
