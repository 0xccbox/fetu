import 'package:fetu/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../models/provider_cabinet.dart';
import '../models/subscription_node.dart';

/// Элемент списка узлов подписки: имя, бейджи, протоколы, подключение.
class NodeListTile extends StatelessWidget {
  /// Создаёт элемент узла.
  const NodeListTile({
    super.key,
    required this.node,
    required this.badges,
    required this.onConnect,
    this.actionLabel,
    this.isSelected = false,
  });

  /// Узел подписки.
  final SubscriptionNode node;

  /// Каталог бейджей (id → метка).
  final Map<String, NodeBadge> badges;

  /// Обработчик подключения.
  final VoidCallback? onConnect;

  /// Подпись действия, если плитка используется для выбора сервера.
  final String? actionLabel;

  /// Отмечает выбранный сервер.
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final badgeLabels = node.badges;

    return Card(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    node.name.isEmpty ? node.id : node.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        AppTypography.labelLarge.copyWith(color: textPrimary),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: onConnect,
                  icon: Icon(
                    isSelected ? Icons.check_circle : Icons.power_settings_new,
                    size: 18,
                  ),
                  label: Text(actionLabel ?? l10n.nodeConnect),
                ),
              ],
            ),
            if (badgeLabels.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final badgeId in badgeLabels)
                    _badgeChip(context, badgeId),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              node.protocols
                  .map((p) => p.protocolType?.displayName ?? p.type)
                  .join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.monoSmall.copyWith(color: textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badgeChip(BuildContext context, String badgeId) {
    final badge = badges[badgeId];
    final label = badge?.label ?? badgeId;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accentCool.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(color: AppColors.accentCool),
      ),
    );
  }
}
