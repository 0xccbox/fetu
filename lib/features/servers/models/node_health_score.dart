/// Многофакторный рейтинг узла для `SmartNodeScorer` (0..100 баллов).
///
/// См. `docs/reference/УМНЫЙ_ВЫБОР_СЕРВЕРА.md`.
library;

import 'package:meta/meta.dart';

import '../../../core/constants/server_constants.dart';
import '../../connection/models/server_node.dart';

/// Иммутабельная оценка качества маршрута `(Relay -> Exit -> Protocol)`.
@immutable
class NodeHealthScore {
  /// Создаёт результат оценки узла.
  const NodeHealthScore({
    required this.score,
    required this.realDelayMs,
    required this.jitterMs,
    required this.packetLossPercent,
    required this.serverLoadPercent,
    required this.payloadProbePassed,
    required this.networkMemoryBonus,
    this.recommendedProtocol,
    this.recommendedRelayId,
  });

  /// Итоговый рейтинг (0..100).
  final double score;

  /// Сквозная задержка (мс).
  final int realDelayMs;

  /// Джиттер (мс).
  final double jitterMs;

  /// Потеря пакетов (%).
  final double packetLossPercent;

  /// Нагрузка сервера (%).
  final double serverLoadPercent;

  /// Пройден ли тест передачи >24 КБ (отсутствие 16KB-блокировки ТСПУ).
  final bool payloadProbePassed;

  /// Бонус памяти текущего сетевого профиля.
  final double networkMemoryBonus;

  /// Рекомендованный протокол для этой связки.
  final ProtocolType? recommendedProtocol;

  /// Рекомендованный входной каскадный релей (если использовался каскад).
  final String? recommendedRelayId;

  /// Считается ли маршрут заблокированным в текущей сети.
  bool get isBlocked =>
      !payloadProbePassed ||
      packetLossPercent > ServerConstants.maxPacketLossPercent ||
      score <= 0;

  /// Рассчитывает [NodeHealthScore] по спецификации `SmartNodeScorer`.
  factory NodeHealthScore.calculate({
    required int realDelayMs,
    double jitterMs = 0,
    double packetLossPercent = 0,
    double serverLoadPercent = 0,
    bool payloadProbePassed = true,
    double networkMemoryBonus = 0,
    ProtocolType? recommendedProtocol,
    String? recommendedRelayId,
  }) {
    if (!payloadProbePassed ||
        packetLossPercent > ServerConstants.maxPacketLossPercent ||
        realDelayMs < 0) {
      return NodeHealthScore(
        score: 0,
        realDelayMs: realDelayMs,
        jitterMs: jitterMs,
        packetLossPercent: packetLossPercent,
        serverLoadPercent: serverLoadPercent,
        payloadProbePassed: payloadProbePassed,
        networkMemoryBonus: networkMemoryBonus,
        recommendedProtocol: recommendedProtocol,
        recommendedRelayId: recommendedRelayId,
      );
    }

    final penalty = (realDelayMs * 0.35) +
        (jitterMs * 1.2) +
        (packetLossPercent * 18.0) +
        (serverLoadPercent * 0.4) -
        networkMemoryBonus;

    final clamped = (100.0 - (penalty / 4.0)).clamp(0.0, 100.0);

    return NodeHealthScore(
      score: clamped,
      realDelayMs: realDelayMs,
      jitterMs: jitterMs,
      packetLossPercent: packetLossPercent,
      serverLoadPercent: serverLoadPercent,
      payloadProbePassed: payloadProbePassed,
      networkMemoryBonus: networkMemoryBonus,
      recommendedProtocol: recommendedProtocol,
      recommendedRelayId: recommendedRelayId,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NodeHealthScore &&
      other.score == score &&
      other.realDelayMs == realDelayMs &&
      other.recommendedProtocol == recommendedProtocol &&
      other.recommendedRelayId == recommendedRelayId;

  @override
  int get hashCode =>
      Object.hash(score, realDelayMs, recommendedProtocol, recommendedRelayId);

  @override
  String toString() =>
      'NodeHealthScore(score=${score.toStringAsFixed(1)}, delay=${realDelayMs}ms)';
}
