import 'package:fetu/features/connection/models/server_node.dart';
import 'package:fetu/features/servers/controllers/server_list_controller.dart';
import 'package:fetu/features/servers/models/node_health_score.dart';
import 'package:fetu/features/servers/services/network_profile_memory.dart';
import 'package:fetu/features/servers/services/ping_service.dart';
import 'package:fetu/features/servers/services/server_list_service.dart';
import 'package:fetu/features/servers/services/smart_node_scorer.dart';
import 'package:fetu/features/subscription/models/subscription.dart';
import 'package:fetu/features/subscription/models/subscription_node.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/subscription_fixtures.dart';
import '../../../helpers/test_storage.dart';

void main() {
  group('PingService (кэширование 5 минут)', () {
    test('кэширует замер на 5 минут и обновляет после истечения TTL', () async {
      var now = DateTime(2026, 11, 23, 9, 0);
      var tcpCalls = 0;
      final service = PingService(
        clock: () => now,
        tcpProbe: (host, port, _) async {
          tcpCalls++;
          return Duration(milliseconds: 30 + tcpCalls * 5);
        },
      );

      final node = SubscriptionNode.fromJson(validNode(id: 'nl-1'));

      final first = await service.measureNode(node);
      expect(first.latencyMs, 35);
      expect(tcpCalls, 1);

      // Через 4 минуты — возвращается значение из кэша.
      now = now.add(const Duration(minutes: 4));
      final cached = await service.measureNode(node);
      expect(cached.latencyMs, 35);
      expect(tcpCalls, 1);

      // Через 5 минут — выполняется новый замер.
      now = now.add(const Duration(minutes: 1));
      final refreshed = await service.measureNode(node);
      expect(refreshed.latencyMs, 40);
      expect(tcpCalls, 2);
    });

    test('probeRealDelay204 использует переданный HTTP-204 зонд', () async {
      final service = PingService(
        realDelayProbe: (_, __) async => const Duration(milliseconds: 77),
      );
      final delay = await service.probeRealDelay204();
      expect(delay, const Duration(milliseconds: 77));
    });
  });

  group('NodeHealthScore и SmartNodeScorer', () {
    test('штрафует потерю пакетов >15% и проваленный payload-зонд до score=0',
        () {
      final blockedLoss = NodeHealthScore.calculate(
        realDelayMs: 25,
        packetLossPercent: 20,
      );
      expect(blockedLoss.score, 0);
      expect(blockedLoss.isBlocked, isTrue);

      final blockedPayload = NodeHealthScore.calculate(
        realDelayMs: 25,
        payloadProbePassed: false,
      );
      expect(blockedPayload.score, 0);
      expect(blockedPayload.isBlocked, isTrue);
    });

    test('выбирает узел по минимальной задержке и учитывает память сети',
        () async {
      final storage = TestStorage();
      await storage.init();
      final memory = NetworkProfileMemory(
        storage: storage,
        fingerprintProvider: () async => 'wifi:home',
      );
      await memory.recordSuccess(protocol: ProtocolType.hysteria2);

      final pingService = PingService(
        tcpProbe: (host, _, __) async {
          if (host.contains('fast')) return const Duration(milliseconds: 20);
          return const Duration(milliseconds: 180);
        },
      );
      final scorer = SmartNodeScorer(
        pingService: pingService,
        networkMemory: memory,
        apiFetcher: (_) async => null,
      );

      final slowNode = SubscriptionNode.fromJson({
        ...validNode(id: 'slow'),
        'name': 'Slow',
        'domains': const [
          {'address': 'slow.vpn.com', 'priority': 1, 'status': 'active'},
        ],
      });
      final fastNode = SubscriptionNode.fromJson({
        ...validNode(id: 'fast'),
        'name': 'Fast',
        'domains': const [
          {'address': 'fast.vpn.com', 'priority': 1, 'status': 'active'},
        ],
      });

      final result = await scorer.selectBestNode([slowNode, fastNode]);
      expect(result, isNotNull);
      expect(result!.server.id, 'fast');
      expect(result.fromProviderApi, isFalse);
      expect(result.server.healthScore!.networkMemoryBonus, greaterThan(0));
    });

    test('использует ответ smart_selection_url провайдера и fallback при сбое',
        () async {
      final pingService = PingService(
        tcpProbe: (_, __, ___) async => const Duration(milliseconds: 50),
      );
      final storage = TestStorage();
      await storage.init();
      final memory = NetworkProfileMemory(
        storage: storage,
        fingerprintProvider: () async => 'cell:mts',
      );
      final apiScorer = SmartNodeScorer(
        pingService: pingService,
        networkMemory: memory,
        apiFetcher: (_) async => 'de-2',
      );

      final nodes = [
        SubscriptionNode.fromJson(validNode(id: 'de-1')),
        SubscriptionNode.fromJson(validNode(id: 'de-2')),
      ];

      final apiResult = await apiScorer.selectBestNode(
        nodes,
        smartSelectionUrl: 'https://api.example/smart',
      );
      expect(apiResult!.server.id, 'de-2');
      expect(apiResult.fromProviderApi, isTrue);

      final fallbackScorer = SmartNodeScorer(
        pingService: pingService,
        networkMemory: memory,
        apiFetcher: (_) async => throw StateError('API down'),
      );
      final fallbackResult = await fallbackScorer.selectBestNode(
        nodes,
        smartSelectionUrl: 'https://api.example/smart',
      );
      expect(fallbackResult!.fromProviderApi, isFalse);
      expect(fallbackResult.server.id, 'de-1');
    });
  });

  group('ServerListController и ServerListService', () {
    test('фильтрует, сортирует и обновляет задержки с сохранением кэша',
        () async {
      final storage = TestStorage();
      await storage.init();
      final memory = NetworkProfileMemory(
        storage: storage,
        fingerprintProvider: () async => 'wifi:office',
      );
      final pingService = PingService(
        tcpProbe: (host, _, __) async => host.contains('de')
            ? const Duration(milliseconds: 35)
            : const Duration(milliseconds: 90),
      );
      final scorer = SmartNodeScorer(
        pingService: pingService,
        networkMemory: memory,
      );
      final sub = Subscription.fromJson({
        ...minimalSubscription(
          nodes: [
            {
              ...validNode(id: 'jp-1'),
              'name': 'Tokyo-01',
              'country': 'JP',
              'domains': [
                {'address': 'jp.vpn.com', 'priority': 1, 'status': 'active'},
              ],
            },
            {
              ...validNode(id: 'de-1'),
              'name': 'Berlin-01',
              'country': 'DE',
              'domains': [
                {'address': 'de.vpn.com', 'priority': 1, 'status': 'active'},
              ],
            },
          ],
        ),
      });

      final controller = ServerListController(
        pingService: pingService,
        scorer: scorer,
        networkMemory: memory,
        subscriptionProvider: () => sub,
      );
      addTearDown(controller.dispose);

      controller.syncWithSubscription(sub);
      await controller.refreshLatencies(subscription: sub);

      controller.setSortOrder(ServerSortOrder.lowestLatency);
      expect(controller.filteredServers.first.id, 'de-1');

      controller.setCountryFilter('JP');
      expect(controller.filteredServers.map((s) => s.id), ['jp-1']);

      controller.setCountryFilter('JP');
      controller.setSearchQuery('berlin');
      expect(controller.filteredServers.map((s) => s.id), ['de-1']);
    });
  });
}
