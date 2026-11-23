import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/platform/vpn_method_channel.dart';
import '../../split_tunnel/models/split_rule.dart';
import '../models/connection_metrics.dart';
import '../models/connection_state.dart';
import '../models/local_rule_set_ref.dart';
import '../models/server_node.dart';
import 'cascade_relay_resolver.dart';
import 'mock_traffic_tracker.dart';
import 'singbox_config_generator.dart';

/// Провайдер текущих правил раздельного туннелирования.
///
/// Внедряется через DI, чтобы сервис всегда брал актуальные
/// правила на момент подключения/перезагрузки.
typedef SplitRulesProvider = List<SplitRule> Function();

/// Провайдер текущих кэшированных `.srs`-наборов правил.
typedef RuleSetsProvider = List<LocalRuleSetRef> Function();

/// Режим работы VPN-сервиса.
enum VpnServiceMode {
  /// Реальное подключение через Platform Channel и sing-box.
  real,

  /// Мок-режим для разработки без нативного кода.
  mock,
}

/// Сервис управления VPN-подключением.
///
/// Поддерживает два режима работы:
/// - `real`: реальное подключение через Platform Channel
/// - `mock`: мок-режим для разработки UI
///
/// Все операции изменения состояния туннеля (connect/disconnect/reload)
/// сериализуются через внутреннюю очередь (AGENTS.md, правило 8).
class VpnConnectionService {
  final VpnServiceMode mode;
  final VpnMethodChannel? _channel;
  final SplitRulesProvider? _splitRulesProvider;
  final RuleSetsProvider? _ruleSetsProvider;

  ConnectionState _currentState = ConnectionState.disconnected;
  ConnectionMetrics _currentMetrics = const ConnectionMetrics.empty();
  ServerNode? _currentNode;
  List<ServerNode> _protocolCandidates = const <ServerNode>[];
  final CascadeRelayResolver _relayResolver = CascadeRelayResolver();
  List<SplitRule> _currentSplitRules = const <SplitRule>[];
  List<LocalRuleSetRef> _currentRuleSets = const <LocalRuleSetRef>[];

  final _stateController = StreamController<ConnectionState>.broadcast();
  final _coreErrorController = StreamController<String>.broadcast();

  /// Хвост очереди операций туннеля (мьютекс сериализации).
  Future<void>? _lastOperation;

  /// Изменились ли правила, пока туннель устанавливался.
  bool _pendingRulesReload = false;

  DateTime? _connectionStartTime;
  StreamSubscription<NativeVpnStatus>? _statusSubscription;
  StreamSubscription<NativeVpnMetrics>? _metricsSubscription;
  StreamSubscription<String>? _errorSubscription;

  final MockTrafficTracker _mockTracker = MockTrafficTracker();

  /// Создает сервис.
  ///
  /// [mode] — режим работы (real/mock); [splitRulesProvider] —
  /// провайдер правил Split Tunneling для генерации конфигурации;
  /// [channel] — переопределение канала (только для тестов).
  VpnConnectionService({
    this.mode = VpnServiceMode.real,
    SplitRulesProvider? splitRulesProvider,
    RuleSetsProvider? ruleSetsProvider,
    @visibleForTesting VpnMethodChannel? channel,
  })  : _channel = channel ??
            (mode == VpnServiceMode.real ? VpnMethodChannel.instance : null),
        _splitRulesProvider = splitRulesProvider,
        _ruleSetsProvider = ruleSetsProvider {
    if (_channel != null) {
      _subscribeToNativeEvents();
      // Нативный сервис мог пережить рестарт процесса приложения —
      // синхронизируем стартовое состояние.
      unawaited(_syncInitialState());
    }
  }

  /// Поток изменений состояния подключения.
  Stream<ConnectionState> get stateStream => _stateController.stream;

  /// Поток ошибок ядра (для детекции DPI/сбоев в failover).
  Stream<String> get coreErrorStream => _coreErrorController.stream;

  /// Получить текущее состояние подключения.
  ConnectionState get currentState => _currentState;

  /// Получить текущие метрики.
  ConnectionMetrics get currentMetrics => _currentMetrics;

