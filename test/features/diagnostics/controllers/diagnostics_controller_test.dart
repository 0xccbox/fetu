import 'package:fetu/features/connection/models/connection_state.dart';
import 'package:fetu/features/diagnostics/controllers/diagnostics_controller.dart';
import 'package:fetu/features/diagnostics/models/diagnostic_report.dart';
import 'package:fetu/features/diagnostics/services/diagnostic_report_builder.dart';
import 'package:fetu/features/diagnostics/services/real_delay_probe.dart';
import 'package:fetu/features/settings/models/ui_experience_mode.dart';
import 'package:flutter_test/flutter_test.dart';

DiagnosticSnapshot _snapshot({
  ConnectionState state = ConnectionState.connected,
}) =>
    DiagnosticSnapshot(
      uiMode: UiExperienceMode.advanced,
      tunnelMode: 'mock',
      connectionState: state,
      activeSplitRules: 3,
      totalSplitRules: 4,
    );

void main() {
  group('DiagnosticsController', () {
    test('refresh собирает отчёт и уведомляет слушателей', () {
      final controller = DiagnosticsController(
        builder: DiagnosticReportBuilder(snapshotProvider: _snapshot),
        probe: RealDelayProbe(
          probeImpl: (_, __) async => const Duration(milliseconds: 42),
        ),
        isTunnelActive: () => true,
      )..refresh();

      var notified = 0;
      controller.addListener(() => notified++);

      expect(controller.report, isNotNull);
      expect(
        controller.report!.snapshot.connectionState,
        ConnectionState.connected,
      );

      controller.refresh();
      expect(notified, greaterThan(0));
    });

    test('measureRealDelay пропускается без активного туннеля', () async {
      final controller = DiagnosticsController(
        builder: DiagnosticReportBuilder(snapshotProvider: _snapshot),
        probe: RealDelayProbe(
          probeImpl: (_, __) async => const Duration(milliseconds: 99),
        ),
        isTunnelActive: () => false,
      );

      final measured = await controller.measureRealDelay();

      expect(measured, isFalse);
      expect(controller.realDelayMs, isNull);
    });

    test('measureRealDelay сохраняет результат зонда', () async {
      final controller = DiagnosticsController(
        builder: DiagnosticReportBuilder(snapshotProvider: _snapshot),
        probe: RealDelayProbe(
          probeImpl: (_, __) async => const Duration(milliseconds: 42),
        ),
        isTunnelActive: () => true,
      );

      final measured = await controller.measureRealDelay();

      expect(measured, isTrue);
      expect(controller.realDelayMs, 42);
      expect(controller.report!.realDelayMs, 42);
      expect(controller.isProbing, isFalse);
    });

    test('неудачный зонд: measured = true, результат null', () async {
      final controller = DiagnosticsController(
        builder: DiagnosticReportBuilder(snapshotProvider: _snapshot),
        probe: RealDelayProbe(probeImpl: (_, __) async => null),
        isTunnelActive: () => true,
      );

      expect(await controller.measureRealDelay(), isTrue);
      expect(controller.realDelayMs, isNull);
    });
  });
}
