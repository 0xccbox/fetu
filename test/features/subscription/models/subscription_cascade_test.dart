import 'package:fetu/features/connection/models/server_node.dart';
import 'package:fetu/features/subscription/models/subscription.dart';
import 'package:fetu/features/subscription/models/subscription_cascade.dart';
import 'package:fetu/features/subscription/services/subscription_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/subscription_fixtures.dart';

void main() {
  group('SubscriptionCascade', () {
    test('парсит cascade.relays, backup_relay_ids и attached_exit_nodes',
        () async {
      final raw = {
        ...minimalSubscription(
          nodes: [
            validNode(id: 'de-1'),
            validNode(id: 'nl-1'),
          ],
        ),
        'features': {
          'cascade': {
            'enabled': true,
            'client_auto_failover': true,
            'topology_mode': 'auto_mesh',
            'relays': [
              {
                'id': 'cascade-msk-1',
                'name': 'Москва #1',
                'priority': 1,
                'backup_relay_ids': ['cascade-spb-1'],
                'attached_exit_nodes': ['de-1'],
                'domains': ['msk1.myvpn.com', '185.10.20.30'],
                'protocols': [
                  {
                    'type': 'hysteria2',
                    'port': 443,
                    'password': 'pw1',
                    'priority': 1,
                  },
                  {
                    'type': 'vless',
                    'port': 443,
                    'uuid': '550e8400-e29b-41d4-a716-446655440000',
                    'transport': 'xhttp',
                    'priority': 2,
                  },
                ],
              },
              {
                'id': 'cascade-spb-1',
                'name': 'СПб #2',
                'priority': 2,
                'backup_relay_ids': [
                  'cascade-msk-1',
                ], // цикл для проверки защиты
                'attached_exit_nodes': ['nl-1'],
                'domains': ['spb1.myvpn.com'],
                'protocols': [
                  {
                    'type': 'vless',
                    'port': 443,
                    'uuid': '550e8400-e29b-41d4-a716-446655440001',
                    'priority': 1,
                  },
                ],
              },
            ],
          },
        },
      };

      final sub = await SubscriptionParser.parse(asJson(raw));

      expect(sub.cascade, isNotNull);
      expect(sub.cascade!.enabled, isTrue);
      expect(sub.cascade!.topologyMode, CascadeTopologyMode.autoMesh);
      expect(sub.cascade!.relays, hasLength(2));

      final msk = sub.cascade!.relays.first;
      expect(msk.id, 'cascade-msk-1');
      expect(msk.backupRelayIds, ['cascade-spb-1']);
      expect(msk.attachedExitNodes, ['de-1']);
      expect(msk.primaryAddress, 'msk1.myvpn.com');

      // Для de-1 первым идёт msk, резервным — spb (цикл не зацикливается).
      final relaysForDe = sub.cascade!.resolveRelaysForExitNode('de-1');
      expect(
        relaysForDe.map((r) => r.id).toList(),
        ['cascade-msk-1', 'cascade-spb-1'],
      );

      final serverRelays = sub.resolveRelayCandidates(sub.nodes.first);
      expect(serverRelays, hasLength(3));
      expect(serverRelays.first.id, 'cascade-msk-1');
      expect(serverRelays.first.protocol, ProtocolType.hysteria2);
      expect(serverRelays.last.id, 'cascade-spb-1');
    });

    test('isolated режим не подмешивает чужие каскады при отсутствии привязки',
        () {
      const cascade = SubscriptionCascade(
        enabled: true,
        topologyMode: CascadeTopologyMode.isolated,
        relays: [
          CascadeRelay(
            id: 'r1',
            name: 'R1',
            priority: 1,
            attachedExitNodes: ['de-1'],
          ),
          CascadeRelay(
            id: 'r2',
            name: 'R2',
            priority: 2,
            attachedExitNodes: ['nl-1'],
          ),
        ],
      );

      expect(
        cascade.resolveRelaysForExitNode('de-1').map((r) => r.id).toList(),
        ['r1'],
      );
      expect(cascade.resolveRelaysForExitNode('us-1'), isEmpty);
    });

    test(
        'Subscription.toJson сохраняет блок cascade при повторной сериализации',
        () async {
      final raw = {
        ...minimalSubscription(nodes: [validNode(id: 'de-1')]),
        'features': {
          'cascade': {
            'enabled': true,
            'topology_mode': 'single',
            'relays': [
              {
                'id': 'r1',
                'name': 'R1',
                'priority': 1,
                'attached_exit_nodes': ['de-1'],
                'domains': ['r1.example.com'],
                'protocols': [
                  {
                    'type': 'vless',
                    'port': 443,
                    'uuid': 'uuid-1',
                    'priority': 1,
                  },
                ],
              },
            ],
          },
        },
      };

      final parsed = await SubscriptionParser.parse(asJson(raw));
      final roundTrip = Subscription.fromJson(parsed.toJson());
      expect(roundTrip.cascade, isNotNull);
      expect(roundTrip.cascade!.relays.single.id, 'r1');
      expect(roundTrip.cascade!.topologyMode, CascadeTopologyMode.single);
    });

    test('отклоняет включённый cascade без TCP fallback на relay (правило 9)',
        () async {
      final raw = {
        ...minimalSubscription(),
        'features': {
          'cascade': {
            'enabled': true,
            'relays': [
              {
                'id': 'r-udp',
                'name': 'UDP only relay',
                'domains': ['r.example.com'],
                'protocols': [
                  {'type': 'hysteria2', 'port': 443, 'password': 'pw'},
                ],
              },
            ],
          },
        },
      };

      expect(
        () => SubscriptionParser.parse(asJson(raw)),
        throwsA(isA<SubscriptionParseException>()),
      );
    });
  });
}