  /// Получить текущий узел подключения.
  ServerNode? get currentNode => _currentNode;

  /// Текущий входной каскадный узел (если используется мульти-каскад).
  ServerNode? get currentRelayNode => _relayResolver.currentRelayNode;

  /// Список доступных и поддерживаемых ядром протоколов для текущего узла.
  List<ProtocolType> get availableProtocols => [
        for (final node in _protocolCandidates)
          if (SingBoxConfigGenerator.canGenerate(node)) node.protocol,
      ];

  /// Порт первого доступного TCP-канала текущего узла (для canary-проверки).
  int? get canaryTcpPort {
    for (final node in _protocolCandidates) {
      if (!node.protocol.isTcp) continue;
      if (!SingBoxConfigGenerator.canGenerate(node)) continue;
      final port = node.config['port'] ?? node.config['server_port'];
      if (port is int && port > 0) return port;
    }
    return null;
  }

  /// Подписаться на события из нативного слоя.
  void _subscribeToNativeEvents() {
    final channel = _channel;
    if (channel == null) return;

    _statusSubscription = channel.statusStream.listen((status) {
      final nextState = _mapNativeStatus(status);
      _setState(nextState);

      if (nextState == ConnectionState.connected) {
        _connectionStartTime = DateTime.now();
        _flushPendingRulesReload();
      } else if (nextState == ConnectionState.disconnected) {
        _connectionStartTime = null;
        _currentMetrics = const ConnectionMetrics.empty();
        _relayResolver.clear();
        _pendingRulesReload = false;
      }
    });

    _metricsSubscription = channel.metricsStream.listen((nativeMetrics) {
      final duration = _connectionStartTime != null
          ? DateTime.now().difference(_connectionStartTime!).inSeconds
          : 0;

      _currentMetrics = ConnectionMetrics(
        downloadSpeed: nativeMetrics.downloadSpeed,
        uploadSpeed: nativeMetrics.uploadSpeed,
        totalDownloaded: nativeMetrics.downloadBytes,
        totalUploaded: nativeMetrics.uploadBytes,
        connectionDuration: duration,
        latency: nativeMetrics.ping,
      );
    });

    _errorSubscription = channel.errorStream.listen((error) {
      if (kDebugMode) {
        debugPrint('[VpnConnectionService] Native error received');
      }
      _coreErrorController.add(error);
      _setState(ConnectionState.error);
    });
  }

  void _setState(ConnectionState next) {
    if (_currentState == next) return;
    _currentState = next;
    if (!_stateController.isClosed) {
      _stateController.add(next);
    }
  }

  /// Преобразует нативный статус в состояние приложения.
  static ConnectionState _mapNativeStatus(NativeVpnStatus status) =>
      switch (status) {
        NativeVpnStatus.disconnected => ConnectionState.disconnected,
        NativeVpnStatus.connecting => ConnectionState.connecting,
        NativeVpnStatus.connected => ConnectionState.connected,
        NativeVpnStatus.disconnecting => ConnectionState.disconnecting,
        NativeVpnStatus.error => ConnectionState.error,
      };

