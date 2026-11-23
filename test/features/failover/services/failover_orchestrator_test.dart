import 'package:fetu/features/connection/models/server_node.dart';
import 'package:fetu/features/failover/models/failover_event.dart';
import 'package:fetu/features/failover/models/failover_strategy.dart';
import 'package:fetu/features/failover/models/protocol_health.dart';
import 'package:fetu/features/failover/services/failover_orchestrator.dart';
import 'package:fetu/features/failover/services/protocol_health_monitor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FailoverOrchestrator', () {
    late FailoverOrchestrator orchestrator;
    late ProtocolHealthMonitor healthMonitor;
    late ServerNode testNode;

    setUp(() {
      healthMonitor = ProtocolHealthMonitor(
        healthProbe: (_) async => true,
        canaryProbe: (_, __) async => true,
      );

      orchestrator = FailoverOrchestrator(
        healthMonitor: healthMonitor,
        strategy: FailoverStrategy.defaultStrategy,
      );

      testNode = const ServerNode(
        id: 'test-node-1',
        name: 'Test Server NY',
        countryCode: 'US',
        address: '1.2.3.4:8080',
        protocol: ProtocolType.hysteria2,
        config: {},
      );
    });

    tearDown(() {
      orchestrator.dispose();
      healthMonitor.dispose();
    });

    test('должен стартовать с null протоколом', () {
      expect(orchestrator.currentProtocol, isNull);
      expect(orchestrator.currentNode, isNull);
    });

    test('должен запускать мониторинг', () async {
      await orchestrator.start(testNode, ProtocolType.hysteria2);

      expect(orchestrator.currentProtocol, ProtocolType.hysteria2);
      expect(orchestrator.currentNode, testNode);

      await orchestrator.stop();
    });

    test('должен эмитить события failover', () async {
      final events = <FailoverEvent>[];
      orchestrator.failoverEvents.listen(events.add);

      await orchestrator.start(testNode, ProtocolType.hysteria2);

      // Принудительный failover
      await orchestrator.forceFailover();

      expect(events, isNotEmpty);
      expect(events.first.fromProtocol, ProtocolType.hysteria2);
      expect(events.first.toProtocol, ProtocolType.amneziaWg);

      await orchestrator.stop();
    });

    test('должен переключаться на следующий протокол при failover', () async {
      await orchestrator.start(testNode, ProtocolType.hysteria2);
      expect(orchestrator.currentProtocol, ProtocolType.hysteria2);

      await orchestrator.forceFailover();
      expect(orchestrator.currentProtocol, ProtocolType.amneziaWg);

      await orchestrator.forceFailover();
      expect(orchestrator.currentProtocol, ProtocolType.vlessReality);

      await orchestrator.stop();
    });

    test('должен использовать стратегию по умолчанию', () {
      expect(orchestrator.strategy, FailoverStrategy.defaultStrategy);
      expect(
        orchestrator.strategy.protocolOrder,
        [
          ProtocolType.hysteria2,
          ProtocolType.amneziaWg,
          ProtocolType.vlessReality,
          ProtocolType.naive,
          ProtocolType.mieru,
        ],
      );
    });

    test('должен правильно определять UDP протоколы', () {
      expect(
        orchestrator.strategy.isUdpProtocol(ProtocolType.hysteria2),
        isTrue,
      );
      expect(
        orchestrator.strategy.isUdpProtocol(ProtocolType.amneziaWg),
        isTrue,
      );
      expect(
        orchestrator.strategy.isUdpProtocol(ProtocolType.vlessReality),
        isFalse,
      );
      expect(orchestrator.strategy.isUdpProtocol(ProtocolType.naive), isFalse);
    });

    test('должен получать первый TCP протокол для fallback', () {
      expect(
        orchestrator.strategy.firstTcpProtocol,
        ProtocolType.vlessReality,
      );
    });

    test('вызывает onSwitchProtocol и ограничивается availableProtocols',
        () async {
      final switched = <ProtocolType>[];
      final custom = FailoverOrchestrator(
        healthMonitor: healthMonitor,
        onSwitchProtocol: (target) async => switched.add(target),
      );
      addTearDown(custom.dispose);

      await custom.start(
        testNode,
        ProtocolType.hysteria2,
        availableProtocols: const [
          ProtocolType.hysteria2,
          ProtocolType.vlessReality,
        ],
      );
      await custom.forceFailover();

      expect(switched, [ProtocolType.vlessReality]);
      expect(custom.currentProtocol, ProtocolType.vlessReality);
      await custom.stop();
    });

    test('при ошибке переключения на протокол пробует следующий в цепочке',
        () async {
      final attempts = <ProtocolType>[];
      final custom = FailoverOrchestrator(
        healthMonitor: healthMonitor,
        onSwitchProtocol: (target) async {
          attempts.add(target);
          if (target == ProtocolType.amneziaWg) {
            throw StateError('unsupported');
          }
        },
      );
      addTearDown(custom.dispose);

      await custom.start(testNode, ProtocolType.hysteria2);
      await custom.forceFailover();

      expect(attempts, [ProtocolType.amneziaWg, ProtocolType.vlessReality]);
      expect(custom.currentProtocol, ProtocolType.vlessReality);
      await custom.stop();
    });

    test('при исчерпании протоколов вызывает onSwitchBackupRelay', () async {
      var relaySwitched = false;
      final events = <FailoverEvent>[];
      final custom = FailoverOrchestrator(
        healthMonitor: healthMonitor,
        onSwitchProtocol: (_) async => throw StateError('fail'),
        onSwitchBackupRelay: () async {
          relaySwitched = true;
          return true;
        },
      );
      custom.failoverEvents.listen(events.add);
      addTearDown(custom.dispose);

      await custom.start(
        testNode,
        ProtocolType.hysteria2,
        availableProtocols: const [ProtocolType.hysteria2],
      );
      await custom.forceFailover();
      await Future<void>.delayed(Duration.zero);

      expect(relaySwitched, isTrue);
      expect(events.single.errorDetails, 'cascade_relay_failover');
      await custom.stop();
    });

    test('после перехода на резервный каскад перебор протоколов продолжается',
        () async {
      final switchedProtocols = <ProtocolType>[];
      var relaySwitched = false;
      final custom = FailoverOrchestrator(
        healthMonitor: healthMonitor,
        onSwitchProtocol: (target) async {
          switchedProtocols.add(target);
        },
        onSwitchBackupRelay: () async {
          relaySwitched = true;
          return true;
        },
      );
      addTearDown(custom.dispose);

      // Стартуем на последнем доступном протоколе (vlessReality).
      await custom.start(
        testNode,
        ProtocolType.vlessReality,
        availableProtocols: const [
          ProtocolType.hysteria2,
          ProtocolType.vlessReality,
        ],
      );

      // 1-й failover: протоколы на текущем каскаде исчерпаны -> переход на резервный каскад.
      await custom.forceFailover();
      expect(relaySwitched, isTrue);

      // 2-й failover на новом каскаде: должен суметь вернуться к hysteria2.
      await custom.forceFailover();
      expect(switchedProtocols, [ProtocolType.hysteria2]);
      expect(custom.currentProtocol, ProtocolType.hysteria2);
      await custom.stop();
    });
  });

  group('ProtocolType', () {
    test('должен иметь правильный порядок приоритетов', () {
      expect(ProtocolType.hysteria2.priority, 1);
      expect(ProtocolType.amneziaWg.priority, 2);
      expect(ProtocolType.vlessReality.priority, 3);
      expect(ProtocolType.naive.priority, 4);
      expect(ProtocolType.mieru.priority, 5);
    });

    test('должен правильно определять UDP/TCP', () {
      expect(ProtocolType.hysteria2.isUdp, isTrue);
      expect(ProtocolType.amneziaWg.isUdp, isTrue);
      expect(ProtocolType.vlessReality.isUdp, isFalse);
      expect(ProtocolType.naive.isTcp, isTrue);
    });

    test('должен возвращать следующий протокол', () {
      expect(ProtocolType.hysteria2.nextProtocol, ProtocolType.amneziaWg);
      expect(ProtocolType.amneziaWg.nextProtocol, ProtocolType.vlessReality);
      expect(ProtocolType.vlessReality.nextProtocol, ProtocolType.naive);
      expect(ProtocolType.mieru.nextProtocol, ProtocolType.shadowsocks);
    });
  });

  group('ProtocolHealth', () {
    test('должен правильно определять необходимость failover', () {
      expect(ProtocolHealth.healthy.requiresFailover, isFalse);
      expect(ProtocolHealth.degraded.requiresFailover, isFalse);
      expect(ProtocolHealth.failed.requiresFailover, isTrue);
      expect(ProtocolHealth.blocked.requiresFailover, isTrue);
    });

    test('должен правильно определять необходимость TCP fallback', () {
      expect(ProtocolHealth.degraded.requiresTcpFallback, isTrue);
      expect(ProtocolHealth.healthy.requiresTcpFallback, isFalse);
      expect(ProtocolHealth.failed.requiresTcpFallback, isFalse);
    });
  });
}
