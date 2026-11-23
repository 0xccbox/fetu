import 'package:fetu/features/connection/models/server_node.dart';
import 'package:fetu/features/failover/models/protocol_health.dart';
import 'package:fetu/features/failover/services/protocol_health_monitor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProtocolHealthMonitor', () {
    late ProtocolHealthMonitor monitor;
    late ServerNode testNode;

    setUp(() {
      monitor = ProtocolHealthMonitor(
        checkInterval: const Duration(milliseconds: 100),
        healthProbe: (_) async => true,
        canaryProbe: (_, __) async => true,
      );

      testNode = const ServerNode(
        id: 'test-node-1',
        name: 'Test Server',
        countryCode: 'US',
        address: '1.2.3.4:8080',
        protocol: ProtocolType.hysteria2,
        config: {},
      );
    });

    tearDown(() {
      monitor.dispose();
    });

    test('должен начинать со статуса unknown', () {
      expect(monitor.currentHealth, ProtocolHealth.unknown);
    });

    test('должен запускать и останавливать мониторинг', () {
      monitor.startMonitoring(testNode);
      expect(monitor.currentHealth, ProtocolHealth.unknown);

      monitor.stopMonitoring();
    });

    test('должен эмитить события здоровья в stream', () async {
      final healthEvents = <ProtocolHealth>[];

      monitor.healthStream.listen(healthEvents.add);
      monitor.startMonitoring(testNode);

      // Ждём несколько проверок
      await Future.delayed(const Duration(milliseconds: 500));

      expect(healthEvents, isNotEmpty);
      monitor.stopMonitoring();
    });

    test('должен парсить ошибки блокировки из логов', () {
      expect(
        monitor.parseErrorFromLog('connection reset by peer'),
        ProtocolHealth.blocked,
      );

      expect(
        monitor.parseErrorFromLog('TLS handshake failure'),
        ProtocolHealth.blocked,
      );
    });

    test('должен парсить ошибки сбоя из логов', () {
      expect(
        monitor.parseErrorFromLog('connection refused'),
        ProtocolHealth.failed,
      );

      expect(
        monitor.parseErrorFromLog('no route to host'),
        ProtocolHealth.failed,
      );
    });

    test('должен парсить ошибки деградации из логов', () {
      expect(
        monitor.parseErrorFromLog('high packet loss detected'),
        ProtocolHealth.degraded,
      );

      expect(
        monitor.parseErrorFromLog('high latency warning'),
        ProtocolHealth.degraded,
      );
    });

    test('должен сбрасывать метрики', () {
      monitor.startMonitoring(testNode);
      monitor.reset();

      expect(monitor.currentHealth, ProtocolHealth.unknown);
    });

    test('переходит в failed при провале зонда', () async {
      final failing = ProtocolHealthMonitor(
        checkInterval: const Duration(milliseconds: 50),
        healthProbe: (_) async => false,
      );
      final events = <ProtocolHealth>[];
      failing.healthStream.listen(events.add);
      failing.startMonitoring(testNode);
      await Future.delayed(const Duration(milliseconds: 180));
      failing.dispose();

      expect(events, contains(ProtocolHealth.failed));
    });
  });
}