  /// Синхронизирует состояние с нативным слоем при старте.
  ///
  /// Отказ канала не фатален (песочница/тест без нативного кода).
  Future<void> _syncInitialState() async {
    final channel = _channel;
    if (channel == null) return;
    try {
      _setState(_mapNativeStatus(await channel.getStatus()));
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[VpnConnectionService] Initial state sync skipped: ${e.runtimeType}',
        );
      }
    }
  }

  /// Сериализует операции над туннелем (AGENTS.md, правило 8).
  ///
  /// Каждая операция выполняется только после завершения предыдущей;
  /// ошибка одной операции не блокирует очередь.
  Future<void> _serialized(Future<void> Function() action) async {
    final previous = _lastOperation;
    final operation = Completer<void>();
    _lastOperation = operation.future;

    // Хвост очереди завершается в finally и никогда не падает,
    // но защищаемся от будущих изменений контракта очереди.
    await previous?.catchError((Object _) {});
    try {
      await action();
    } finally {
      operation.complete();
    }
  }

  /// Применяет отложенные правила сразу после установления туннеля.
  void _flushPendingRulesReload() {
    if (!_pendingRulesReload) return;
    _pendingRulesReload = false;
    unawaited(
      applySplitRules().then(
        (_) {},
        onError: (Object e) {
          if (kDebugMode) {
            debugPrint(
              '[VpnConnectionService] Pending rules reload failed: ${e.runtimeType}',
            );
          }
        },
      ),
    );
  }

  /// Проверить доступность VPN на устройстве.
  Future<bool> isVpnAvailable() async {
    if (mode == VpnServiceMode.mock) return true;
    return await _channel!.isVpnAvailable();
  }

  /// Запросить разрешение VPN у пользователя.
  Future<bool> requestVpnPermission() async {
    if (mode == VpnServiceMode.mock) return true;
    return await _channel!.requestVpnPermission();
  }

  /// Подключиться к VPN с указанным узлом, fallback-протоколами и каскадами.
  Future<void> connect(
    ServerNode node, {
    List<ServerNode> fallbackNodes = const <ServerNode>[],
    List<ServerNode> relayCandidates = const <ServerNode>[],
  }) =>
      _serialized(
        () => _connectGuarded(
          node,
          fallbackNodes: fallbackNodes,
          relayCandidates: relayCandidates,
        ),
      );

  Future<void> _connectGuarded(
    ServerNode node, {
    required List<ServerNode> fallbackNodes,
    required List<ServerNode> relayCandidates,
  }) async {
    if (_currentState.isTransitioning || _currentState.isActive) {
      throw StateError('Подключение уже активно или в процессе');
    }

    _protocolCandidates = fallbackNodes.isNotEmpty
        ? List.unmodifiable(fallbackNodes)
        : <ServerNode>[node];
    _relayResolver.reset(relayCandidates);
    _currentNode = node;
    _currentSplitRules = _splitRulesProvider?.call() ?? const <SplitRule>[];
    _currentRuleSets = _ruleSetsProvider?.call() ?? const <LocalRuleSetRef>[];
    _setState(ConnectionState.connecting);
    _currentMetrics = const ConnectionMetrics.empty();

    if (mode == VpnServiceMode.mock) {
      await _connectMock();
    } else {
      await _connectReal(node);
    }
  }

  /// Реальное подключение через Platform Channel (с пропуском неподдерживаемых конфигов).
  Future<void> _connectReal(ServerNode node) async {
    try {
      final candidates = [
        node,
        for (final c in _protocolCandidates)
          if (c.protocol != node.protocol) c,
      ];
      final plan = _relayResolver.buildInitialPlan(
        exitCandidates: candidates,
        splitRules: _currentSplitRules,
        ruleSets: _currentRuleSets,
      );
      _currentNode = await _relayResolver.connectWithRelayFallback(
        channel: _channel!,
        plan: plan,
        splitRules: _currentSplitRules,
        ruleSets: _currentRuleSets,
      );
    } catch (e) {
      _setState(ConnectionState.error);
      _currentMetrics = const ConnectionMetrics.empty();
      _currentNode = null;
      _relayResolver.clear();
      rethrow;
    }
  }

  /// Мок-подключение для разработки UI.
  Future<void> _connectMock() async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      _setState(ConnectionState.connected);
      _connectionStartTime = DateTime.now();
      _mockTracker.start((metrics) {
        if (_currentState == ConnectionState.connected) {
          _currentMetrics = metrics;
        }
      });
      _flushPendingRulesReload();
    } catch (e) {
      _setState(ConnectionState.error);
      _currentMetrics = const ConnectionMetrics.empty();
      _currentNode = null;
      rethrow;
    }
  }

  /// Отключиться от VPN.
  Future<void> disconnect() => _serialized(_disconnectGuarded);

  Future<void> _disconnectGuarded() async {
    if (_currentState == ConnectionState.disconnected) return;
    _setState(ConnectionState.disconnecting);
    if (mode == VpnServiceMode.mock) {
      await _disconnectMock();
    } else {
      await _disconnectReal();
    }
  }

  /// Реальное отключение через Platform Channel.
  Future<void> _disconnectReal() async {
    try {
      await _channel!.disconnect();
    } catch (e) {
      _setState(ConnectionState.error);
      rethrow;
    }
  }

  /// Мок-отключение.
  Future<void> _disconnectMock() async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      _setState(ConnectionState.disconnected);
      _currentMetrics = const ConnectionMetrics.empty();
      _currentNode = null;
      _protocolCandidates = const <ServerNode>[];
      _relayResolver.clear();
      _connectionStartTime = null;
      _mockTracker.stop();
    } catch (e) {
      _setState(ConnectionState.error);
      rethrow;
    }
  }

  /// Есть ли доступный резервный входной каскадный узел.
  bool get hasBackupRelay => _relayResolver.hasBackupRelay;

  /// Переключает активный туннель на резервный каскадный узел без разрыва сессии.
  Future<bool> switchToBackupRelay() {
    final completer = Completer<bool>();
    _serialized(() async {
      try {
        completer.complete(await _switchToBackupRelayGuarded());
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  Future<bool> _switchToBackupRelayGuarded() async {
    if (!_canReloadTunnel || _currentNode == null) return false;
    _syncRulesAndRuleSets();
    final switched = await _relayResolver.switchToBackupRelay(
      channel: _channel,
      isMock: mode == VpnServiceMode.mock,
      exitNode: _currentNode!,
      splitRules: _currentSplitRules,
      ruleSets: _currentRuleSets,
    );
    if (switched && _currentState == ConnectionState.error) {
      _setState(ConnectionState.connected);
    }
    return switched;
  }

  /// Переключает активный туннель на протокол [protocol] через Zero-Drop Live Reload.
  Future<void> switchProtocol(ProtocolType protocol) =>
      _serialized(() => _switchProtocolGuarded(protocol));

  Future<void> _switchProtocolGuarded(ProtocolType protocol) async {
    if (!_canReloadTunnel) return;
    final current = _currentNode;
    if (current == null) return;

    final target = _protocolCandidates.firstWhere(
      (c) => c.protocol == protocol,
      orElse: () => current.copyWith(protocol: protocol),
    );

    if (mode != VpnServiceMode.mock) {
      final channel = _channel;
      if (channel == null) return;
      _syncRulesAndRuleSets();
      final configJson = SingBoxConfigGenerator.generate(
        target,
        splitRules: _currentSplitRules,
        ruleSets: _currentRuleSets,
        relayNode: _relayResolver.currentRelayNode,
      );
      await channel.reloadConfig(configJson);
    }
    _currentNode = target;
    if (_currentState == ConnectionState.error) {
      _setState(ConnectionState.connected);
    }
  }

  bool get _canReloadTunnel =>
      _currentState == ConnectionState.connected ||
      _currentState == ConnectionState.error;

  void _syncRulesAndRuleSets() {
    _currentSplitRules = _splitRulesProvider?.call() ?? const <SplitRule>[];
    _currentRuleSets = _ruleSetsProvider?.call() ?? const <LocalRuleSetRef>[];
  }

  /// Применяет новые правила раздельного туннелирования без разрыва (Zero-Drop).
  Future<void> applySplitRules() => _serialized(_applySplitRulesGuarded);

  Future<void> _applySplitRulesGuarded() async {
    if (_currentState != ConnectionState.connected) {
      if (_currentState.isTransitioning) _pendingRulesReload = true;
      return;
    }
    if (mode == VpnServiceMode.mock) return;
    final node = _currentNode;
    final channel = _channel;
    if (node == null || channel == null) return;

    _syncRulesAndRuleSets();
    final configJson = SingBoxConfigGenerator.generate(
      node,
      splitRules: _currentSplitRules,
      ruleSets: _currentRuleSets,
      relayNode: _relayResolver.currentRelayNode,
    );
    await channel.reloadConfig(configJson);
  }

  /// Освободить ресурсы.
  void dispose() {
    _statusSubscription?.cancel();
    _metricsSubscription?.cancel();
    _errorSubscription?.cancel();
    _stateController.close();
    _coreErrorController.close();
    _mockTracker.stop();
  }
}
