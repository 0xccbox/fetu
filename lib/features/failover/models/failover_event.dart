import '../../connection/models/server_node.dart';
import 'protocol_health.dart';

/// Событие failover (для логирования и UI)
class FailoverEvent {
  const FailoverEvent({
    required this.timestamp,
    required this.fromProtocol,
    required this.toProtocol,
    required this.reason,
    required this.health,
    this.serverNodeId,
    this.errorDetails,
  });

  /// Время события
  final DateTime timestamp;

  /// С какого протокола переключились
  final ProtocolType fromProtocol;

  /// На какой протокол переключились
  final ProtocolType toProtocol;

  /// Причина переключения
  final FailoverReason reason;

  /// Состояние здоровья протокола, вызвавшее failover
  final ProtocolHealth health;

  /// ID узла (если failover на другой узел)
  final String? serverNodeId;

  /// Детали ошибки (для телеметрии)
  final String? errorDetails;

  @override
  String toString() {
    return 'FailoverEvent('
        'time=${timestamp.toIso8601String()}, '
        'from=${fromProtocol.name}, '
        'to=${toProtocol.name}, '
        'reason=$reason, '
        'health=$health'
        ')';
  }
}

/// Причина failover
enum FailoverReason {
  /// Таймаут подключения
  timeout,

  /// Высокая потеря пакетов
  packetLoss,

  /// Протокол заблокирован DPI
  blocked,

  /// Ошибка handshake
  handshakeFailed,

  /// Ручное переключение пользователем
  manual,
}
