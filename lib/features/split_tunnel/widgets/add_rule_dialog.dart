import 'package:fetu/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../models/rule_action.dart';
import '../models/rule_type.dart';
import '../models/split_rule.dart';
import 'rule_l10n.dart';

/// Результат диалога: тип, паттерн и действие правила.
typedef RuleFormResult = (RuleType, String, RuleAction);

/// Диалог добавления/редактирования правила Split Tunneling.
///
/// Чистая форма без бизнес-логики: минимальная проверка (непустой
/// паттерн); валидация паттерна и дубликатов — в контроллере.
/// Возвращает [RuleFormResult] через [Navigator.pop].
class AddRuleDialog extends StatefulWidget {
  /// Создаёт диалог. [initial] — редактируемое правило (null = новое).
  const AddRuleDialog({super.key, this.initial});

  /// Редактируемое правило (null — создание нового).
  final SplitRule? initial;

  @override
  State<AddRuleDialog> createState() => _AddRuleDialogState();
}

class _AddRuleDialogState extends State<AddRuleDialog> {
  late final TextEditingController _patternController;
  late RuleType _type;
  late RuleAction _action;
  String? _patternError;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _patternController = TextEditingController(text: initial?.pattern ?? '');
    _type = initial?.type ?? RuleType.domainSuffix;
    _action = initial?.action ?? RuleAction.proxy;
  }

  @override
  void dispose() {
    _patternController.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final pattern = _patternController.text.trim();
    if (pattern.isEmpty) {
      setState(() => _patternError = l10n.splitPatternRequired);
      return;
    }
    Navigator.of(context).pop<RuleFormResult>((_type, pattern, _action));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return AlertDialog(
      title: Text(
        widget.initial == null ? l10n.splitNewRule : l10n.splitEditRule,
        style: AppTypography.h4.copyWith(color: textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _patternController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.splitFieldPattern,
                labelStyle: AppTypography.bodySmall.copyWith(
                  color: textSecondary,
                ),
                hintText: _type.hint(l10n),
                hintStyle: AppTypography.bodySmall.copyWith(
                  color: textSecondary,
                ),
                errorText: _patternError,
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<RuleType>(
              value: _type,
              decoration: InputDecoration(labelText: l10n.splitFieldType),
              items: [
                for (final type in RuleType.values)
                  DropdownMenuItem(
                    value: type,
                    child: Text(type.label(l10n)),
                  ),
              ],
              onChanged: (value) => setState(() => _type = value ?? _type),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<RuleAction>(
              value: _action,
              decoration: InputDecoration(labelText: l10n.splitFieldAction),
              items: [
                for (final action in RuleAction.values)
                  DropdownMenuItem(
                    value: action,
                    child: Text(action.label(l10n)),
                  ),
              ],
              onChanged: (value) => setState(() => _action = value ?? _action),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.actionSave),
        ),
      ],
    );
  }
}
