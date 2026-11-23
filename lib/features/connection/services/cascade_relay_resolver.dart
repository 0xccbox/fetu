/// Резолвер каскадных релеев и резервных конфигураций для туннеля.
///
/// Выделен из [VpnConnectionService] для соблюдения принципа SRP (AGENTS.md #1).
library;

import '../../../core/platform/vpn_method_channel.dart';
import '../../split_tunnel/models/split_rule.dart';
import '../models/local_rule_set_ref.dart';
import '../models/server_node.dart';
import 'singbox_config_generator.dart';

/// План генерации конфигурации с выбранным выходным узлом и опциональным релеем.
class RelayConnectionPlan {
  /// Создаёт план подключения.
  const RelayConnectionPlan({
    required this.exitNode,
    required this.configJson,
    this.relayNode,
  });

  /// Выбранный выходной узел.
  final ServerNode exitNode;

  /// Входной каскадный узел (если используется).
  final ServerNode? relayNode;

  /// Сгенерированная конфигурация sing-box.
  final String configJson;
}

/// Управляет кандидатами входных каскадов и историей отказавших релеев.
class CascadeRelayResolver {
  List<ServerNode> _relayCandidates = const <ServerNode>[];
  ServerNode? _currentRelayNode;
  final Set<String> _failedSignatures = <String>{};

  /// Активный входной релей (если подключён каскад).
  ServerNode? get currentRelayNode => _currentRelayNode;

  /// Все кандидаты релеев текущей сессии.
  List<ServerNode> get relayCandidates => _relayCandidates;

  /// Инициализирует список кандидатов перед новым подключением.
  void reset(List<ServerNode> relayCandidates) {
    _relayCandidates = List.unmodifiable(relayCandidates);
    _failedSignatures.clear();
    _currentRelayNode =
        _relayCandidates.isNotEmpty ? _relayCandidates.first : null;
  }

  /// Очищает состояние после отключения.
  void clear() {
    _relayCandidates = const <ServerNode>[];
    _currentRelayNode = null;
    _failedSignatures.clear();
  }

  /// Фиксирует текущий активный релей.
  void setCurrent(ServerNode? relay) {
    _currentRelayNode = relay;
  }

  /// Помечает релей как отказавший.
  void markFailed(ServerNode relay) {
    _failedSignatures.add(signature(relay));
  }

  /// Есть ли живой резервный релей, отличный от текущего.
  bool get hasBackupRelay => nextBackupRelay() != null;

  /// Подбирает первую валидную конфигурацию из кандидатов протоколов и релеев.
  ///
  /// Throws: [ConfigGenerationException] если ни одна пара не валидна.
  RelayConnectionPlan buildInitialPlan({
    required List<ServerNode> exitCandidates,
    required List<SplitRule> splitRules,
    required List<LocalRuleSetRef> ruleSets,
  }) {
    final relaysToTry = _relayCandidates.isEmpty
        ? const <ServerNode?>[null]
        : <ServerNode?>[..._relayCandidates];
    ConfigGenerationException? lastError;

    for (final relay in relaysToTry) {
      for (final exitNode in exitCandidates) {
        try {
          final configJson = SingBoxConfigGenerator.generate(
            exitNode,
            splitRules: splitRules,
            ruleSets: ruleSets,
            relayNode: relay,
          );
          return RelayConnectionPlan(
            exitNode: exitNode,
            relayNode: relay,
            configJson: configJson,
          );
        } on ConfigGenerationException catch (e) {
          lastError = e;
        }
      }
    }
    throw lastError ??
        const ConfigGenerationException('Нет валидных кандидатов подключения');
  }

  /// Возвращает следующий резервный релей, способный сгенерировать конфиг.
  ServerNode? nextBackupRelay() {
    final current = _currentRelayNode;
    if (current == null || _relayCandidates.isEmpty) return null;
    final currentSig = signature(current);
    for (final candidate in _relayCandidates) {
      final sig = signature(candidate);
      if (sig == currentSig || _failedSignatures.contains(sig)) continue;
      if (!SingBoxConfigGenerator.canGenerate(candidate)) continue;
      return candidate;
    }
    return null;
  }

  /// Строит конфигурацию для следующего резервного релея (если доступен).
  RelayConnectionPlan? buildBackupPlan({
    required ServerNode exitNode,
    required List<SplitRule> splitRules,
    required List<LocalRuleSetRef> ruleSets,
  }) {
    while (true) {
      final relay = nextBackupRelay();
      if (relay == null) return null;
      try {
        final configJson = SingBoxConfigGenerator.generate(
          exitNode,
          splitRules: splitRules,
          ruleSets: ruleSets,
          relayNode: relay,
        );
        return RelayConnectionPlan(
          exitNode: exitNode,
          relayNode: relay,
          configJson: configJson,
        );
      } on ConfigGenerationException {
        markFailed(relay);
      }
    }
  }

  /// Уникальная сигнатура релея (id + адрес + протокол).
  static String signature(ServerNode relay) =>
      '${relay.id}:${relay.address}:${relay.protocol.name}';

  /// Выполняет первичное подключение по [plan], переключаясь на резервные релеи при сбое.
  Future<ServerNode> connectWithRelayFallback({
    required VpnMethodChannel channel,
    required RelayConnectionPlan plan,
    required List<SplitRule> splitRules,
    required List<LocalRuleSetRef> ruleSets,
  }) async {
    setCurrent(plan.relayNode);
    try {
      await channel.connect(plan.configJson);
      return plan.exitNode;
    } on VpnChannelException {
      final failedRelay = plan.relayNode;
      if (failedRelay == null || _relayCandidates.length < 2) rethrow;
      markFailed(failedRelay);
      while (true) {
        final next = buildBackupPlan(
          exitNode: plan.exitNode,
          splitRules: splitRules,
          ruleSets: ruleSets,
        );
        if (next == null) rethrow;
        try {
          await channel.connect(next.configJson);
          setCurrent(next.relayNode);
          return next.exitNode;
        } on VpnChannelException {
          if (next.relayNode != null) markFailed(next.relayNode!);
        }
      }
    }
  }

  /// Переключает активный туннель на следующий резервный релей через `reloadConfig`.
  Future<bool> switchToBackupRelay({
    required VpnMethodChannel? channel,
    required bool isMock,
    required ServerNode exitNode,
    required List<SplitRule> splitRules,
    required List<LocalRuleSetRef> ruleSets,
  }) async {
    final currentRelay = _currentRelayNode;
    if (currentRelay == null) return false;

    markFailed(currentRelay);
    if (isMock) {
      final nextRelay = nextBackupRelay();
      if (nextRelay == null) return false;
      setCurrent(nextRelay);
      return true;
    }
    if (channel == null) return false;

    while (true) {
      final plan = buildBackupPlan(
        exitNode: exitNode,
        splitRules: splitRules,
        ruleSets: ruleSets,
      );
      if (plan == null) return false;
      try {
        await channel.reloadConfig(plan.configJson);
        setCurrent(plan.relayNode);
        return true;
      } on VpnChannelException {
        if (plan.relayNode != null) markFailed(plan.relayNode!);
      }
    }
  }
}
