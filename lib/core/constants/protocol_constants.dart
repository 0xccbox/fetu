/// Таймауты и пороги переключения протоколов в цепочке failover.
abstract final class ProtocolConstants {
  /// Таймаут рукопожатия для Hysteria 2 (UDP).
  static const Duration hysteria2HandshakeTimeout = Duration(seconds: 5);

  /// Таймаут рукопожатия для AmneziaWG (UDP L3 CPS).
  static const Duration amneziaWgHandshakeTimeout = Duration(seconds: 5);

  /// Таймаут рукопожатия для VLESS Reality (TCP / XHTTP).
  static const Duration vlessRealityHandshakeTimeout = Duration(seconds: 10);

  /// Таймаут рукопожатия для NaiveProxy (TCP HTTP/2).
  static const Duration naiveProxyHandshakeTimeout = Duration(seconds: 10);

  /// Таймаут рукопожатия для Mieru (TCP).
  static const Duration mieruHandshakeTimeout = Duration(seconds: 10);

  /// Порог потерь пакетов (в процентах) для ухода с UDP на TCP-стелс.
  static const double maxUdpPacketLossPercent = 15.0;
}
