/// Узел VPN-сервера с поддержкой нескольких протоколов.
///
/// Представляет один физический сервер, который может поддерживать
/// несколько протоколов (Shadowsocks, Hysteria2, VLESS, etc).
library;

import 'package:meta/meta.dart';

/// Тип протокола VPN с поддержкой failover.
///
/// Порядок приоритета для failover:
/// 1. Hysteria2 (UDP, приоритет 1)
/// 2. AmneziaWG (UDP, приоритет 2)
/// 3. VLESS Reality (TCP, приоритет 3)
/// 4. Naive (TCP, приоритет 4)
/// 5. Mieru (TCP, приоритет 5)
/// 6. Shadowsocks (TCP, приоритет 6, fallback)
enum ProtocolType {
  hysteria2(priority: 1, isUdp: true),
  amneziaWg(priority: 2, isUdp: true),
  vlessReality(priority: 3, isUdp: false),
  naive(priority: 4, isUdp: false),
  mieru(priority: 5, isUdp: false),
  shadowsocks(priority: 6, isUdp: false),
  wireguard(priority: 7, isUdp: true),
  vless(priority: 8, isUdp: false);

  const ProtocolType({required this.priority, required this.isUdp});

  /// Приоритет протокола (меньше = выше приоритет)
  final int priority;

  /// Является ли протокол UDP-based
  final bool isUdp;

  /// Является ли протокол TCP-based
  bool get isTcp => !isUdp;

  /// Следующий протокол в цепочке failover
  ProtocolType? get nextProtocol {
    final sorted = ProtocolType.values.toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
    final currentIndex = sorted.indexOf(this);
    if (currentIndex == -1 || currentIndex >= sorted.length - 1) {
      return null;
    }
    return sorted[currentIndex + 1];
  }

  /// Получить все TCP fallback протоколы
  static List<ProtocolType> get tcpFallbacks =>
      ProtocolType.values.where((p) => p.isTcp).toList()
        ..sort((a, b) => a.priority.compareTo(b.priority));

  /// Получить все UDP протоколы
  static List<ProtocolType> get udpProtocols =>
      ProtocolType.values.where((p) => p.isUdp).toList()
        ..sort((a, b) => a.priority.compareTo(b.priority));

  /// Человекочитаемое имя протокола для UI
  String get displayName {
    switch (this) {
      case ProtocolType.hysteria2:
        return 'Hysteria 2';
      case ProtocolType.amneziaWg:
        return 'AmneziaWG';
      case ProtocolType.vlessReality:
        return 'VLESS Reality';
      case ProtocolType.naive:
        return 'NaiveProxy';
      case ProtocolType.mieru:
        return 'Mieru';
      case ProtocolType.shadowsocks:
        return 'Shadowsocks';
      case ProtocolType.wireguard:
        return 'WireGuard';
      case ProtocolType.vless:
        return 'VLESS';
    }
  }
}

/// Базовая модель узла сервера.
@immutable
class ServerNode {
  final String id;
  final String name;
  final String countryCode;
  final String address;
  final ProtocolType protocol;
  final Map<String, dynamic> config;

  const ServerNode({
    required this.id,
    required this.name,
    required this.countryCode,
    required this.address,
    required this.protocol,
    required this.config,
  });

  factory ServerNode.fromJson(Map<String, dynamic> json) {
    return ServerNode(
      id: json['id'] as String,
      name: json['name'] as String,
      countryCode: json['country_code'] as String,
      address: json['address'] as String,
      protocol: ProtocolType.values.firstWhere(
        (p) => p.name == json['protocol'],
        orElse: () => ProtocolType.shadowsocks,
      ),
      config: json['config'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'country_code': countryCode,
      'address': address,
      'protocol': protocol.name,
      'config': config,
    };
  }

  ServerNode copyWith({
    String? id,
    String? name,
    String? countryCode,
    String? address,
    ProtocolType? protocol,
    Map<String, dynamic>? config,
  }) {
    return ServerNode(
      id: id ?? this.id,
      name: name ?? this.name,
      countryCode: countryCode ?? this.countryCode,
      address: address ?? this.address,
      protocol: protocol ?? this.protocol,
      config: config ?? this.config,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServerNode && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ServerNode(id: $id, name: $name, protocol: $protocol)';
}
