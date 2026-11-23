import 'dart:convert';

import 'package:fetu/core/platform/vpn_method_channel.dart';
import 'package:fetu/features/connection/models/connection_state.dart';
import 'package:fetu/features/connection/models/server_node.dart';
import 'package:fetu/features/connection/services/vpn_connection_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../mocks/mock_vpn_method_channel.dart';

void main() {
  group('VpnConnectionService', () {
    late VpnConnectionService service;
    late ServerNode testNode;

    setUp(() {
      // Используем mock-режим для тестов (без Platform Channel)
      service = VpnConnectionService(mode: VpnServiceMode.mock);
      testNode = const ServerNode(
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
    });

    tearDown(() {
      service.dispose();
    });

    test('начальное состояние - disconnected', () {
      expect(service.currentState, ConnectionState.disconnected);
    });

    test('connect изменяет состояние на connected', () async {
      await service.connect(testNode);
      expect(service.currentState, ConnectionState.connected);
    });

    test('disconnect изменяет состояние на disconnected', () async {
      await service.connect(testNode);
      await service.disconnect();
      expect(service.currentState, ConnectionState.disconnected);
    });

    test('нельзя подключиться дважды', () async {
      await service.connect(testNode);
      expect(
        () => service.connect(testNode),
        throwsA(isA<StateError>()),
      );
    });

    test('метрики обновляются после подключения', () async {
      await service.connect(testNode);

      // Даём время таймеру обновить метрики
      await Future.delayed(const Duration(seconds: 2));

      final metrics = service.currentMetrics;
      expect(metrics.downloadSpeed, greaterThan(0));
      expect(metrics.uploadSpeed, greaterThan(0));
      expect(metrics.connectionDuration, greaterThanOrEqualTo(1));
    });

    test('метрики сбрасываются после отключения', () async {
      await service.connect(testNode);
      await Future.delayed(const Duration(seconds: 1));
      await service.disconnect();

      final metrics = service.currentMetrics;
      expect(metrics.downloadSpeed, 0);
      expect(metrics.uploadSpeed, 0);
      expect(metrics.totalDownloaded, 0);
      expect(metrics.totalUploaded, 0);
    });
  });

  group('VpnConnectionService — мульти-каскады и failover релеев', () {
    const exitNode = ServerNode(
      id: 'de-1',
      name: 'Germany',
      countryCode: 'DE',
      address: 'de.example.com',
      protocol: ProtocolType.vlessReality,
      config: {
        'port': 443,
        'uuid': 'uuid-de',
        'reality': {
          'public_key': 'pub',
          'short_id': '1234',
          'server_name': 'www.microsoft.com',
        },
      },
    );

    const primaryRelay = ServerNode(
      id: 'relay-msk',
      name: 'MSK Relay',
      countryCode: 'RU',
      address: 'msk.example.com',
      protocol: ProtocolType.hysteria2,
      config: {'port': 443, 'password': 'pw1'},
    );

    const backupRelay = ServerNode(
      id: 'relay-spb',
      name: 'SPB Relay',
      countryCode: 'RU',
      address: 'spb.example.com',
      protocol: ProtocolType.vlessReality,
      config: {
        'port': 443,
        'uuid': 'uuid-spb',
        'reality': {
          'public_key': 'pub2',
          'short_id': '5678',
          'server_name': 'www.microsoft.com',
        },
      },
    );

    test(
        'connect с relayCandidates передаёт relayNode и автопереключается при сбое connect',
        () async {
      final channel = MockVpnMethodChannel();
      var attempts = 0;
      final realService = VpnConnectionService(
        mode: VpnServiceMode.real,
        channel: channel,
      );
      addTearDown(realService.dispose);

      // Первый вызов connect с primaryRelay падает, второй с backupRelay проходит.
      final failingChannel = _FailFirstConnectChannel(
        failOnAttempt: 1,
      );
      final failoverService = VpnConnectionService(
        mode: VpnServiceMode.real,
        channel: failingChannel,
      );
      addTearDown(() {
        failoverService.dispose();
        channel.dispose();
        failingChannel.dispose();
      });

      await failoverService.connect(
        exitNode,
        relayCandidates: const [primaryRelay, backupRelay],
      );

      attempts = failingChannel.connectConfigs.length;
      expect(attempts, 2);
      final firstRelayConfig = jsonDecode(failingChannel.connectConfigs.first)
          as Map<String, dynamic>;
      final secondRelayConfig = jsonDecode(failingChannel.connectConfigs.last)
          as Map<String, dynamic>;

      final firstOutbounds =
          (firstRelayConfig['outbounds'] as List).cast<Map<String, dynamic>>();
      final secondOutbounds =
          (secondRelayConfig['outbounds'] as List).cast<Map<String, dynamic>>();

      expect(
        firstOutbounds.firstWhere((o) => o['tag'] == 'relay')['server'],
        'msk.example.com',
      );
      expect(
        secondOutbounds.firstWhere((o) => o['tag'] == 'relay')['server'],
        'spb.example.com',
      );
      expect(failoverService.currentRelayNode?.id, 'relay-spb');
    });

    test('switchToBackupRelay перегенерирует конфиг и вызывает reloadConfig',
        () async {
      final channel = _FailFirstConnectChannel(failOnAttempt: -1);
      final realService = VpnConnectionService(
        mode: VpnServiceMode.real,
        channel: channel,
      );
      addTearDown(() {
        realService.dispose();
        channel.dispose();
      });

      await realService.connect(
        exitNode,
        relayCandidates: const [primaryRelay, backupRelay],
      );
      await Future<void>.delayed(Duration.zero);

      expect(realService.currentRelayNode?.id, 'relay-msk');
      expect(realService.hasBackupRelay, isTrue);

      final switched = await realService.switchToBackupRelay();
      expect(switched, isTrue);
      expect(realService.currentRelayNode?.id, 'relay-spb');
      expect(channel.reloadedConfigs, hasLength(1));

      final reloaded =
          jsonDecode(channel.reloadedConfigs.single) as Map<String, dynamic>;
      final outbounds =
          (reloaded['outbounds'] as List).cast<Map<String, dynamic>>();
      expect(
        outbounds.firstWhere((o) => o['tag'] == 'relay')['server'],
        'spb.example.com',
      );
    });

    test(
        'после нативной ошибки (ConnectionState.error) switchToBackupRelay восстанавливает connected',
        () async {
      final channel = _FailFirstConnectChannel(failOnAttempt: -1);
      final realService = VpnConnectionService(
        mode: VpnServiceMode.real,
        channel: channel,
      );
      addTearDown(() {
        realService.dispose();
        channel.dispose();
      });

      await realService.connect(
        exitNode,
        relayCandidates: const [primaryRelay, backupRelay],
      );
      await Future<void>.delayed(Duration.zero);

      channel.simulateError('tls handshake failure');
      await Future<void>.delayed(Duration.zero);
      expect(realService.currentState, ConnectionState.error);

      final switched = await realService.switchToBackupRelay();
      expect(switched, isTrue);
      expect(realService.currentState, ConnectionState.connected);
      expect(realService.currentRelayNode?.id, 'relay-spb');
    });
  });
}

class _FailFirstConnectChannel extends MockVpnMethodChannel {
  _FailFirstConnectChannel({required this.failOnAttempt});

  final int failOnAttempt;
  final List<String> connectConfigs = <String>[];
  final List<String> reloadedConfigs = <String>[];

  @override
  Future<void> connect(String configJson) async {
    connectConfigs.add(configJson);
    if (connectConfigs.length == failOnAttempt) {
      throw const VpnChannelException('Relay unreachable', code: 'CONNECT_ERR');
    }
    await super.connect(configJson);
  }

  @override
  Future<void> reloadConfig(String configJson) async {
    reloadedConfigs.add(configJson);
    await super.reloadConfig(configJson);
  }
}
