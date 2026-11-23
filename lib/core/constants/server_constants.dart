/// Константы фичи серверов, скоринга и автоподбора (AGENTS.md, правило 12).
abstract final class ServerConstants {
  /// Время жизни кэша пинга узлов (правило 22: 5 минут).
  static const Duration pingCacheTtl = Duration(minutes: 5);

  /// Таймаут TCP-зонда до входного порта узла.
  static const Duration tcpPingTimeout = Duration(seconds: 3);

  /// Таймаут Real-Delay HTTP 204 зонда.
  static const Duration realDelayTimeout = Duration(seconds: 4);

  /// Таймаут API-запроса умного выбора провайдера.
  static const Duration smartSelectApiTimeout = Duration(seconds: 4);

  /// Максимум параллельных замеров узлов (до 4 потоков по спецификации).
  static const int maxConcurrentProbes = 4;

  /// Порог потери пакетов (%), после которого связка считается заблокированной.
  static const double maxPacketLossPercent = 15.0;

  /// Бонус к рейтингу за успешную работу в текущем сетевом профиле.
  static const double networkMemoryBonus = 25.0;

  /// Минимальный размер тестового payload для проверки на 16KB-блокировку.
  static const int minPayloadProbeBytes = 24 * 1024;

  /// Ключ хранения памяти сетевых профилей (Wi-Fi BSSID / Cellular MCC-MNC).
  static const String networkMemoryStorageKey =
      'fetu.servers.network_memory.v1';

  /// Порог хорошего пинга (зелёный индикатор).
  static const int goodLatencyThresholdMs = 100;

  /// Порог среднего пинга (жёлтый индикатор).
  static const int mediumLatencyThresholdMs = 250;
}
