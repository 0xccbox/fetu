import 'dart:convert';

import 'package:fetu/features/connection/models/local_rule_set_ref.dart';
import 'package:fetu/features/connection/models/server_node.dart';
import 'package:fetu/features/connection/services/singbox_config_generator.dart';
import 'package:fetu/features/split_tunnel/models/rule_action.dart';
import 'package:fetu/features/split_tunnel/models/rule_type.dart';
import 'package:fetu/features/split_tunnel/models/split_rule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const node = ServerNode(
    id: 'test-node',
    name: 'Test Node',
    countryCode: 'US',
    address: '1.2.3.4',
    protocol: ProtocolType.shadowsocks,
    config: {
      'server_port': 8388,
      'method': '2022-blake3-aes-256-gcm',
      'password': 'pw',
    },
  );

  Map<String, dynamic> decode(String config) =>
      jsonDecode(config) as Map<String, dynamic>;

  group('SingBoxConfigGenerator — базовые инварианты 1.12+', () {
    test('конфиг валиден и содержит все секции', () {
      final config = decode(SingBoxConfigGenerator.generate(node));

      expect(config.containsKey('log'), isTrue);
      expect(config.containsKey('dns'), isTrue);
      expect(config.containsKey('inbounds'), isTrue);
      expect(config.containsKey('outbounds'), isTrue);
      expect(config.containsKey('route'), isTrue);
      expect(config.containsKey('experimental'), isTrue);
    });

    test(
        'системные правила маршрутизации 1.12+ остаются первыми, final = proxy',
        () {
      final config = decode(SingBoxConfigGenerator.generate(node));
      final route = config['route'] as Map<String, dynamic>;
      final rules = route['rules'] as List<dynamic>;

      expect(
        rules,
        hasLength(3),
        reason: 'без split-правил — sniff, hijack-dns, reject multicast',
      );
      expect(rules[0], {'action': 'sniff'});
      expect(rules[1], {'protocol': 'dns', 'action': 'hijack-dns'});
      expect((rules[2] as Map<String, dynamic>)['action'], 'reject');
      expect(route['final'], 'proxy');
      expect(route['auto_detect_interface'], isTrue);
      expect(route['default_domain_resolver'], 'bootstrap-dns');
    });

    test('DNS-инвариант 1.12+: нет detour: direct, final = remote-dns', () {
      final config = decode(SingBoxConfigGenerator.generate(node));
      final dns = config['dns'] as Map<String, dynamic>;
      final servers =
          (dns['servers'] as List<dynamic>).cast<Map<String, dynamic>>();

      expect(dns['strategy'], 'ipv4_only');
      expect(dns['final'], 'remote-dns');
      expect(
        servers.any((s) => s['detour'] == 'direct'),
        isFalse,
        reason: 'sing-box 1.12+ запрещает detour: direct',
      );
      expect(
        servers.firstWhere((s) => s['tag'] == 'remote-dns')['detour'],
        'proxy',
      );
      expect(
        servers.firstWhere((s) => s['tag'] == 'bootstrap-dns')['type'],
        'local',
      );
    });
  });

  group('SingBoxConfigGenerator — Split Tunneling и .srs rule_set', () {
    test('split-правила встраиваются после системных, порядок сохранён', () {
      const splitRules = [
        SplitRule(
          id: '1',
          type: RuleType.domainSuffix,
          pattern: 'vk.com',
          action: RuleAction.direct,
        ),
        SplitRule(
          id: '2',
          type: RuleType.domain,
          pattern: 'example.com',
          action: RuleAction.block,
        ),
        SplitRule(
          id: '3',
          type: RuleType.geoip,
          pattern: 'ru, cn',
          action: RuleAction.direct,
        ),
      ];

      final config = decode(
        SingBoxConfigGenerator.generate(node, splitRules: splitRules),
      );
      final route = config['route'] as Map<String, dynamic>;
      final rules = route['rules'] as List<dynamic>;

      expect(rules, hasLength(6), reason: '3 системных + 3 split');
      expect(rules[0], {'action': 'sniff'});
      expect(rules[1], {'protocol': 'dns', 'action': 'hijack-dns'});
      expect((rules[2] as Map<String, dynamic>)['action'], 'reject');

      expect(rules[3], {
        'domain_suffix': ['vk.com'],
        'outbound': 'direct',
      });
      expect(rules[4], {
        'domain': ['example.com'],
        'action': 'reject',
      });
      expect(rules[5], {
        'geoip': ['ru', 'cn'],
        'outbound': 'direct',
      });
    });

    test('выключенные правила не попадают в конфигурацию', () {
      const splitRules = [
        SplitRule(
          id: '1',
          type: RuleType.domainSuffix,
          pattern: 'vk.com',
          action: RuleAction.direct,
          enabled: false,
        ),
      ];

      final config = decode(
        SingBoxConfigGenerator.generate(node, splitRules: splitRules),
      );
      final rules =
          (config['route'] as Map<String, dynamic>)['rules'] as List<dynamic>;

      expect(rules, hasLength(3));
    });

    test('локальные .srs rule_set встраиваются в route.rule_set и route.rules',
        () {
      const ruleSets = [
        LocalRuleSetRef(
          tag: 'geoip-ru',
          path: '/data/user/0/com.fetu.app/files/rulesets/geoip-ru.srs',
          action: RuleAction.direct,
        ),
      ];

      final config = decode(
        SingBoxConfigGenerator.generate(node, ruleSets: ruleSets),
      );
      final route = config['route'] as Map<String, dynamic>;
      final sets = route['rule_set'] as List<dynamic>;
      final rules = route['rules'] as List<dynamic>;

      expect(sets, [
        {
          'type': 'local',
          'tag': 'geoip-ru',
          'format': 'binary',
          'path': '/data/user/0/com.fetu.app/files/rulesets/geoip-ru.srs',
        },
      ]);
      expect(rules.last, {'rule_set': 'geoip-ru', 'outbound': 'direct'});
    });
  });

  group('SingBoxConfigGenerator — протоколы и каскад', () {
    test('naive outbound транслируется в http + tls для sing-box 1.12+', () {
      const naiveNode = ServerNode(
        id: 'naive-1',
        name: 'Naive Node',
        countryCode: 'DE',
        address: '1.2.3.5',
        protocol: ProtocolType.naive,
        config: {
          'port': 8443,
          'username': 'user1',
          'password': 'pw',
          'tls_sni': 'cdn.example.com',
        },
      );

      final config = decode(SingBoxConfigGenerator.generate(naiveNode));
      final proxy = (config['outbounds'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .first;

      expect(proxy['type'], 'http');
      expect(proxy['server_port'], 8443);
      expect(proxy['username'], 'user1');
      expect(proxy['tag'], 'proxy');
      expect((proxy['tls'] as Map<String, dynamic>)['enabled'], isTrue);
      expect(
        (proxy['tls'] as Map<String, dynamic>)['server_name'],
        'cdn.example.com',
      );
    });

    test('mieru outbound формируется корректно', () {
      const mieruNode = ServerNode(
        id: 'mieru-1',
        name: 'Mieru Node',
        countryCode: 'FI',
        address: '1.2.3.6',
        protocol: ProtocolType.mieru,
        config: {'port': 8964, 'username': 'user2', 'password': 'pw2'},
      );

      final config = decode(SingBoxConfigGenerator.generate(mieruNode));
      final proxy = (config['outbounds'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .first;

      expect(proxy['type'], 'mieru');
      expect(proxy['server_port'], 8964);
    });

    test('vlessReality с XHTTP, uTLS и TLS fragment', () {
      const realityNode = ServerNode(
        id: 'reality-1',
        name: 'Reality XHTTP',
        countryCode: 'NL',
        address: '1.2.3.7',
        protocol: ProtocolType.vlessReality,
        config: {
          'port': 443,
          'uuid': 'uuid-x',
          'transport': 'xhttp',
          'path': '/split',
          'host': 'cdn.example.com',
          'tls_fragment': true,
          'utls_fingerprint': 'chrome',
          'reality': {
            'public_key': 'PubKey',
            'short_id': '6ba8',
            'server_name': 'www.microsoft.com',
          },
          'tls_sni': 'www.microsoft.com',
        },
      );

      final config = decode(SingBoxConfigGenerator.generate(realityNode));
      final proxy = (config['outbounds'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .first;
      final tls = proxy['tls'] as Map<String, dynamic>;
      final transport = proxy['transport'] as Map<String, dynamic>;

      expect(proxy['type'], 'vless');
      expect(proxy.containsKey('flow'), isFalse);
      expect(transport, {
        'type': 'http',
        'path': '/split',
        'host': ['cdn.example.com'],
      });
      expect(tls['fragment'], isTrue);
      expect(tls['utls'], {'enabled': true, 'fingerprint': 'chrome'});
      expect((tls['reality'] as Map<String, dynamic>)['enabled'], isTrue);
    });

    test('wireguard генерирует endpoint, а amneziaWg с CPS бросает исключение',
        () {
      const wgNode = ServerNode(
        id: 'wg-1',
        name: 'WireGuard',
        countryCode: 'DE',
        address: '1.2.3.8',
        protocol: ProtocolType.wireguard,
        config: {
          'port': 51820,
          'private_key': 'priv',
          'peer_public_key': 'pub',
          'local_address': ['10.0.0.2/32'],
        },
      );

      final config = decode(SingBoxConfigGenerator.generate(wgNode));
      final endpoints =
          (config['endpoints'] as List<dynamic>).cast<Map<String, dynamic>>();

      expect(endpoints.single['type'], 'wireguard');
      expect(endpoints.single['tag'], 'proxy');

      const awgNode = ServerNode(
        id: 'awg-1',
        name: 'AmneziaWG',
        countryCode: 'DE',
        address: '1.2.3.9',
        protocol: ProtocolType.amneziaWg,
        config: {
          'port': 51820,
          'private_key': 'priv',
          'peer_public_key': 'pub',
          'jc': 4,
        },
      );

      expect(
        () => SingBoxConfigGenerator.generate(awgNode),
        throwsA(isA<ConfigGenerationException>()),
      );
    });

    test('каскадный relay добавляет outbound relay и detour у proxy', () {
      const relayNode = ServerNode(
        id: 'relay-1',
        name: 'Moscow Relay',
        countryCode: 'RU',
        address: '5.6.7.8',
        protocol: ProtocolType.hysteria2,
        config: {'port': 443, 'password': 'rpw'},
      );

      final config = decode(
        SingBoxConfigGenerator.generate(node, relayNode: relayNode),
      );
      final outbounds =
          (config['outbounds'] as List<dynamic>).cast<Map<String, dynamic>>();

      expect(outbounds.any((o) => o['tag'] == 'relay'), isTrue);
      expect(
        outbounds.firstWhere((o) => o['tag'] == 'proxy')['detour'],
        'relay',
      );
    });
  });
}
