/// Сервис измерения задержки узлов (TCP ping + Real-Delay HTTP 204)
/// с 5-минутным кэшированием (AGENTS.md, правило 22).
library;

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:meta/meta.dart';

import '../../../core/constants/diagnostics_constants.dart';
import '../../../core/constants/server_constants.dart';
import '../../../core/network/http_connection_pool.dart';
import '../../subscription/models/subscription_node.dart';

/// Результат замера одного узла.
@immutable
class PingSample {
  /// Создаёт снимок замера.
  const PingSample({
    required this.nodeId,
    required this.latencyMs,
    required this.measuredAt,
    this.jitterMs = 0,
    this.packetLossPercent = 0,
    this.payloadProbePassed = true,
  });

  /// Идентификатор узла.
  final String nodeId;

  /// Измеренная задержка (мс), либо `null` при недоступности.
  final int? latencyMs;

  /// Оценка джиттера (мс).
  final double jitterMs;

  /// Потеря пакетов (%).
  final double packetLossPercent;

  /// Пройдена ли проверка полезной нагрузки >24 КБ (для Real-Delay).
  final bool payloadProbePassed;

  /// Время замера.
  final DateTime measuredAt;

  /// Доступен ли узел.
  bool get isReachable => latencyMs != null && latencyMs! >= 0;
}

/// Инъектируемый TCP-зонд до `(host, port)` (для unit-тестов без сети).
typedef TcpPingProbe = Future<Duration?> Function(
  String host,
  int port,
  Duration timeout,
);

/// Инъектируемый Real-Delay HTTP 204 зонд через общий HTTP-пул (для тестов).
typedef RealDelay204Probe = Future<Duration?> Function(
  Uri url,
  Duration timeout,
);

/// Инъектируемый источник текущего времени (для детерминированных тестов кэша).
typedef ClockProvider = DateTime Function();

/// Измеритель задержек серверов с кэшем на 5 минут.
class PingService {
  /// Создаёт сервис измерения пинга.
  PingService({
    Duration cacheTtl = ServerConstants.pingCacheTtl,
    @visibleForTesting TcpPingProbe? tcpProbe,
    @visibleForTesting RealDelay204Probe? realDelayProbe,
    @visibleForTesting ClockProvider? clock,
  })  : _cacheTtl = cacheTtl,
        _tcpProbe = tcpProbe ?? _defaultTcpProbe,
        _realDelayProbe = realDelayProbe ?? _defaultRealDelay204Probe,
        _clock = clock ?? DateTime.now;

  final Duration _cacheTtl;
  final TcpPingProbe _tcpProbe;
  final RealDelay204Probe _realDelayProbe;
  final ClockProvider _clock;

  final Map<String, PingSample> _cache = <String, PingSample>{};

  /// Возвращает кэшированный замер, если он не старше TTL (5 минут).
  PingSample? getCached(SubscriptionNode node) {
    final key = _cacheKey(node);
    final entry = _cache[key];
    if (entry == null) return null;
    if (_clock().difference(entry.measuredAt) >= _cacheTtl) {
      return null;
    }
    return entry;
  }

  /// Очищает весь кэш замеров (например, при ручном «Обновить»).
  void clearCache() => _cache.clear();

  /// Измеряет задержку узла [node] (используя 5-минутный кэш при [forceRefresh] = false).
  ///
  /// Если активен VPN-туннель ([isTunnelActive] == true) и [useRealDelayWhenConnected],
  /// выполняет сквозной HTTP 204 зонд через общий пул; иначе измеряет TCP handshake
  /// до входного адреса и порта узла.
  Future<PingSample> measureNode(
    SubscriptionNode node, {
    bool forceRefresh = false,
    bool isTunnelActive = false,
    bool useRealDelayWhenConnected = false,
  }) async {
    if (!forceRefresh) {
      final cached = getCached(node);
      if (cached != null) return cached;
    }

    final host = node.primaryAddress;
    final protocol = node.bestProtocol;
    if (host == null ||
        host.isEmpty ||
        protocol == null ||
        protocol.port <= 0) {
      final unreachable = PingSample(
        nodeId: node.id,
        latencyMs: null,
        packetLossPercent: 100,
        payloadProbePassed: false,
        measuredAt: _clock(),
      );
      _cache[_cacheKey(node)] = unreachable;
      return unreachable;
    }

    Duration? elapsed;
    if (isTunnelActive && useRealDelayWhenConnected) {
      elapsed = await _realDelayProbe(
        Uri.parse(DiagnosticsConstants.realDelayProbeUrl),
        ServerConstants.realDelayTimeout,
      );
    } else {
      elapsed = await _tcpProbe(
        host,
        protocol.port,
        ServerConstants.tcpPingTimeout,
      );
    }

    final sample = PingSample(
      nodeId: node.id,
      latencyMs: elapsed?.inMilliseconds,
      jitterMs: elapsed == null ? 0 : (elapsed.inMilliseconds * 0.1),
      packetLossPercent: elapsed == null ? 100.0 : 0.0,
      payloadProbePassed: elapsed != null,
      measuredAt: _clock(),
    );
    _cache[_cacheKey(node)] = sample;
    return sample;
  }

  /// Параллельно измеряет список узлов [nodes] (до [ServerConstants.maxConcurrentProbes] потоков).
  Future<Map<String, PingSample>> measureAll(
    List<SubscriptionNode> nodes, {
    bool forceRefresh = false,
  }) async {
    final results = <String, PingSample>{};
    if (nodes.isEmpty) return results;

    var cursor = 0;
    final workersCount = nodes.length < ServerConstants.maxConcurrentProbes
        ? nodes.length
        : ServerConstants.maxConcurrentProbes;

    Future<void> worker() async {
      while (true) {
        final index = cursor++;
        if (index >= nodes.length) return;
        final node = nodes[index];
        final sample = await measureNode(node, forceRefresh: forceRefresh);
        results[node.id] = sample;
      }
    }

    await Future.wait([
      for (var i = 0; i < workersCount; i++) worker(),
    ]);
    return results;
  }

  /// Выполняет сквозной HTTP 204 зонд через общий [HttpConnectionPool].
  Future<Duration?> probeRealDelay204() => _realDelayProbe(
        Uri.parse(DiagnosticsConstants.realDelayProbeUrl),
        ServerConstants.realDelayTimeout,
      );

  static String _cacheKey(SubscriptionNode node) {
    final host = node.primaryAddress ?? '';
    final port = node.bestProtocol?.port ?? 0;
    return '${node.id}|$host|$port';
  }

  static Future<Duration?> _defaultTcpProbe(
    String host,
    int port,
    Duration timeout,
  ) async {
    final stopwatch = Stopwatch()..start();
    Socket? socket;
    try {
      socket = await Socket.connect(host, port, timeout: timeout);
      return stopwatch.elapsed;
    } catch (_) {
      return null;
    } finally {
      try {
        await socket?.close();
      } catch (_) {}
    }
  }

  static Future<Duration?> _defaultRealDelay204Probe(
    Uri url,
    Duration timeout,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      await HttpConnectionPool.instance.client.getUri<dynamic>(
        url,
        options: Options(
          receiveTimeout: timeout,
          sendTimeout: timeout,
          validateStatus: (status) => status == 204 || status == 200,
        ),
      );
      return stopwatch.elapsed;
    } on DioException {
      return null;
    }
  }
}
