/// Умный скоринг узлов (SmartNodeScorer): многофакторный отбор лучшей связки
/// `(Cascade Relay -> Exit Node -> Protocol)` и интеграция с API провайдера.
///
/// См. `docs/reference/УМНЫЙ_ВЫБОР_СЕРВЕРА.md`.
library;

import 'package:dio/dio.dart';
import 'package:meta/meta.dart';

import '../../../core/constants/server_constants.dart';
import '../../../core/network/http_connection_pool.dart';
import '../../subscription/models/subscription_cascade.dart';
import '../../subscription/models/subscription_node.dart';
import '../models/node_health_score.dart';
import '../models/server_info.dart';
import 'network_profile_memory.dart';
import 'ping_service.dart';

/// Инъектируемый запрос к API умного выбора провайдера (для тестов).
typedef SmartSelectApiFetcher = Future<String?> Function(String url);

/// Результат умного выбора сервера.
@immutable
class SmartSelectionResult {
  /// Создаёт результат умного выбора.
  const SmartSelectionResult({
    required this.server,
    required this.fromProviderApi,
    this.scoredServers = const <ServerInfo>[],
    this.reason,
  });

  /// Выбранный сервер с оценкой качества.
  final ServerInfo server;

  /// Полный список оценённых серверов для кэширования пингов в UI.
  final List<ServerInfo> scoredServers;

  /// Был ли сервер выбран API провайдера (`true`) или локально (`false`).
  final bool fromProviderApi;

  /// Причина выбора (`lowest_load`, `lowest_ping`, `smart_score`...).
  final String? reason;
}

/// Движок многофакторного скоринга узлов.
class SmartNodeScorer {
  /// Создаёт скорер.
  SmartNodeScorer({
    required PingService pingService,
    NetworkProfileMemory? networkMemory,
    @visibleForTesting SmartSelectApiFetcher? apiFetcher,
  })  : _pingService = pingService,
        _networkMemory = networkMemory ?? NetworkProfileMemory(),
        _apiFetcher = apiFetcher ?? _defaultApiFetcher;

  final PingService _pingService;
  final NetworkProfileMemory _networkMemory;
  final SmartSelectApiFetcher _apiFetcher;

  /// Рассчитывает [ServerInfo] и [NodeHealthScore] для каждого узла подписки.
  Future<List<ServerInfo>> scoreNodes(
    List<SubscriptionNode> nodes, {
    SubscriptionCascade? cascade,
    bool forceRefresh = false,
  }) async {
    if (nodes.isEmpty) return const <ServerInfo>[];

    final samples = await _pingService.measureAll(
      nodes,
      forceRefresh: forceRefresh,
    );
    final preferred = await _networkMemory.getPreferred();

    final scored = <ServerInfo>[];
    for (final node in nodes) {
      final sample = samples[node.id];
      final latency = sample?.latencyMs;
      final bestProto = node.bestProtocol?.protocolType;

      String? relayId;
      if (cascade != null && cascade.enabled) {
        final relays = cascade.resolveRelaysForExitNode(node.id);
        if (relays.isNotEmpty) {
          relayId = relays.first.id;
        }
      }

      final bonus = _memoryBonus(
        preferred: preferred,
        node: node,
        relayId: relayId,
      );

      final health = latency == null
          ? NodeHealthScore(
              score: 0,
              realDelayMs: -1,
              jitterMs: 0,
              packetLossPercent: 100,
              serverLoadPercent: 0,
              payloadProbePassed: false,
              networkMemoryBonus: 0,
              recommendedProtocol: bestProto,
              recommendedRelayId: relayId,
            )
          : NodeHealthScore.calculate(
              realDelayMs: latency,
              jitterMs: sample?.jitterMs ?? 0,
              packetLossPercent: sample?.packetLossPercent ?? 0,
              payloadProbePassed: sample?.payloadProbePassed ?? true,
              networkMemoryBonus: bonus,
              recommendedProtocol: bestProto,
              recommendedRelayId: relayId,
            );

      scored.add(
        ServerInfo(
          node: node,
          latencyMs: latency,
          jitterMs: sample?.jitterMs ?? 0,
          packetLossPercent: sample?.packetLossPercent ?? 0,
          reachable: sample?.isReachable ?? false,
          healthScore: health,
          measuredAt: sample?.measuredAt,
        ),
      );
    }

    return List.unmodifiable(scored);
  }

  /// Выбирает лучший узел: сначала пробует API провайдера ([smartSelectionUrl]),
  /// при отсутствии/сбое — локальный расчёт [NodeHealthScore].
  Future<SmartSelectionResult?> selectBestNode(
    List<SubscriptionNode> nodes, {
    String? smartSelectionUrl,
    SubscriptionCascade? cascade,
    bool forceRefresh = false,
  }) async {
    if (nodes.isEmpty) return null;

    final scored = await scoreNodes(
      nodes,
      cascade: cascade,
      forceRefresh: forceRefresh,
    );

    if (smartSelectionUrl != null && smartSelectionUrl.trim().isNotEmpty) {
      try {
        final apiServerId = await _apiFetcher(smartSelectionUrl.trim());
        if (apiServerId != null && apiServerId.isNotEmpty) {
          for (final info in scored) {
            if (info.id == apiServerId &&
                !(info.healthScore?.isBlocked ?? false)) {
              return SmartSelectionResult(
                server: info,
                fromProviderApi: true,
                scoredServers: scored,
                reason: 'provider_api',
              );
            }
          }
        }
      } catch (_) {
        // Fallback на локальный SmartNodeScorer.
      }
    }

    final ranked = [...scored]..sort(_compareServers);
    return SmartSelectionResult(
      server: ranked.first,
      fromProviderApi: false,
      scoredServers: scored,
      reason: 'smart_score',
    );
  }

  static int _compareServers(ServerInfo a, ServerInfo b) {
    final scoreA = a.healthScore?.score ?? 0;
    final scoreB = b.healthScore?.score ?? 0;
    final scoreCmp = scoreB.compareTo(scoreA);
    if (scoreCmp != 0) return scoreCmp;

    final latA = a.latencyMs ?? 1 << 30;
    final latB = b.latencyMs ?? 1 << 30;
    return latA.compareTo(latB);
  }

  static double _memoryBonus({
    required NetworkProfilePreference? preferred,
    required SubscriptionNode node,
    required String? relayId,
  }) {
    if (preferred == null) return 0;
    final supportsPreferredProtocol =
        node.protocols.any((p) => p.protocolType == preferred.protocol);
    if (!supportsPreferredProtocol) return 0;
    if (preferred.relayId != null &&
        relayId != null &&
        preferred.relayId != relayId) {
      return ServerConstants.networkMemoryBonus * 0.5;
    }
    return ServerConstants.networkMemoryBonus;
  }

  static Future<String?> _defaultApiFetcher(String url) async {
    final response = await HttpConnectionPool.instance.client.get<dynamic>(
      url,
      options: Options(
        receiveTimeout: ServerConstants.smartSelectApiTimeout,
        sendTimeout: ServerConstants.smartSelectApiTimeout,
      ),
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data['server_id'] as String?;
    }
    return null;
  }
}
