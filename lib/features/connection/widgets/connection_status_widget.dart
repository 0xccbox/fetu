import 'package:fetu/design_system/design_system.dart';
import 'package:fetu/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../settings/controllers/settings_controller.dart';
import '../../settings/services/ux_terminology_translator.dart';
import '../controllers/connection_controller.dart';
import '../models/connection_metrics.dart';
import '../models/connection_state.dart' as vpn;

/// Статус и метрики текущей VPN-сессии; подписка на метрики локальна.
class ConnectionStatusWidget extends StatelessWidget {
  /// Создаёт панель состояния под основной кнопкой подключения.
  const ConnectionStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final (state, error, protocol) = context.select(
      (ConnectionController c) =>
          (c.state, c.errorCode, c.currentNode?.protocol),
    );
    final mode = context.select((SettingsController c) => c.mode);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StatusBadge(
          status: switch (state) {
            vpn.ConnectionState.disconnected => ConnectionStatus.disconnected,
            vpn.ConnectionState.connecting ||
            vpn.ConnectionState.disconnecting =>
              ConnectionStatus.connecting,
            vpn.ConnectionState.connected => ConnectionStatus.connected,
            vpn.ConnectionState.error => ConnectionStatus.error,
          },
          label: UxTerminologyTranslator.connectionStateLabel(l10n, state),
        ),
        if (state.isActive) ...[
          if (protocol != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                l10n.homeProtectionMode(
                  UxTerminologyTranslator.protocolLabel(
                    l10n,
                    mode,
                    protocol,
                  ),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption
                    .copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          const SizedBox(height: 10),
          const _SessionMetrics(),
        ],
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Semantics(
              liveRegion: true,
              child: Text(
                UxTerminologyTranslator.connectionErrorLabel(l10n, error),
                style: AppTypography.bodySmall
                    .copyWith(color: theme.colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class _SessionMetrics extends StatelessWidget {
  const _SessionMetrics();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final metrics = context.select((ConnectionController c) => c.metrics);
    final ping = metrics.latency;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _metric(
                  context,
                  l10n.metricPing,
                  ping == null
                      ? l10n.telemetryNoValue
                      : l10n.telemetryLatencyValue(ping),
                ),
              ),
              Expanded(
                child: _metric(
                  context,
                  l10n.metricTime,
                  ConnectionMetrics.formatDuration(
                    metrics.connectionDuration,
                    alwaysShowHours: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _metric(
                  context,
                  l10n.homeDownload,
                  ConnectionMetrics.formatSpeed(metrics.downloadSpeed),
                ),
              ),
              Expanded(
                child: _metric(
                  context,
                  l10n.metricTraffic,
                  ConnectionMetrics.formatBytes(
                    metrics.totalDownloaded + metrics.totalUploaded,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(BuildContext context, String label, String value) => Column(
        children: [
          Text(
            value,
            style: AppTypography.mono,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
}
