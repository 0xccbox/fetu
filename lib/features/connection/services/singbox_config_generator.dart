/// Генератор конфигурации sing-box (1.12+) для поддерживаемых протоколов.
///
/// Создаёт JSON-конфигурацию sing-box на основе узла сервера,
/// правил раздельного туннелирования и локальных `.srs` rule-set'ов.
library;

import 'dart:convert';
import 'dart:io' show Platform;

import '../../split_tunnel/models/rule_action.dart';
import '../../split_tunnel/models/rule_type.dart';
import '../../split_tunnel/models/split_rule.dart';
import '../../split_tunnel/services/rule_engine.dart';
import '../models/local_rule_set_ref.dart';
import '../models/server_node.dart';

/// Исключение генерации конфигурации.
class ConfigGenerationException implements Exception {
  final String message;
  final ProtocolType? protocol;

  const ConfigGenerationException(this.message, {this.protocol});

  @override
  String toString() =>
      'ConfigGenerationException: $message${protocol != null ? ' (protocol: $protocol)' : ''}';
}

/// Генератор sing-box конфигурации (совместимость с ядром 1.12+).
class SingBoxConfigGenerator {
  /// DNS конфигурация 1.12+: удалённый DoH через прокси + нативный локальный bootstrap.
  ///
  /// Инвариант (VPN_CORE_FOUNDATION.md):
  /// - нет `'detour': 'direct'` (ошибка в sing-box 1.12+);
  /// - `final: remote-dns` направляет все запросы пользователя через туннель;
  /// - `strategy: ipv4_only` предотвращает утечки IPv6 при IPv4-туннеле.
  static const _dnsConfig = {
    'servers': [
      {
        'type': 'https',
        'tag': 'remote-dns',
        'server': '1.1.1.1',
        'detour': 'proxy',
      },
      {
        'type': 'local',
        'tag': 'bootstrap-dns',
      },
    ],
    'final': 'remote-dns',
    'strategy': 'ipv4_only',
  };

  /// Системные правила маршрутизации (инвариант, нельзя менять порядок).
  ///
  /// 1. Sniff трафика.
  /// 2. Перехват DNS-трафика в `hijack-dns`.
  /// 3. Блок multicast-диапазонов через `reject`.
  static const List<Map<String, dynamic>> _baseRouteRules = [
    {'action': 'sniff'},
    {'protocol': 'dns', 'action': 'hijack-dns'},
    {
      'ip_cidr': ['224.0.0.0/4', 'ff00::/8'],
      'action': 'reject',
    },
  ];

  /// Проверяет, может ли генератор построить валидный конфиг для узла [node].
  static bool canGenerate(ServerNode node) {
    try {
      generate(node);
      return true;
    } on ConfigGenerationException {
      return false;
    }
  }

  /// Генерирует полную sing-box конфигурацию для узла.
  ///
  /// [node] — целевой узел сервера.
  /// [splitRules] — активные инлайн-правила Split Tunneling.
  /// [ruleSets] — локальные `.srs`-наборы (правило 32).
  /// [relayNode] — опциональный входной каскадный узел (мульти-каскад, `detour`).
  ///
  /// Returns: JSON-строка конфигурации sing-box.
  /// Throws: [ConfigGenerationException] если конфигурация не может быть создана.
  static String generate(
    ServerNode node, {
    List<SplitRule> splitRules = const <SplitRule>[],
    List<LocalRuleSetRef> ruleSets = const <LocalRuleSetRef>[],
    ServerNode? relayNode,
  }) {
    final endpoints = <Map<String, dynamic>>[];
    final outbounds = <Map<String, dynamic>>[];

    if (relayNode != null) {
      outbounds.add(_buildProxyOutbound(relayNode, tag: 'relay'));
    }

    final detourTag = relayNode != null ? 'relay' : null;
    if (_isEndpointProtocol(node.protocol)) {
      endpoints.add(
        _generateWireGuardEndpoint(node, tag: 'proxy', detour: detourTag),
      );
    } else {
      outbounds.add(
        _buildProxyOutbound(node, tag: 'proxy', detour: detourTag),
      );
    }

    outbounds.add(const {'type': 'direct', 'tag': 'direct'});

    final config = <String, dynamic>{
      'log': const {'level': 'info', 'timestamp': true},
      'dns': _dnsConfig,
      'inbounds': _generateInbounds(),
      if (endpoints.isNotEmpty) 'endpoints': endpoints,
      'outbounds': outbounds,
      'route': _buildRouteConfig(splitRules, ruleSets),
      // Clash API в памяти позволяет CommandServer снимать реальные метрики трафика.
      'experimental': const {'clash_api': <String, dynamic>{}},
    };

    try {
      return jsonEncode(config);
    } on JsonUnsupportedObjectError catch (e) {
      throw ConfigGenerationException(
        'Failed to encode config to JSON: ${e.unsupportedObject}',
        protocol: node.protocol,
      );
    }
  }

