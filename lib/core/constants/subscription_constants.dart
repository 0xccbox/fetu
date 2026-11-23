/// Константы фичи подписок (ФАЗА 9).
///
/// Ключи хранилища, лимиты и таймауты без magic numbers
/// (AGENTS.md, правило 12).
library;

/// Лимиты и ключи для подсистемы подписок и `.srs`-кэша.
class SubscriptionConstants {
  const SubscriptionConstants._();

  /// Ключ KeyValueStorage для активной подписки (url + raw JSON).
  static const String storageKey = 'subscription.active.v1';

  /// Минимальная поддерживаемая версия формата подписки.
  static const int minFormatVersion = 2;

  /// Максимум узлов в одной подписке (защита памяти, правило 32).
  static const int maxNodesPerSubscription = 200;

  /// Максимум протоколов на узел.
  static const int maxProtocolsPerNode = 8;

  // --------------------------------------------------------------------------
  // `.srs` RULE-SETS (AGENTS.md, правило 32)
  // --------------------------------------------------------------------------

  /// Префикс ключа кэша бинарного набора правил (JSON: etag,
  /// sha256, размер, данные в base64).
  static const String srsCacheKeyPrefix = 'ruleset.';

  /// Максимальный размер `.srs`-набора в килобайтах (защита от OOM
  /// на слабых устройствах и в iOS NetworkExtension).
  static const int srsMaxSizeKb = 1024;

  /// Таймаут скачивания `.srs`-набора.
  static const Duration srsDownloadTimeout = Duration(seconds: 15);

  /// Таймаут загрузки подписки по HTTP.
  static const Duration httpTimeout = Duration(seconds: 20);

  /// Минимальный интервал фонового автообновления подписки (защита от спама).
  static const int minAutoUpdateIntervalSeconds = 300;
}
