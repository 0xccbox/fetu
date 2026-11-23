/// Состояние здоровья протокола
enum ProtocolHealth {
  /// Работает нормально (ping < 200ms, packet loss < 5%)
  healthy,

  /// Деградировано (packet loss 5-50%, мигающее соединение)
  degraded,

  /// Полный сбой (timeout, connection refused)
  failed,

  /// Заблокирован DPI/файрволом (специфичные ошибки sing-box)
  blocked,

  /// Неизвестно (ещё не проверялось)
  unknown;

  /// Требуется ли failover
  bool get requiresFailover => this == failed || this == blocked;

  /// Требуется ли переход на TCP (для degraded UDP)
  bool get requiresTcpFallback => this == degraded;
}