  static bool _isEndpointProtocol(ProtocolType protocol) =>
      protocol == ProtocolType.wireguard || protocol == ProtocolType.amneziaWg;

  static Map<String, dynamic> _buildRouteConfig(
    List<SplitRule> splitRules,
    List<LocalRuleSetRef> ruleSets,
  ) {
    return {
      'rules': [
        ..._baseRouteRules,
        ...RuleEngine.buildRouteRules(_platformSupportedRules(splitRules)),
        for (final ref in ruleSets)
          {
            'rule_set': ref.tag,
            if (ref.action == RuleAction.block)
              'action': 'reject'
            else
              'outbound': ref.action.outboundTag,
          },
      ],
      if (ruleSets.isNotEmpty)
        'rule_set': [
          for (final ref in ruleSets)
            {
              'type': 'local',
              'tag': ref.tag,
              'format': 'binary',
              'path': ref.path,
            },
        ],
      'final': 'proxy',
      'auto_detect_interface': true,
      'default_domain_resolver': 'bootstrap-dns',
    };
  }

  static List<SplitRule> _platformSupportedRules(List<SplitRule> rules) =>
      Platform.isAndroid
          ? rules
          : rules.where((rule) => rule.type != RuleType.app).toList();

  static List<Map<String, dynamic>> _generateInbounds() {
    return [
      {
        'type': 'tun',
        'tag': 'tun-in',
        'address': ['172.19.0.1/30', 'fdfe:dcba:9876::1/126'],
        'auto_route': true,
        'strict_route': true,
        'stack': 'gvisor',
      },
    ];
  }

  static Map<String, dynamic> _buildProxyOutbound(
    ServerNode node, {
    required String tag,
    String? detour,
  }) {
    final outbound = switch (node.protocol) {
      ProtocolType.shadowsocks => _generateShadowsocksOutbound(node, tag),
      ProtocolType.hysteria2 => _generateHysteria2Outbound(node, tag),
      ProtocolType.vless ||
      ProtocolType.vlessReality =>
        _generateVlessOutbound(node, tag),
      ProtocolType.naive => _generateNaiveOutbound(node, tag),
      ProtocolType.mieru => _generateMieruOutbound(node, tag),
      ProtocolType.wireguard ||
      ProtocolType.amneziaWg =>
        throw ConfigGenerationException(
          'WireGuard/AmneziaWG must be configured as endpoint, not relay outbound',
          protocol: node.protocol,
        ),
    };
    if (detour != null) {
      outbound['detour'] = detour;
    }
    return outbound;
  }

