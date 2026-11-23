import 'dart:convert';

import 'package:fetu/features/connection/models/connection_state.dart';
import 'package:fetu/features/connection/models/server_node.dart';
import 'package:fetu/features/connection/services/vpn_connection_service.dart';
import 'package:fetu/features/split_tunnel/models/rule_action.dart';
import 'package:fetu/features/split_tunnel/models/rule_type.dart';
import 'package:fetu/features/split_tunnel/models/split_rule.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../mocks/mock_vpn_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockVpnMethodChannel channel;
  late List<SplitRule> activeRules;

  const testNode = ServerNode(
    id: 'test-node-1',
    name: 'Test Server',
    countryCode: 'US',
    address: '127.0.0.1',
    protocol: ProtocolType.shadowsocks,
    config: {
      'server_port': 8388,
      'password': 'test-password',
      'method': 'chacha20-ietf-poly1305',
    },
  );

  /// Извлекает route.rules последнего конфига из мок-канала.
  List<dynamic> lastRouteRules(MockVpnMethodChannel mock) =>
      ((jsonDecode(mock.currentConfig!) as Map<String, dynamic>)['route']
          as Map<String, dynamic>)['rules'] as List<dynamic>;

  group('VpnConnectionService + Split Tunneling (Zero-Drop)', () {
    late VpnConnectionService service;

    setUp(() {
      channel = MockVpnMethodChannel();
      activeRules = [
        const SplitRule(
          id: 'r1',
          type: RuleType.domainSuffix,
          pattern: 'vk.com',
          action: RuleAction.direct,
        ),
      ];
      service = VpnConnectionService(
        mode: VpnServiceMode.real,
        channel: channel,
        splitRulesProvider: () => activeRules,
      );
    });

    tearDown(() {
      service.dispose();
    });

    test('connect передаёт активные правила в конфигурацию', () async {
      await service.connect(testNode);
      // Статусные события канала доезжают асинхронно — выкачиваем очередь.
      await pumpEventQueue();

      expect(service.currentState, ConnectionState.connected);
      expect(
        lastRouteRules(channel),
        contains(containsPair('domain_suffix', ['vk.com'])),
      );
    });

    test('смена правил → reloadConfig, туннель НЕ разрывается', () async {
      await service.connect(testNode);
      await pumpEventQueue();
      expect(channel.reloadCalls, 0);

      // Пользователь добавил правило блокировки рекламы.
      activeRules = [
        ...activeRules,
        const SplitRule(
          id: 'r2',
          type: RuleType.domainSuffix,
          pattern: 'ads.com',
          action: RuleAction.block,
        ),
      ];

      await service.applySplitRules();

      expect(channel.reloadCalls, 1, reason: 'конфиг перезагружен');
      expect(
        service.currentState,
        ConnectionState.connected,
        reason: 'Zero-Drop: состояние не менялось',
      );
      expect(
        channel.disconnectCalls,
        0,
        reason: 'Zero-Drop: disconnect не вызывался',
      );
      expect(
        lastRouteRules(channel),
        contains(containsPair('domain_suffix', ['ads.com'])),
      );
    });

    test('applySplitRules без активного туннеля — без ошибок и reload',
        () async {
      await service.applySplitRules();

      expect(channel.reloadCalls, 0);
      expect(service.currentState, ConnectionState.disconnected);
    });

    test('после нативной ошибки applySplitRules пропускается без исключения',
        () async {
      await service.connect(testNode);
      await pumpEventQueue();

      // Нативный слой упал: сервис в состоянии error.
      channel.simulateError('native crash');
      await pumpEventQueue();

      await service.applySplitRules();

      expect(service.currentState, ConnectionState.error);
      expect(channel.reloadCalls, 0);
    });

    test('switchProtocol вызывает reloadConfig и обновляет currentNode',
        () async {
      const hy2Node = ServerNode(
        id: 'n1',
        name: 'HY2',
        countryCode: 'DE',
        address: '1.2.3.4',
        protocol: ProtocolType.hysteria2,
        config: {'port': 443, 'password': 'pw'},
      );
      const realityNode = ServerNode(
        id: 'n1',
        name: 'Reality',
        countryCode: 'DE',
        address: '1.2.3.4',
        protocol: ProtocolType.vlessReality,
        config: {
          'port': 443,
          'uuid': 'uuid-1',
          'reality': {'public_key': 'pub', 'short_id': '12'},
        },
      );

      await service.connect(
        hy2Node,
        fallbackNodes: const [hy2Node, realityNode],
      );
      await pumpEventQueue();
      await service.switchProtocol(ProtocolType.vlessReality);

      expect(channel.reloadCalls, 1);
      expect(service.currentNode?.protocol, ProtocolType.vlessReality);
    });

    test('connect пропускает неподдерживаемый amneziaWg и берёт vlessReality',
        () async {
      const awgNode = ServerNode(
        id: 'n2',
        name: 'AWG',
        countryCode: 'DE',
        address: '1.2.3.4',
        protocol: ProtocolType.amneziaWg,
        config: {
          'port': 51820,
          'private_key': 'p',
          'peer_public_key': 'k',
          'jc': 4,
        },
      );
      const realityNode = ServerNode(
        id: 'n2',
        name: 'Reality',
        countryCode: 'DE',
        address: '1.2.3.4',
        protocol: ProtocolType.vlessReality,
        config: {
          'port': 443,
          'uuid': 'uuid-1',
          'reality': {'public_key': 'pub', 'short_id': '12'},
        },
      );

      await service.connect(
        awgNode,
        fallbackNodes: const [awgNode, realityNode],
      );
      await pumpEventQueue();

      expect(service.currentState, ConnectionState.connected);
      expect(service.currentNode?.protocol, ProtocolType.vlessReality);
    });
  });
}
