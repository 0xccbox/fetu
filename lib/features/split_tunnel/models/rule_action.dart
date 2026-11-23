/// Действие правила раздельного туннелирования.
///
/// Определяет, через какой outbound конфигурации sing-box
/// пойдёт трафик, совпавший с правилом.
library;

/// Действие над совпавшим трафиком: через VPN / напрямую / блокировка.
enum RuleAction {
  /// Трафик идёт через VPN-прокси.
  proxy('proxy'),

  /// Трафик идёт напрямую, минуя VPN.
  direct('direct'),

  /// Трафик блокируется (kill switch на уровне правила).
  block('block');

  const RuleAction(this.outboundTag);

  /// Тег outbound в конфигурации sing-box.
  final String outboundTag;

  /// Разбирает действие из JSON-значения хранилища.
  ///
  /// Неизвестное или повреждённое значение трактуется как
  /// [RuleAction.proxy] (безопасный вариант по умолчанию),
  /// чтобы битое хранилище не ломало приложение при старте.
  static RuleAction fromName(String? name) => switch (name) {
        'proxy' => RuleAction.proxy,
        'direct' => RuleAction.direct,
        'block' => RuleAction.block,
        _ => RuleAction.proxy,
      };
}