  static Map<String, dynamic> _generateShadowsocksOutbound(
    ServerNode node,
    String tag,
  ) {
    final config = node.config;
    final port = config['server_port'];
    final method = config['method'];
    final password = config['password'];
    if (port is! int || method is! String || password is! String) {
      throw const ConfigGenerationException(
        'Shadowsocks config missing required fields: server_port, method, password',
        protocol: ProtocolType.shadowsocks,
      );
    }

    return {
      'type': 'shadowsocks',
      'tag': tag,
      'server': node.address,
      'server_port': port,
      'method': method,
      'password': password,
      if (config['plugin'] is String) 'plugin': config['plugin'] as String,
      if (config['plugin_opts'] is String)
        'plugin_opts': config['plugin_opts'] as String,
    };
  }

  static Map<String, dynamic> _generateHysteria2Outbound(
    ServerNode node,
    String tag,
  ) {
    final config = node.config;
    final port = config['port'];
    final password = config['password'];
    if (port is! int || password is! String) {
      throw const ConfigGenerationException(
        'Hysteria2 config missing required fields: port, password',
        protocol: ProtocolType.hysteria2,
      );
    }

    final obfs = config['obfs'];
    return {
      'type': 'hysteria2',
      'tag': tag,
      'server': node.address,
      'server_port': port,
      'password': password,
      if (config['up_mbps'] is int) 'up_mbps': config['up_mbps'] as int,
      if (config['down_mbps'] is int) 'down_mbps': config['down_mbps'] as int,
      if (obfs is Map<String, dynamic>)
        'obfs': {
          'type': obfs['type'] as String? ?? 'salamander',
          'password': obfs['password'] as String? ?? '',
        },
      'tls': {
        'enabled': true,
        'insecure': config['tls_insecure'] as bool? ?? false,
        'alpn': const ['h3'],
        if (config['tls_sni'] is String)
          'server_name': config['tls_sni'] as String,
      },
    };
  }

  /// В sing-box 1.12+ исходящий HTTPS/HTTP2-прокси (Naive-совместимый)
  /// описывается через outbound `type: http` с включённым `tls`.
  static Map<String, dynamic> _generateNaiveOutbound(
    ServerNode node,
    String tag,
  ) {
    final config = node.config;
    final port = config['port'];
    final username = config['username'];
    if (port is! int || username is! String) {
      throw const ConfigGenerationException(
        'Naive config missing required fields: port, username',
        protocol: ProtocolType.naive,
      );
    }

    return {
      'type': 'http',
      'tag': tag,
      'server': node.address,
      'server_port': port,
      'username': username,
      'password': config['password'] as String? ?? '',
      'tls': {
        'enabled': true,
        'insecure': config['tls_insecure'] as bool? ?? false,
        if (config['tls_sni'] is String)
          'server_name': config['tls_sni'] as String,
      },
    };
  }

  /// Генерирует Mieru outbound (поддерживается кастомными сборками/клиентами).
  static Map<String, dynamic> _generateMieruOutbound(
    ServerNode node,
    String tag,
  ) {
    final config = node.config;
    final port = config['port'];
    final username = config['username'];
    if (port is! int || username is! String) {
      throw const ConfigGenerationException(
        'Mieru config missing required fields: port, username',
        protocol: ProtocolType.mieru,
      );
    }

    return {
      'type': 'mieru',
      'tag': tag,
      'server': node.address,
      'server_port': port,
      'username': username,
      'password': config['password'] as String? ?? '',
    };
  }

