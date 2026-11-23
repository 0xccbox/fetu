import 'package:fetu/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../design_system/theme/app_colors.dart';
import '../../../design_system/typography/app_typography.dart';
import '../../connection/models/connection_metrics.dart';
import '../../settings/models/ui_experience_mode.dart';
import '../../settings/services/ux_terminology_translator.dart';
import '../../subscription/models/provider_cabinet.dart';
import '../controllers/diagnostics_controller.dart';
import '../services/diagnostic_report_formatter.dart';
import '../widgets/telemetry_tile.dart';

/// Экран диагностики: Real-Delay, телеметрия туннеля и отчёт.
///
/// Полная телеметрия доступна в расширенном режиме (правило 33);
/// в простом показываются человекочитаемые метрики.
class DiagnosticsScreen extends StatelessWidget {
  /// Создаёт экран.
  const DiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          l10n.diagnosticsTitle,
          style: AppTypography.h3.copyWith(color: textPrimary),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: const [
            _RealDelaySection(),
            _TelemetrySection(),
            _ReportSection(),
          ],
        ),
      ),
    );
  }
}

/// Секция зонда Real-Delay с кнопкой измерения.
class _RealDelaySection extends StatelessWidget {
  const _RealDelaySection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = context.watch<DiagnosticsController>();

    final valueText = controller.realDelayMs == null
        ? l10n.telemetryNoValue
        : l10n.realDelayValue(controller.realDelayMs!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(l10n.realDelayTitle),
        TelemetryTile(label: l10n.realDelayTitle, value: valueText),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              FilledButton.tonalIcon(
                onPressed:
                    controller.isProbing ? null : controller.measureRealDelay,
                icon: controller.isProbing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.speed, size: 18),
                label: Text(l10n.realDelayMeasure),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Секция телеметрии туннеля (протокол, состояние, метрики).
class _TelemetrySection extends StatelessWidget {
  const _TelemetrySection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = context.watch<DiagnosticsController>();
    final report = controller.report;
    if (report == null) return const SizedBox.shrink();

    final snapshot = report.snapshot;
    final metrics = snapshot.metrics;
    final isAdvanced = snapshot.uiMode == UiExperienceMode.advanced;

    final protocolLabel = snapshot.protocol == null
        ? l10n.telemetryNoValue
        : UxTerminologyTranslator.protocolLabel(
            l10n,
            snapshot.uiMode,
            snapshot.protocol!,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(l10n.telemetrySection),
        TelemetryTile(
          label: l10n.telemetryState,
          value: UxTerminologyTranslator.connectionStateLabel(
            l10n,
            snapshot.connectionState,
          ),
        ),
        TelemetryTile(label: l10n.telemetryProtocol, value: protocolLabel),
        TelemetryTile(
          label: l10n.telemetryTunnelMode,
          value: snapshot.tunnelMode == 'real'
              ? l10n.tunnelModeReal
              : l10n.tunnelModeMock,
        ),
        if (metrics != null) ...[
          TelemetryTile(
            label: l10n.telemetryLatency,
            value: metrics.latency == null
                ? l10n.telemetryNoValue
                : l10n.telemetryLatencyValue(metrics.latency!),
          ),
          TelemetryTile(
            label: l10n.telemetryDownload,
            value: ConnectionMetrics.formatSpeed(metrics.downloadSpeed),
          ),
          TelemetryTile(
            label: l10n.telemetryUpload,
            value: ConnectionMetrics.formatSpeed(metrics.uploadSpeed),
          ),
          TelemetryTile(
            label: l10n.telemetryDuration,
            value: ConnectionMetrics.formatDuration(
              metrics.connectionDuration,
            ),
          ),
        ],
        TelemetryTile(
          label: l10n.telemetrySplitRules,
          value: l10n.telemetrySplitRulesValue(
            snapshot.activeSplitRules,
            snapshot.totalSplitRules,
          ),
        ),
        TelemetryTile(
          label: l10n.telemetrySubscription,
          value: snapshot.providerName == null
              ? l10n.telemetryNoValue
              : l10n.telemetrySubscriptionValue(
                  snapshot.providerName!,
                  snapshot.subscriptionNodeCount ?? 0,
                ),
        ),
        // developer_meta — только расширенный режим (правило 33).
        if (isAdvanced) _DeveloperMetaSection(meta: snapshot.developerMeta),
      ],
    );
  }
}

/// Блок developer_meta провайдера (без webhook-URL, правило 16).
class _DeveloperMetaSection extends StatelessWidget {
  const _DeveloperMetaSection({required this.meta});

  final DeveloperMeta? meta;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (meta == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Text(
          l10n.devMetaEmpty,
          style: AppTypography.bodySmall.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(l10n.devMetaTitle),
        if (meta!.configGeneratedMs != null)
          TelemetryTile(
            label: 'config_generated_ms',
            value: l10n.devMetaGenerated(meta!.configGeneratedMs!),
          ),
        if (meta!.backendNode != null)
          TelemetryTile(
            label: 'backend_node',
            value: l10n.devMetaBackend(meta!.backendNode!),
          ),
        if (meta!.abTestGroup != null)
          TelemetryTile(
            label: 'ab_test_group',
            value: l10n.devMetaAbGroup(meta!.abTestGroup!),
          ),
        if (meta!.recommendedUiMode != null)
          TelemetryTile(
            label: 'recommended_ui_mode',
            value: l10n.devMetaRecommendedMode(meta!.recommendedUiMode!),
          ),
        if (meta!.diagnosticWebhook != null)
          TelemetryTile(
            label: 'diagnostic_webhook',
            value: l10n.devMetaWebhook,
          ),
      ],
    );
  }
}

/// Секция диагностического отчёта: текст + копирование/шаринг.
class _ReportSection extends StatelessWidget {
  const _ReportSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = context.watch<DiagnosticsController>();
    final report = controller.report;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final reportText =
        report == null ? '' : DiagnosticReportFormatter.format(l10n, report);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(l10n.reportSection),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: SelectableText(
                  reportText,
                  style: AppTypography.monoSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.reportNote,
                style: AppTypography.caption.copyWith(color: textSecondary),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: report == null
                        ? null
                        : () async {
                            await Clipboard.setData(
                              ClipboardData(text: reportText),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.reportCopied),
                                  ),
                                );
                            }
                          },
                    icon: const Icon(Icons.copy, size: 18),
                    label: Text(l10n.reportCopy),
                  ),
                  FilledButton.icon(
                    onPressed:
                        report == null ? null : () => Share.share(reportText),
                    icon: const Icon(Icons.share, size: 18),
                    label: Text(l10n.reportShare),
                  ),
                  OutlinedButton.icon(
                    onPressed: controller.refresh,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(l10n.reportRefresh),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Заголовок секции экрана диагностики.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 4),
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
