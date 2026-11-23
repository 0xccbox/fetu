import 'package:fetu/design_system/design_system.dart';
import 'package:fetu/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../models/subscription_node.dart';
import 'server_location.dart';

/// Выбор узла на главном экране, без кабинетных действий и протокольных деталей.
class ServerSelectionTile extends StatelessWidget {
  /// Создаёт кликабельную карточку или индикатор текущего соединения.
  const ServerSelectionTile({
    super.key,
    required this.node,
    required this.active,
    required this.selected,
    required this.onTap,
    this.latencyMs,
    this.focusNode,
  });

  /// Узел из текущей подписки.
  final SubscriptionNode node;

  /// Туннель установлен на этом узле.
  final bool active;

  /// Узел выбран для будущего подключения.
  final bool selected;

  /// Выбирает узел; null при активном или переходном состоянии туннеля.
  final VoidCallback? onTap;

  /// Кэшированная задержка узла (мс), если измерена.
  final int? latencyMs;

  /// Опциональный фокус для перехода с кнопки «Выбрать сервер».
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final highlighted = active || selected;
    final accent = active ? AppColors.statusConnected : scheme.primary;
    final label = active ? l10n.statusConnected : l10n.homeSelectedServer;
    return Semantics(
      selected: highlighted,
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        clipBehavior: Clip.antiAlias,
        color: highlighted
            ? Color.alphaBlend(accent.withOpacity(0.12), scheme.surface)
            : scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: highlighted ? accent : theme.dividerColor,
            width: highlighted ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          focusNode: focusNode,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                ServerFlagBadge(
                  country: node.country,
                  highlighted: highlighted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serverDisplayName(node),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelLarge
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      ServerLocation(
                        country: node.country,
                        city: node.city,
                        showLeading: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (latencyMs != null) ...[
                  Text(
                    l10n.telemetryLatencyValue(latencyMs!),
                    style: AppTypography.monoSmall.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (highlighted)
                  Icon(
                    active
                        ? Icons.lock_outline_rounded
                        : Icons.check_circle_rounded,
                    color: active ? AppColors.statusConnected : scheme.primary,
                    semanticLabel: label,
                  )
                else if (onTap != null)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
