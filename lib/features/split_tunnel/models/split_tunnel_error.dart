/// Код ошибки операции с правилами Split Tunneling (для локализации).
///
/// Контроллер выставляет код рядом с debug-сообщением; UI переводит
/// код в сообщение через `AppLocalizations` (AGENTS.md, правило 14).
enum SplitTunnelError {
  /// Не удалось загрузить правила из хранилища.
  loadFailed,

  /// Не удалось сохранить правила.
  saveFailed,

  /// Правило не найдено.
  ruleNotFound,

  /// Неизвестный набор правил.
  presetUnknown,

  /// В подписке нет применимых правил.
  noProviderRules,

  /// Достигнут лимит правил.
  limitReached,

  /// Паттерн слишком короткий.
  patternTooShort,

  /// Паттерн слишком длинный.
  patternTooLong,

  /// Паттерн пуст после нормализации.
  patternEmpty,

  /// Дубликат правила.
  duplicate,

  /// Некорректное регулярное выражение.
  invalidRegex,

  /// Некорректный домен.
  invalidDomain,

  /// Некорректное ключевое слово.
  invalidKeyword,

  /// Некорректный GeoIP-код.
  invalidGeoip,

  /// Некорректное имя пакета.
  invalidPackage,

  /// Некорректный IP/CIDR.
  invalidCidr,

  /// Правила сохранены, но reload туннеля не удался.
  reloadFailed,
}
