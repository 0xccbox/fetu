/// Состояние VPN-подключения.
///
/// Используется для отображения текущего статуса в UI.
enum ConnectionState {
  /// Отключено
  disconnected,

  /// Подключение в процессе
  connecting,

  /// Успешно подключено
  connected,

  /// Отключение в процессе
  disconnecting,

  /// Ошибка подключения
  error;

  /// Проверка, находится ли подключение в активном состоянии
  bool get isActive => this == ConnectionState.connected;

  /// Проверка, находится ли подключение в процессе изменения
  bool get isTransitioning =>
      this == ConnectionState.connecting ||
      this == ConnectionState.disconnecting;
}
