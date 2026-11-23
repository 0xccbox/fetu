import 'package:fetu/features/connection/models/connection_metrics.dart';
import 'package:fetu/features/connection/models/connection_state.dart';
import 'package:fetu/features/connection/models/server_node.dart';
import 'package:fetu/features/diagnostics/models/diagnostic_report.dart';
import 'package:fetu/features/diagnostics/services/diagnostic_report_builder.dart';
import 'package:fetu/features/diagnostics/services/diagnostic_report_formatter.dart';
import 'package:fetu/features/settings/models/ui_experience_mode.dart';
import 'package:fetu/features/subscription/models/provider_cabinet.dart';
import 'package:fetu/l10n/app_localizations_en.dart';
import 'package:fetu/l10n/app_localizations_ru.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DiagnosticSnapshot snapshot({
    UiExperienceMode mode = UiExperienceMode.advanced,
    DeveloperMeta? meta = const DeveloperMeta(
      configGeneratedMs: 14,
      backendNode: 'api-eu-west-2',
      abTestGroup: 'xhttp_reality_v2',
      recommendedUiMode: 'auto',
      diagnosticWebhook: 'https://diag.test-vpn.com/hook',
    ),
    String? providerName = 'Test VPN Pro',
  }) =>
      DiagnosticSnapshot(
        uiMode: mode,
        tunnelMode: 'real',
        connectionState: ConnectionState.connected,
        protocol: ProtocolType.hysteria2,
        metrics: const ConnectionMetrics(
          downloadSpeed: 1024 * 1024,
          uploadSpeed: 4096,
          totalDownloaded: 10 * 1024 * 1024,
          totalUploaded: 1024,
          connectionDuration: 75,
          latency: 42,
        ),
        activeSplitRules: 10,
        totalSplitRules: 12,
        providerName: providerName,
        subscriptionExpiresAt: DateTime.utc(2030, 1, 1),
        subscriptionNodeCount: 3,
        developerMeta: meta,
      );

  group('DiagnosticReportBuilder', () {
    test('собирает отчёт из провайдера снимка', () {
      var calls = 0;
      final builder = DiagnosticReportBuilder(
        snapshotProvider: () {
          calls++;
          return snapshot();
        },
        appVersion: '9.9.9-test',
      );

      final report = builder.build(realDelayMs: 123);

      expect(calls, 1);
      expect(report.appVersion, '9.9.9-test');
      expect(report.realDelayMs, 123);
      expect(report.snapshot.connectionState, ConnectionState.connected);
      expect(report.snapshot.protocol, ProtocolType.hysteria2);
      expect(report.hasMetrics, isTrue);
      expect(report.generatedAt, isNotNull);
    });

    test('без измерения Real-Delay поле остаётся null', () {
      final builder = DiagnosticReportBuilder(snapshotProvider: snapshot);

      expect(builder.build().realDelayMs, isNull);
    });
  });

  group('DiagnosticReportFormatter (санитизация, правило 16)', () {
    test('в отчёте нет адресов серверов, URL и webhook-значения', () {
      final report = DiagnosticReportBuilder(snapshotProvider: snapshot)
          .build(realDelayMs: 55);
      final text =
          DiagnosticReportFormatter.format(AppLocalizationsRu(), report);

      // Фикстура содержит адреса/URL только в developer_meta.webhook;
      // в текст отчёта они попасть не должны (правило 16).
      // NB: подстрока 'xhttp' в A/B-группе — легитимные данные
      // провайдера, это не URL: проверяем схемы целиком.
      expect(text.contains('diag.test-vpn.com'), isFalse);
      expect(text.contains('http://'), isFalse);
      expect(text.contains('https://'), isFalse);
      expect(text.contains('45.67'), isFalse);
      expect(text.contains('nl1.vpn.com'), isFalse);
    });

    test('developer_meta включается только в расширенном режиме', () {
      final ru = AppLocalizationsRu();

      final advancedText = DiagnosticReportFormatter.format(
        ru,
        DiagnosticReportBuilder(snapshotProvider: snapshot).build(),
      );
      expect(advancedText.contains('developer_meta'), isTrue);

      final simpleText = DiagnosticReportFormatter.format(
        ru,
        DiagnosticReportBuilder(
          snapshotProvider: () => snapshot(mode: UiExperienceMode.simple),
        ).build(),
      );
      expect(simpleText.contains('developer_meta'), isFalse);
    });

    test('ключевые строки отчёта: подписка, метрики, ядро', () {
      final ru = AppLocalizationsRu();
      final text = DiagnosticReportFormatter.format(
        ru,
        DiagnosticReportBuilder(snapshotProvider: snapshot)
            .build(realDelayMs: 55),
      );

      expect(text, contains(ru.reportLineSubscription('Test VPN Pro', 3)));
      expect(text, contains(ru.reportLineRealDelay(55)));
      expect(text, contains(ru.tunnelModeReal));
    });

    test('без подписки — строка «не добавлена»', () {
      final ru = AppLocalizationsRu();
      final text = DiagnosticReportFormatter.format(
        ru,
        DiagnosticReportBuilder(
          snapshotProvider: () => snapshot(providerName: null),
        ).build(),
      );

      expect(text, contains(ru.reportLineNoSubscription));
    });

    test('EN-формат локализован', () {
      final en = AppLocalizationsEn();
      final text = DiagnosticReportFormatter.format(
        en,
        DiagnosticReportBuilder(snapshotProvider: snapshot).build(),
      );

      expect(text, contains(en.reportLineCore(en.tunnelModeReal)));
      expect(text, contains(en.reportLineSubscription('Test VPN Pro', 3)));
    });
  });
}
