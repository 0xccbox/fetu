/// Расширенная информация о сервере (узел + задержка + рейтинг).
library;

import 'package:meta/meta.dart';

import '../../subscription/models/subscription_node.dart';
import 'node_health_score.dart';

/// Иммутабельная карточка сервера для фичи `servers/`.
@immutable
class ServerInfo {
  /// Создаёт запись о сервере.
  const ServerInfo({
    required this.node,
    this.latencyMs,
    this.jitterMs = 0,
    this.packetLossPercent = 0,
    this.loadPercent = 0,
    this.reachable,
    this.healthScore,
    this.measuredAt,
  });

  /// Исходный узел из подписки.
  final SubscriptionNode node;

  /// Измеренная задержка (мс); `null` если ещё не измерялась или недоступен.
  final int? latencyMs;

  /// Оценка джиттера (мс).
  final double jitterMs;

  /// Оценка потери пакетов (%).
  final double packetLossPercent;

  /// Загрузка сервера провайдера (%).
  final double loadPercent;

  /// Доступен ли узел при последнем замере (`null` — ещё не проверялся).
  final bool? reachable;

  /// Многофакторный рейтинг узла (если рассчитан `SmartNodeScorer`).
  final NodeHealthScore? healthScore;

  /// Время последнего замера (для TTL-кэша 5 минут).
  final DateTime? measuredAt;

  /// Идентификатор узла.
  String get id => node.id;

  /// Отображаемое имя узла.
  String get name => node.name;

  /// Код страны.
  String? get country => node.country;

  /// Город.
  String? get city => node.city;

  /// Актуален ли замер в рамках [ttl].
  bool isFreshAt(DateTime now, Duration ttl) {
    final ts = measuredAt;
    if (ts == null) return false;
    return now.difference(ts) < ttl;
  }

  /// Возвращает копию с обновлёнными полями.
  ServerInfo copyWith({
    SubscriptionNode? node,
    int? latencyMs,
    bool clearLatency = false,
    double? jitterMs,
    double? packetLossPercent,
    double? loadPercent,
    bool? reachable,
    NodeHealthScore? healthScore,
    DateTime? measuredAt,
  }) {
    return ServerInfo(
      node: node ?? this.node,
      latencyMs: clearLatency ? null : (latencyMs ?? this.latencyMs),
      jitterMs: jitterMs ?? this.jitterMs,
      packetLossPercent: packetLossPercent ?? this.packetLossPercent,
      loadPercent: loadPercent ?? this.loadPercent,
      reachable: reachable ?? this.reachable,
      healthScore: healthScore ?? this.healthScore,
      measuredAt: measuredAt ?? this.measuredAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ServerInfo &&
      other.node == node &&
      other.latencyMs == latencyMs &&
      other.reachable == reachable &&
      other.healthScore == healthScore;

  @override
  int get hashCode => Object.hash(node, latencyMs, reachable, healthScore);

  @override
  String toString() =>
      'ServerInfo(${node.id}, latency=${latencyMs}ms, reachable=$reachable)';
}
