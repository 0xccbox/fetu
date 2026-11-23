import 'package:fetu/design_system/design_system.dart';
import 'package:fetu/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/server_constants.dart';
import '../models/server_info.dart';

/// Элемент списка серверов (страна, название, задержка, рейтинг, выбор).
class ServerListItem extends StatelessWidget {
  /// Создаёт карточку сервера.
  const ServerListItem({
    super.key,
    required this.info,
    required this.selected,
    required this.onTap,
  });

  /// Данные сервера и замера задержки.
  final ServerInfo info;

  /// Выбран ли сервер.
  final bool selected;

  /// Обработчик выбора.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final latency = info.latencyMs;
    final pingColor = _latencyColor(latency, scheme.onSurfaceVariant);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      color: selected
          ? Color.alphaBlend(
              scheme.primary.withOpacity(0.12),
              scheme.surface,
            )
          : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? scheme.primary : theme.dividerColor,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(
          info.name.isEmpty ? info.id : info.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          [
            if (info.country != null && info.country!.isNotEmpty) info.country!,
            if (info.city != null && info.city!.isNotEmpty) info.city!,
            if (info.healthScore != null)
              l10n.serverHealthScoreValue(info.healthScore!.score.round()),
          ].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.caption.copyWith(color: scheme.onSurfaceVariant),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              latency == null
                  ? l10n.telemetryNoValue
                  : l10n.telemetryLatencyValue(latency),
              style: AppTypography.monoSmall.copyWith(color: pingColor),
            ),
            if (selected) ...[
              const SizedBox(width: 8),
              Icon(Icons.check_circle_rounded, color: scheme.primary),
            ],
          ],
        ),
      ),
    );
  }

  static Color _latencyColor(int? latency, Color fallback) {
    if (latency == null) return fallback;
    if (latency <= ServerConstants.goodLatencyThresholdMs) {
      return AppColors.statusConnected;
    }
    if (latency <= ServerConstants.mediumLatencyThresholdMs) {
      return AppColors.statusConnecting;
    }
    return AppColors.statusError;
  }
}
