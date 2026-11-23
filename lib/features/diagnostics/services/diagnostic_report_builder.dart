/// Сборщик диагностического отчёта.
///
/// Получает снимок состояния через инъекцируемый провайдер
/// (функцию, собираемую в DI-корне): фичи не импортируют
/// чужие контроллеры (AGENTS.md, правило зависимостей).
library;

import 'package:fetu/core/constants/app_constants.dart';

import '../models/diagnostic_report.dart';

/// Провайдер снимка состояния для отчёта.
typedef DiagnosticSnapshotProvider = DiagnosticSnapshot Function();

/// Строит [DiagnosticReport] из актуального состояния приложения.
class DiagnosticReportBuilder {
  /// Создаёт сборщик.
  ///
  /// [snapshotProvider] — источник данных; [appVersion] — версия
  /// приложения (инъекция для тестов).
  DiagnosticReportBuilder({
    required DiagnosticSnapshotProvider snapshotProvider,
    String appVersion = AppConstants.appVersion,
  })  : _snapshotProvider = snapshotProvider,
        _appVersion = appVersion;

  final DiagnosticSnapshotProvider _snapshotProvider;
  final String _appVersion;

  /// Собирает отчёт.
  ///
  /// [realDelayMs] — последний результат зонда Real-Delay
  /// (null — не измерялся).
  DiagnosticReport build({int? realDelayMs}) => DiagnosticReport(
        snapshot: _snapshotProvider(),
        generatedAt: DateTime.now(),
        appVersion: _appVersion,
        realDelayMs: realDelayMs,
      );
}
