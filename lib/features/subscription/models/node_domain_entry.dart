/// Домен/IP-точка входа узла подписки с приоритетом и статусом.
library;

import 'package:meta/meta.dart';

/// Тип адреса узла.
enum NodeDomainType {
  /// Обычный домен.
  domain,

  /// Прямой IP (последний рубеж при блокировках доменов).
  ip;

  factory NodeDomainType.fromName(String? name) => switch (name) {
        'ip' => NodeDomainType.ip,
        _ => NodeDomainType.domain,
      };
}

/// Статус адреса узла.
enum NodeDomainStatus {
  /// Основной адрес.
  active,

  /// Резервный домен.
  backup,

  /// Последний fallback (обычно IP).
  fallback;

  factory NodeDomainStatus.fromName(String? name) => switch (name) {
        'backup' => NodeDomainStatus.backup,
        'fallback' => NodeDomainStatus.fallback,
        _ => NodeDomainStatus.active,
      };
}

/// Иммутабельная запись адреса узла подписки.
@immutable
class NodeDomainEntry {
  /// Создаёт запись адреса.
  const NodeDomainEntry({
    required this.address,
    required this.priority,
    this.type = NodeDomainType.domain,
    this.status = NodeDomainStatus.active,
  });

  /// Домен или IP-адрес.
  final String address;

  /// Приоритет (меньше = выше).
  final int priority;

  /// Тип адреса.
  final NodeDomainType type;

  /// Статус адреса.
  final NodeDomainStatus status;

  /// Восстанавливает запись из JSON.
  factory NodeDomainEntry.fromJson(Map<String, dynamic> json) =>
      NodeDomainEntry(
        address: (json['address'] as String? ?? '').trim(),
        priority: (json['priority'] as num?)?.toInt() ?? 999,
        type: NodeDomainType.fromName(json['type'] as String?),
        status: NodeDomainStatus.fromName(json['status'] as String?),
      );

  /// Сериализует запись в JSON.
  Map<String, dynamic> toJson() => {
        'address': address,
        'priority': priority,
        'type': type.name,
        'status': status.name,
      };

  NodeDomainEntry copyWith({
    String? address,
    int? priority,
    NodeDomainType? type,
    NodeDomainStatus? status,
  }) =>
      NodeDomainEntry(
        address: address ?? this.address,
        priority: priority ?? this.priority,
        type: type ?? this.type,
        status: status ?? this.status,
      );

  @override
  bool operator ==(Object other) =>
      other is NodeDomainEntry &&
      other.address == address &&
      other.priority == priority &&
      other.type == type &&
      other.status == status;

  @override
  int get hashCode => Object.hash(address, priority, type, status);

  @override
  String toString() => 'NodeDomainEntry($address, p$priority, ${status.name})';
}
