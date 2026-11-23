import 'package:fetu/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../models/rule_action.dart';
import '../models/split_rule.dart';
import 'rule_l10n.dart';

/// Элемент списка правил раздельного туннелирования.
///
/// Отображает паттерн, локализованные тип и действие; позволяет
/// редактировать (тап), включать/выключать и удалять правило.
class RuleListItem extends StatelessWidget {
  /// Создаёт элемент правила.
  const RuleListItem({
    super.key,
    required this.rule,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  /// Отображаемое правило.
  final SplitRule rule;

  /// Обработчик редактирования.
  final VoidCallback onTap;

  /// Обработчик переключения активности.
  final ValueChanged<bool> onToggle;

  /// Обработчик удаления.
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(
        rule.action._icon,
        color: rule.enabled ? rule.action._color : AppColors.statusDisconnected,
      ),
      title: Text(
        rule.pattern,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.bodyMedium.copyWith(
          color:
              isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
      ),
      subtitle: Text(
        '${rule.type.label(l10n)} · ${rule.action.label(l10n)}'
        '${rule.builtin ? ' · ${l10n.ruleSourcePreset}' : ''}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.caption.copyWith(
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: rule.enabled
                ? l10n.ruleEnabledSemantic(rule.pattern)
                : l10n.ruleDisabledSemantic(rule.pattern),
            child: Switch(
              value: rule.enabled,
              onChanged: onToggle,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.splitTooltipDeleteRule,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

extension _RuleActionUi on RuleAction {
  IconData get _icon => switch (this) {
        RuleAction.proxy => Icons.vpn_lock_outlined,
        RuleAction.direct => Icons.bolt_outlined,
        RuleAction.block => Icons.block_outlined,
      };

  Color get _color => switch (this) {
        RuleAction.proxy => AppColors.accentCool,
        RuleAction.direct => AppColors.statusConnected,
        RuleAction.block => AppColors.statusError,
      };
}
