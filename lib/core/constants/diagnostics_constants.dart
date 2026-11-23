/// Константы диагностики (AGENTS.md, правило 12: без magic numbers).
abstract final class DiagnosticsConstants {
  /// URL HTTP-204 зонда Real-Delay (стандартный connectivity-check).
  ///
  /// Запрос идёт через системный сетевой стек: при активном туннеле
  /// весь трафик (включая этот) проходит через VPN — измеряется
  /// сквозная задержка до выхода.
  static const String realDelayProbeUrl =
      'https://www.gstatic.com/generate_204';

  /// Таймаут зонда Real-Delay.
  static const Duration realDelayTimeout = Duration(seconds: 3);

  /// Максимальное число строк в отчёте для UI-отображения.
  static const int reportMaxLines = 64;
}
