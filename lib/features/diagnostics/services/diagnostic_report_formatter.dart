/// Форматирование диагностического отчёта в текст (для копирования/шаринга).
///
/// Правило 16: в текст НЕ попадают адреса серверов, URL и credentials.
library;

import 'package:fetu/l10n/app_localizations.dart';

import '../../connection/models/connection_metrics.dart';
import '../../connection/models/connection_state.dart';
import '../../settings/models/ui_experience_mode.dart';
import '../../subscription/models/provider_cabinet.dart';
import '../models/diagnostic_report.dart';

/// Форматирует [DiagnosticReport] в многострочный текст.
abstract final class DiagnosticReportFormatter {
  /// Собирает текст отчёта на языке [l10n].
  static String format(AppLocalizations l10n, DiagnosticReport report) {
    final snapshot = report.snapshot;
    final lines = <String>[
      l10n.reportLineGenerated(_formatDateTime(report.generatedAt)),
      l10n.reportLineApp(
        report.appVersion,
        switch (snapshot.uiMode) {
          UiExperienceMode.simple => l10n.uiModeSimpleLabel,
          UiExperienceMode.advanced => l10n.uiModeAdvancedLabel,
        },
      ),
      _tunnelLine(l10n, snapshot),
      if (report.hasMetrics) _metricsLine(l10n, snapshot.metrics!),
      report.realDelayMs != null
          ? l10n.reportLineRealDelay(report.realDelayMs!)
          : l10n.reportLineRealDelayMissing,
      l10n.reportLineRules(snapshot.activeSplitRules, snapshot.totalSplitRules),
      _subscriptionLine(l10n, snapshot),
      l10n.reportLineCore(
        snapshot.tunnelMode == 'real'
            ? l10n.tunnelModeReal
            : l10n.tunnelModeMock,
      ),
    ];

    // developer_meta: только в расширенном режиме, без webhook-URL.
    if (snapshot.uiMode == UiExperienceMode.advanced) {
      lines.addAll(_developerMetaLines(l10n, snapshot.developerMeta));
    }

    return lines.join('\n');
  }

  static String _tunnelLine(AppLocalizations l10n, DiagnosticSnapshot s) {
    final state = _connectionStateLabel(l10n, s.connectionState);
    final protocol = s.protocol;
    if (protocol == null) return l10n.reportLineTunnelNoProtocol(state);
    return l10n.reportLineTunnel(state, protocol.displayName);
  }

  static String _connectionStateLabel(
    AppLocalizations l10n,
    ConnectionState state,
  ) =>
      switch (state) {
        ConnectionState.disconnected => l10n.statusDisconnected,
        ConnectionState.connecting => l10n.statusConnecting,
        ConnectionState.connected => l10n.statusConnected,
        ConnectionState.disconnecting => l10n.statusDisconnecting,
        ConnectionState.error => l10n.statusError,
      };

  static String _metricsLine(
    AppLocalizations l10n,
    ConnectionMetrics metrics,
  ) =>
      l10n.reportLineMetrics(
        ConnectionMetrics.formatSpeed(metrics.downloadSpeed),
        ConnectionMetrics.formatSpeed(metrics.uploadSpeed),
        metrics.latency?.toString() ?? l10n.telemetryNoValue,
      );

  static String _subscriptionLine(
    AppLocalizations l10n,
    DiagnosticSnapshot s,
  ) {
    final provider = s.providerName;
    if (provider == null) return l10n.reportLineNoSubscription;

    final expires = s.subscriptionExpiresAt;
    return [
      l10n.reportLineSubscription(provider, s.subscriptionNodeCount ?? 0),
      if (expires != null)
        l10n.reportLineSubscriptionExpires(_formatDateTime(expires)),
    ].join('\n');
  }

  static List<String> _developerMetaLines(
    AppLocalizations l10n,
    DeveloperMeta? meta,
  ) {
    if (meta == null) return [l10n.devMetaEmpty];
    return [
      l10n.devMetaTitle,
      if (meta.configGeneratedMs != null)
        l10n.devMetaGenerated(meta.configGeneratedMs!),
      if (meta.backendNode != null) l10n.devMetaBackend(meta.backendNode!),
      if (meta.abTestGroup != null) l10n.devMetaAbGroup(meta.abTestGroup!),
      if (meta.recommendedUiMode != null)
        l10n.devMetaRecommendedMode(meta.recommendedUiMode!),
      // Webhook — URL: показываем только факт наличия (правило 16).
      if (meta.diagnosticWebhook != null) l10n.devMetaWebhook,
    ];
  }

  static String _formatDateTime(DateTime dateTime) {
    // ISO-формат без локали: в отчёте важна однозначность для разработчиков.
    return dateTime.toLocal().toIso8601String();
  }
}