  static Map<String, dynamic> _generateVlessOutbound(
    ServerNode node,
    String tag,
  ) {
    final config = node.config;
    final port = config['port'];
    final uuid = config['uuid'];
    if (port is! int || uuid is! String) {
      throw const ConfigGenerationException(
        'VLESS config missing required fields: port, uuid',
        protocol: ProtocolType.vless,
      );
    }

    final transport = _buildVlessTransport(config);
    final reality = config['reality'];
    final realityPubKey =
        reality is Map<String, dynamic> ? reality['public_key'] : null;
    if (reality is Map<String, dynamic> &&
        (realityPubKey is! String || realityPubKey.isEmpty)) {
      throw const ConfigGenerationException(
        'VLESS Reality config missing public_key',
        protocol: ProtocolType.vlessReality,
      );
    }
    final fingerprint = config['utls_fingerprint'] as String?;

    return {
      'type': 'vless',
      'tag': tag,
      'server': node.address,
      'server_port': port,
      'uuid': uuid,
      if (transport == null && config['flow'] is String)
        'flow': config['flow'] as String
      else if (transport == null)
        'flow': 'xtls-rprx-vision',
      if (transport != null) 'transport': transport,
      'tls': {
        'enabled': true,
        'insecure': config['tls_insecure'] as bool? ?? false,
        if (config['tls_sni'] is String)
          'server_name': config['tls_sni'] as String,
        if (config['tls_fragment'] == true) 'fragment': true,
        if (fingerprint != null && fingerprint.isNotEmpty)
          'utls': {'enabled': true, 'fingerprint': fingerprint},
        if (reality is Map<String, dynamic> && realityPubKey is String)
          'reality': {
            'enabled': true,
            'public_key': realityPubKey,
            'short_id': reality['short_id'] as String? ?? '',
          },
      },
    };
  }

  static Map<String, dynamic>? _buildVlessTransport(
    Map<String, dynamic> config,
  ) {
    final raw = (config['transport'] as String?)?.trim().toLowerCase();
    if (raw == null || raw.isEmpty || raw == 'tcp') return null;
    final mapped = switch (raw) {
      'xhttp' || 'splithttp' => 'http',
      'http' || 'ws' || 'grpc' || 'httpupgrade' => raw,
      _ => raw,
    };
    return {
      'type': mapped,
      if (config['path'] is String) 'path': config['path'] as String,
      if (mapped == 'http' && config['host'] is String)
        'host': [config['host'] as String]
      else if (mapped == 'httpupgrade' && config['host'] is String)
        'host': config['host'] as String,
      if (mapped == 'grpc' && config['service_name'] is String)
        'service_name': config['service_name'] as String,
    };
  }

  static Map<String, dynamic> _generateWireGuardEndpoint(
    ServerNode node, {
    required String tag,
    String? detour,
  }) {
    final config = node.config;
    if (node.protocol == ProtocolType.amneziaWg) {
      const awgKeys = ['jc', 'jmin', 'jmax', 's1', 's2', 'i1', 'i2', 'i3'];
      if (awgKeys.any(config.containsKey)) {
        throw const ConfigGenerationException(
          'AmneziaWG CPS extensions require a custom sing-box fork',
          protocol: ProtocolType.amneziaWg,
        );
      }
    }

    final port = config['port'] as int?;
    final privateKey = config['private_key'] as String?;
    final peerPublicKey = config['peer_public_key'] as String?;
    if (port == null || privateKey == null || peerPublicKey == null) {
      throw ConfigGenerationException(
        'WireGuard config missing required fields: port, private_key, peer_public_key',
        protocol: node.protocol,
      );
    }

    final rawLocal = config['local_address'];
    final localAddresses = switch (rawLocal) {
      final List list => [for (final item in list) item.toString()],
      final String s when s.isNotEmpty => [s],
      _ => const ['10.0.0.2/32'],
    };

    return {
      'type': 'wireguard',
      'tag': tag,
      if (config['mtu'] is int) 'mtu': config['mtu'] as int,
      'address': localAddresses,
      'private_key': privateKey,
      if (detour != null) 'detour': detour,
      'peers': [
        {
          'address': node.address,
          'port': port,
          'public_key': peerPublicKey,
          if (config['pre_shared_key'] is String)
            'pre_shared_key': config['pre_shared_key'] as String,
          'allowed_ips': const ['0.0.0.0/0', '::/0'],
          if (config['reserved'] is List) 'reserved': config['reserved'],
        },
      ],
    };
  }
}
