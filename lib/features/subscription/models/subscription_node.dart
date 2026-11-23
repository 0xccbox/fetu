/// Узел подписки (элемент `nodes[]` контракта v2).
library;

import 'package:meta/meta.dart';

import '../../connection/models/server_node.dart';
import 'node_domain_entry.dart';
import 'node_protocol.dart';

/// Иммутабельный узел VPN из подписки.
@immutable
class SubscriptionNode {
  /// Создаёт узел подписки.
  const SubscriptionNode({
    required this.id,
    required this.name,
    required this.protocols,
    this.country,
    this.city,
    this.domains = const <NodeDomainEntry>[],
    this.badges = const <String>[],
    this.domainRotation = const <String, dynamic>{},
  });

  /// Идентификатор узла (стабильный, для каскадов и привязок).
  final String id;

  /// Отображаемое имя.
  final String name;

  /// Код страны (`NL`, `DE`).
  final String? country;

  /// Город (для UI).
  final String? city;

  /// Адреса входа (домены + IP fallback).
  final List<NodeDomainEntry> domains;

  /// Протоколы узла (failover-цепочка).
  final List<NodeProtocol> protocols;

  /// Идентификаторы бейджей из `node_badges_catalog`.
  final List<String> badges;

  /// Настройки ротации доменов (сырой блок контракта).
  final Map<String, dynamic> domainRotation;

  /// Восстанавливает узел из JSON.
  factory SubscriptionNode.fromJson(Map<String, dynamic> json) =>
      SubscriptionNode(
        id: (json['id'] as String? ?? '').trim(),
        name: (json['name'] as String? ?? '').trim(),
        country: (json['country'] as String?)?.trim(),
        city: (json['city'] as String?)?.trim(),
        domains: List.unmodifiable([
          for (final entry in (json['domains'] as List? ?? const []))
            if (entry is Map<String, dynamic>) NodeDomainEntry.fromJson(entry),
        ]),
        protocols: List.unmodifiable([
          for (final entry in (json['protocols'] as List? ?? const []))
            if (entry is Map<String, dynamic>) NodeProtocol.fromJson(entry),
        ]),
        badges: List.unmodifiable([
          for (final badge in (json['badges'] as List? ?? const []))
            if (badge is String) badge,
        ]),
        domainRotation: _safeMap(json['domain_rotation']),
      );

