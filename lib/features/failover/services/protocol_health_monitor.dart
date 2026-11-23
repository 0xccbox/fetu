import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fetu/core/constants/diagnostics_constants.dart';
import 'package:fetu/core/network/http_connection_pool.dart';
import 'package:fetu/features/connection/models/server_node.dart';
import 'package:fetu/features/failover/models/protocol_health.dart';
import 'package:meta/meta.dart';

/// Инъектируемая проверка доступности туннеля (для тестов и мок-режима).
typedef HealthProbeImpl = Future<bool> Function(ServerNode node);

/// Инъектируемая TCP canary-проверка до порта узла.
typedef CanaryTcpProbeImpl = Future<bool> Function(ServerNode node, int port);

/// Мониторинг состояния здоровья активного VPN-протокола.
class ProtocolHealthMonitor {
  /// Создаёт монитор здоровья.
  ProtocolHealthMonitor({
    this.checkInterval = const Duration(seconds: 5),
    this.packetLossWindow = const Duration(seconds: 30),
    @visibleForTesting HealthProbeImpl? healthProbe,
    @visibleForTesting CanaryTcpProbeImpl? canaryProbe,
  })  : _healthProbe = healthProbe ?? _defaultHealthProbe,
        _canaryProbe = canaryProbe ?? _defaultCanaryTcpProbe;

  /// Интервал периодической проверки здоровья.
  final Duration checkInterval;

  /// Окно времени для подсчёта потери пакетов.
  final Duration packetLossWindow;

  final HealthProbeImpl _healthProbe;
  final CanaryTcpProbeImpl _canaryProbe;

  Timer? _monitorTimer;
  int? _canaryTcpPort;
  final _healthController = StreamController<ProtocolHealth>.broadcast();

  final List<bool> _recentProbes = <bool>[];
  static const int _maxWindowProbes = 10;

  /// Stream изменения состояния здоровья протокола.
  Stream<ProtocolHealth> get healthStream => _healthController.stream;

  ProtocolHealth _currentHealth = ProtocolHealth.unknown;

  /// Текущее состояние здоровья протокола.
  ProtocolHealth get currentHealth => _currentHealth;

  /// Запускает периодический мониторинг узла.
  void startMonitoring(ServerNode node, {int? canaryTcpPort}) {
    stopMonitoring();

    _canaryTcpPort = canaryTcpPort;
    _currentHealth = ProtocolHealth.unknown;
    _recentProbes.clear();

    _monitorTimer = Timer.periodic(checkInterval, (_) {
      unawaited(_checkHealth(node));
    });
  }

  /// Останавливает мониторинг.
  void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
  }

  Future<void> _checkHealth(ServerNode node) async {
    try {
      final ok = await _healthProbe(node);
      _recentProbes.add(ok);
      if (_recentProbes.length > _maxWindowProbes) {
        _recentProbes.removeAt(0);
      }

      final failures = _recentProbes.where((passed) => !passed).length;
      final failureRate =
          _recentProbes.isEmpty ? 0.0 : failures / _recentProbes.length;

      if (failureRate > 0.5) {
        _updateHealth(ProtocolHealth.failed);
      } else if (failureRate > 0.05) {
        _updateHealth(ProtocolHealth.degraded);
      } else {
        _updateHealth(ProtocolHealth.healthy);
      }
    } catch (_) {
      _updateHealth(ProtocolHealth.failed);
    }
  }

  /// Проверяет сквозную доступность через общий HTTP-пул (правило 3).
  static Future<bool> _defaultHealthProbe(ServerNode node) async {
    try {
      final response = await HttpConnectionPool.instance.client.get<void>(
        DiagnosticsConstants.realDelayProbeUrl,
        options: Options(
          receiveTimeout: DiagnosticsConstants.realDelayTimeout,
          sendTimeout: DiagnosticsConstants.realDelayTimeout,
          validateStatus: (status) => status == 204 || status == 200,
        ),
      );
      return response.statusCode == 204 || response.statusCode == 200;
    } on DioException {
      return false;
    }
  }

  /// Canary TCP-проверка: доступен ли узел по TCP, когда UDP деградирует.
  Future<bool> checkCanaryTcp(ServerNode node, {int? tcpPort}) async {
    try {
      final port = tcpPort ??
          _canaryTcpPort ??
          (node.config['port'] as int?) ??
          (node.config['server_port'] as int?) ??
          443;
      return await _canaryProbe(node, port);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _defaultCanaryTcpProbe(ServerNode node, int port) async {
    if (node.address.isEmpty || port <= 0) return false;
    try {
      final socket = await Socket.connect(
        node.address,
        port,
        timeout: const Duration(seconds: 3),
      );
      await socket.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Передаёт сообщение об ошибке ядра и обновляет здоровье при совпадении.
  void reportLogError(String log) {
    final parsed = parseErrorFromLog(log);
    if (parsed != ProtocolHealth.unknown) {
      _updateHealth(parsed);
    }
  }

  /// Классифицирует текстовую ошибку ядра sing-box в состояние здоровья.
  ProtocolHealth parseErrorFromLog(String log) {
    final lowerLog = log.toLowerCase();

    if (lowerLog.contains('connection reset') ||
        (lowerLog.contains('timeout') && lowerLog.contains('handshake')) ||
        lowerLog.contains('tls handshake failure')) {
      return ProtocolHealth.blocked;
    }

    if (lowerLog.contains('connection refused') ||
        lowerLog.contains('no route to host') ||
        lowerLog.contains('network unreachable')) {
      return ProtocolHealth.failed;
    }

    if (lowerLog.contains('packet loss') ||
        lowerLog.contains('high latency') ||
        lowerLog.contains('unstable')) {
      return ProtocolHealth.degraded;
    }

    return ProtocolHealth.unknown;
  }

  void _updateHealth(ProtocolHealth newHealth) {
    if (_currentHealth != newHealth) {
      _currentHealth = newHealth;
      if (!_healthController.isClosed) {
        _healthController.add(newHealth);
      }
    }
  }

  /// Сбрасывает накопленную статистику для нового подключения.
  void reset() {
    _recentProbes.clear();
    _currentHealth = ProtocolHealth.unknown;
  }

  /// Освобождает ресурсы монитора.
  void dispose() {
    stopMonitoring();
    _healthController.close();
  }
}
