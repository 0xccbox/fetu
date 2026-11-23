/// Константы фичи раздельного туннелирования (Split Tunneling).
///
/// Все лимиты и ключи хранилища вынесены сюда, чтобы исключить
/// magic numbers в коде (AGENTS.md, правило 12).
library;

/// Лимиты, ключи хранилища и значения по умолчанию для Split Tunneling.
class SplitTunnelConstants {
  const SplitTunnelConstants._();

  /// Ключ KeyValueStorage для сериализованного списка правил.
  static const String storageKey = 'split_tunnel.rules.v1';

  /// Максимум инлайн-правил, передаваемых в конфигурацию sing-box.
  ///
  /// Защита от переполнения памяти на слабых устройствах и в
  /// iOS NetworkExtension (AGENTS.md, правило 32).
  /// Большие списки подключаются бинарными `.srs`-наборами (ФАЗА 9).
  static const int maxInlineRules = 500;

  /// Минимальная длина паттерна правила.
  static const int minPatternLength = 2;

  /// Максимальная длина паттерна правила.
  static const int maxPatternLength = 256;

  // --------------------------------------------------------------------------
  // UI (значения экрана правил; правило 12 — без magic numbers)
  // --------------------------------------------------------------------------

  /// Нижний отступ списка правил (место под FAB).
  static const double rulesListBottomPadding = 88;

  /// Размер иконки пустого состояния.
  static const double emptyStateIconSize = 40;

  /// Прозрачность фона баннера ошибки.
  static const double errorBannerBackgroundOpacity = 0.12;

  /// Прозрачность рамки баннера ошибки.
  static const double errorBannerBorderOpacity = 0.5;

  /// Прозрачность иконки пустого состояния.
  static const double emptyStateIconOpacity = 0.5;
}
