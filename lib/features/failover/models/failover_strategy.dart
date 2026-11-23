import '../../connection/models/server_node.dart';

/// Стратегия автоматического failover
class FailoverStrategy {
  const FailoverStrategy({
    required this.protocolOrder,
    this.handshakeTimeout = const Duration(seconds: 10),
    this.packetLossThreshold = 0.5,
    this.enableCanaryCheck = true,
    this.canaryCheckInterval = const Duration(seconds: 30),
    this.degradedThreshold = 0.05,
  });

  /// Порядок протоколов для failover (согласно AGENTS.md, правило 9)
  /// По умолчанию: Hysteria2/AmneziaWG → VLESS Reality → NaiveProxy → Mieru
  final List<ProtocolType> protocolOrder;

  /// Таймаут handshake (Hysteria2: 10s, Reality: 15s)
  final Duration handshakeTimeout;

  /// Порог потери пакетов для failover (по умолчанию 50%)
  final double packetLossThreshold;

  /// Порог для статуса "degraded" (по умолчанию 5%)
  final double degradedThreshold;

  /// Включить Canary TCP-проверку (для мигающего UDP)
  final bool enableCanaryCheck;

  /// Интервал Canary-проверки
  final Duration canaryCheckInterval;

  /// Стратегия по умолчанию (согласно AGENTS.md)
  static const FailoverStrategy defaultStrategy = FailoverStrategy(
    protocolOrder: [
      ProtocolType.hysteria2,
      ProtocolType.amneziaWg,
      ProtocolType.vlessReality,
      ProtocolType.naive,
      ProtocolType.mieru,
    ],
    handshakeTimeout: Duration(seconds: 10),
    packetLossThreshold: 0.5, // 50%
    degradedThreshold: 0.05, // 5%
    enableCanaryCheck: true,
  );

  /// Получить следующий протокол для failover
  ProtocolType? getNextProtocol(ProtocolType current) {
    final index = protocolOrder.indexOf(current);
    if (index == -1 || index >= protocolOrder.length - 1) {
      return null; // Текущий протокол не найден или это последний
    }
    return protocolOrder[index + 1];
  }

  /// Является ли протокол UDP
  bool isUdpProtocol(ProtocolType protocol) {
    return protocol == ProtocolType.hysteria2 ||
        protocol == ProtocolType.amneziaWg;
  }

  /// Получить первый TCP-протокол для fallback (при мигающем UDP)
  ProtocolType get firstTcpProtocol {
    return protocolOrder.firstWhere(
      (p) => !isUdpProtocol(p),
      orElse: () => ProtocolType.vlessReality,
    );
  }

  FailoverStrategy copyWith({
    List<ProtocolType>? protocolOrder,
    Duration? handshakeTimeout,
    double? packetLossThreshold,
    double? degradedThreshold,
    bool? enableCanaryCheck,
    Duration? canaryCheckInterval,
  }) {
    return FailoverStrategy(
      protocolOrder: protocolOrder ?? this.protocolOrder,
      handshakeTimeout: handshakeTimeout ?? this.handshakeTimeout,
      packetLossThreshold: packetLossThreshold ?? this.packetLossThreshold,
      degradedThreshold: degradedThreshold ?? this.degradedThreshold,
      enableCanaryCheck: enableCanaryCheck ?? this.enableCanaryCheck,
      canaryCheckInterval: canaryCheckInterval ?? this.canaryCheckInterval,
    );
  }
}