  /// Сериализует узел в JSON (для отладки и диагностик).
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (country != null) 'country': country,
        if (city != null) 'city': city,
        'domains': [for (final d in domains) d.toJson()],
        'protocols': [for (final p in protocols) p.toJson()],
        if (badges.isNotEmpty) 'badges': badges,
        if (domainRotation.isNotEmpty) 'domain_rotation': domainRotation,
      };

  /// Лучший (приоритетный) адрес узла.
  ///
  /// Порядок: active → backup → fallback, внутри — по priority.
  String? get primaryAddress {
    if (domains.isEmpty) return null;
    return domains
        .reduce((a, b) => _domainRank(a) <= _domainRank(b) ? a : b)
        .address;
  }

  static int _domainRank(NodeDomainEntry entry) =>
      entry.status.index * 1000 + entry.priority;

  /// Типобезопасно извлекает map-блок (битые блоки → пустой map).
  static Map<String, dynamic> _safeMap(Object? value) {
    if (value is! Map) return const <String, dynamic>{};
    try {
      return Map.unmodifiable(Map<String, dynamic>.from(value));
    } catch (_) {
      return const <String, dynamic>{};
    }
  }

  /// Лучший поддерживаемый протокол (по приоритету).
  NodeProtocol? get bestProtocol {
    final supported = protocols.where((p) => p.protocolType != null).toList();
    if (supported.isEmpty) return null;
    supported.sort((a, b) => a.priority.compareTo(b.priority));
    return supported.first;
  }

  /// Есть ли у узла живой TCP-канал (AGENTS.md, правило 9).
  bool get hasTcpFallback => protocols.any((p) => p.isTcpFallback);

  /// Конвертирует узел в [ServerNode] для подключения.
  ///
  /// [protocol] — протокол узла (по умолчанию приоритетный).
  ///
  /// Throws: [StateError] если у узла нет адреса или поддерживаемого
  /// протокола.
  ServerNode toServerNode({NodeProtocol? protocol}) {
    final address = primaryAddress;
    if (address == null || address.isEmpty) {
      throw StateError('Узел $id не имеет адреса');
    }
    final selected = protocol ?? bestProtocol;
    final type = selected?.protocolType;
    if (selected == null || type == null) {
      throw StateError(
        'Узел $id не имеет протокола, поддерживаемого клиентом',
      );
    }

    return ServerNode(
      id: id,
      name: name,
      countryCode: country ?? '??',
      address: address,
      protocol: type,
      config: buildProtocolConfig(selected),
    );
  }

  /// Возвращает все поддерживаемые протоколы узла в порядке приоритета failover.
  List<ServerNode> toProtocolCandidates() {
    final address = primaryAddress;
    if (address == null || address.isEmpty) return const <ServerNode>[];
    final supported = protocols.where((p) => p.protocolType != null).toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
    return [
      for (final p in supported)
        ServerNode(
          id: id,
          name: name,
          countryCode: country ?? '??',
          address: address,
          protocol: p.protocolType!,
          config: buildProtocolConfig(p),
        ),
    ];
  }

  /// Собирает config-карту в формате [SingBoxConfigGenerator].
  static Map<String, dynamic> buildProtocolConfig(NodeProtocol protocol) {
    final c = protocol.credentials;
    final obfs = protocol.obfuscation;
    return switch (protocol.type) {
      'shadowsocks' => {
          'server_port': protocol.port,
          'method': c['method'] as String? ?? '2022-blake3-aes-256-gcm',
          'password': c['password'] as String? ?? '',
          if (c['plugin'] != null) 'plugin': c['plugin'],
          if (c['plugin_opts'] != null) 'plugin_opts': c['plugin_opts'],
        },
      'hysteria2' => {
          'port': protocol.port,
          'password': c['password'] as String? ?? '',
          if (c['up_mbps'] != null) 'up_mbps': c['up_mbps'],
          if (c['down_mbps'] != null) 'down_mbps': c['down_mbps'],
          if (c['tls_sni'] ?? c['sni'] ?? c['server_name'] case final sni?)
            'tls_sni': sni,
          if (c['tls_insecure'] ?? c['insecure'] case final bool ins)
            'tls_insecure': ins,
          if (obfs['type'] == 'salamander' || obfs['type'] == 'obfs')
            'obfs': {
              'type': 'salamander',
              'password': obfs['password'] as String? ?? '',
            },
        },
      'vless' => {
          'port': protocol.port,
          'uuid': c['uuid'] as String? ?? '',
          if (c['transport'] == null)
            'flow': c['flow'] as String? ?? 'xtls-rprx-vision',
          if (c['transport'] != null) 'transport': c['transport'],
          if (c['path'] != null) 'path': c['path'],
          if (c['host'] != null) 'host': c['host'],
          if (c['service_name'] != null) 'service_name': c['service_name'],
          if (protocol.reality.isNotEmpty) 'reality': protocol.reality,
          if (protocol.reality['server_name'] ??
                  c['tls_sni'] ??
                  c['sni'] ??
                  c['server_name']
              case final sni?)
            'tls_sni': sni,
          if (c['tls_insecure'] ?? c['insecure'] case final bool ins)
            'tls_insecure': ins,
          if (obfs['sni_fragmentation'] is Map &&
              (obfs['sni_fragmentation'] as Map)['enabled'] == true)
            'tls_fragment': true,
          if (obfs['randomize_tls_fingerprint'] == true)
            'utls_fingerprint': 'chrome',
        },
      'amneziawg' || 'amnezia-wg' || 'wireguard' => {
          'port': protocol.port,
          if (c['private_key'] ?? c['client_private_key'] case final pk?)
            'private_key': pk,
          if (c['peer_public_key'] ?? c['server_public_key'] case final pub?)
            'peer_public_key': pub,
          if (c['pre_shared_key'] case final psk?) 'pre_shared_key': psk,
          if (c['local_address'] ?? c['local_addresses'] case final addr?)
            'local_address': addr,
          if (c['mtu'] case final mtu?) 'mtu': mtu,
          if (c['reserved'] case final res?) 'reserved': res,
          for (final awgKey in const [
            'jc',
            'jmin',
            'jmax',
            's1',
            's2',
            'h1',
            'h2',
            'h3',
            'h4',
            'i1',
            'i2',
            'i3',
            'i4',
            'i5',
          ])
            if (c[awgKey] case final val?) awgKey: val,
        },
      _ => {
          'port': protocol.port,
          if (c['username'] != null) 'username': c['username'],
          if (c['password'] != null) 'password': c['password'],
          if (c['tls_sni'] ?? c['sni'] ?? c['server_name'] case final sni?)
            'tls_sni': sni,
          if (c['tls_insecure'] ?? c['insecure'] case final bool ins)
            'tls_insecure': ins,
        },
    };
  }

  @override
  bool operator ==(Object other) =>
      other is SubscriptionNode && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => 'SubscriptionNode($id, $name, ${protocols.length}p)';
}
