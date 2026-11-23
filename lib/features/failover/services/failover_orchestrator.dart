import 'dart:async';

import 'package:fetu/features/connection/models/server_node.dart';
import 'package:fetu/features/failover/models/failover_event.dart';
import 'package:fetu/features/failover/models/failover_strategy.dart';
import 'package:fetu/features/failover/models/protocol_health.dart';
import 'package:fetu/features/failover/services/protocol_health_monitor.dart';
import 'package:flutter/foundation.dart';

/// Колбэк переключения протокола на активном туннеле (DI из композиционного корня).
typedef ProtocolSwitchHandler = Future<void> Function(ProtocolType target);

/// Колбэк переключения входного каскада на резервный (DI из композиционного корня).
typedef RelayBackupSwitchHandler = Future<bool> Function();

/// Оркестратор автоматического failover между протоколами и каскадами.
class FailoverOrchestrator with ChangeNotifier {
  /// Создаёт оркестратор.
  FailoverOrchestrator({
    ProtocolHealthMonitor? healthMonitor,
    FailoverStrategy? strategy,
    ProtocolSwitchHandler? onSwitchProtocol,
    RelayBackupSwitchHandler? onSwitchBackupRelay,
  })  : _healthMonitor = healthMonitor ?? ProtocolHealthMonitor(),
        _strategy = strategy ?? FailoverStrategy.defaultStrategy,
        _onSwitchProtocol = onSwitchProtocol,
        _onSwitchBackupRelay = onSwitchBackupRelay;

  final ProtocolHealthMonitor _healthMonitor;
  final FailoverStrategy _strategy;
  ProtocolSwitchHandler? _onSwitchProtocol;
  RelayBackupSwitchHandler? _onSwitchBackupRelay;

  StreamSubscription<ProtocolHealth>? _healthSubscription;
  ServerNode? _currentNode;
  ProtocolType? _currentProtocol;
  List<ProtocolType>? _availableProtocols;
  final Set<ProtocolType> _failedProtocols = <ProtocolType>{};
  bool _isFailoverInProgress = false;
  bool _canWrapAfterRelaySwitch = false;

  final _failoverEventsController = StreamController<FailoverEvent>.broadcast();

  /// Stream событий failover (для UI-уведомлений).
  Stream<FailoverEvent> get failoverEvents => _failoverEventsController.stream;

  /// Текущий узел подключения.
  ServerNode? get currentNode => _currentNode;

  /// Текущий протокол.
  ProtocolType? get currentProtocol => _currentProtocol;

  /// Стратегия failover.
  FailoverStrategy get strategy => _strategy;

  /// Идёт ли процесс failover.
  bool get isFailoverInProgress => _isFailoverInProgress;

  /// Задаёт обработчик переключения протокола (удобно при отложенной связке в DI).
  void bindSwitchHandler(ProtocolSwitchHandler handler) {
    _onSwitchProtocol = handler;
  }

  /// Задаёт обработчик переключения на резервный каскадный узел.
  void bindRelaySwitchHandler(RelayBackupSwitchHandler handler) {
    _onSwitchBackupRelay = handler;
  }

  /// Запускает мониторинг и автоматический failover.
  Future<void> start(
    ServerNode initialNode,
    ProtocolType protocol, {
    List<ProtocolType>? availableProtocols,
    int? canaryTcpPort,
  }) async {
    await stop();
    if (kDebugMode) {
      debugPrint(
        '[FailoverOrchestrator] Запуск мониторинга для ${protocol.displayName}',
      );
    }

    _currentNode = initialNode;
    _currentProtocol = protocol;
    _availableProtocols = availableProtocols;
    _failedProtocols.clear();
    _canWrapAfterRelaySwitch = false;

    _healthSubscription = _healthMonitor.healthStream.listen(_onHealthChanged);
    _healthMonitor.startMonitoring(initialNode, canaryTcpPort: canaryTcpPort);
  }

  /// Передаёт сообщение об ошибке от ядра VPN для детекции DPI/сбоев.
  void reportCoreError(String message) {
    _healthMonitor.reportLogError(message);
  }

  /// Останавливает мониторинг.
  Future<void> stop() async {
    if (_currentProtocol != null && kDebugMode) {
      debugPrint('[FailoverOrchestrator] Остановка мониторинга');
    }

    await _healthSubscription?.cancel();
    _healthSubscription = null;
    _healthMonitor.stopMonitoring();

    _currentNode = null;
    _currentProtocol = null;
    _availableProtocols = null;
    _failedProtocols.clear();
    _isFailoverInProgress = false;
    _canWrapAfterRelaySwitch = false;

    notifyListeners();
  }

  Future<void> _onHealthChanged(ProtocolHealth health) async {
    if (_currentProtocol == null || _currentNode == null) return;
    if (_isFailoverInProgress) return;

    if (kDebugMode) {
      debugPrint('[FailoverOrchestrator] Здоровье протокола: $health');
    }

    if (health.requiresFailover) {
      await _performFailover(
        reason: health == ProtocolHealth.blocked
            ? FailoverReason.blocked
            : FailoverReason.timeout,
        health: health,
      );
    } else if (health.requiresTcpFallback && _currentProtocol!.isUdp) {
      if (_strategy.enableCanaryCheck) {
        final canaryOk = await _healthMonitor.checkCanaryTcp(_currentNode!);
        if (canaryOk) {
          await _performFailover(
            reason: FailoverReason.packetLoss,
            health: health,
            forceTcp: true,
          );
        }
      }
    }
  }

  ProtocolType? _selectNextProtocol(
    ProtocolType fromProtocol, {
    required bool forceTcp,
  }) {
    final available = _availableProtocols;
    final ordered = (available == null || available.isEmpty)
        ? _strategy.protocolOrder
        : _strategy.protocolOrder.where(available.contains).toList();

    final startIndex = ordered.indexOf(fromProtocol);
    for (var i = startIndex + 1; i < ordered.length; i++) {
      final candidate = ordered[i];
      if (_failedProtocols.contains(candidate)) continue;
      if (forceTcp && _strategy.isUdpProtocol(candidate)) continue;
      return candidate;
    }
    if (_canWrapAfterRelaySwitch && startIndex > 0) {
      for (var i = 0; i < startIndex; i++) {
        final candidate = ordered[i];
        if (_failedProtocols.contains(candidate)) continue;
        if (forceTcp && _strategy.isUdpProtocol(candidate)) continue;
        return candidate;
      }
    }
    return null;
  }

  Future<void> _performFailover({
    required FailoverReason reason,
    required ProtocolHealth health,
    bool forceTcp = false,
  }) async {
    if (_isFailoverInProgress) return;
    _isFailoverInProgress = true;
    notifyListeners();

    try {
      final fromProtocol = _currentProtocol!;
      while (true) {
        final toProtocol =
            _selectNextProtocol(fromProtocol, forceTcp: forceTcp);

        if (toProtocol == null || toProtocol == fromProtocol) {
          final relayHandler = _onSwitchBackupRelay;
          if (relayHandler != null && await relayHandler()) {
            _failedProtocols.clear();
            _canWrapAfterRelaySwitch = true;
            _healthMonitor.reset();
            if (kDebugMode) {
              debugPrint(
                '[FailoverOrchestrator] Выполнен переход на резервный каскад',
              );
            }
            final event = FailoverEvent(
              timestamp: DateTime.now(),
              fromProtocol: fromProtocol,
              toProtocol: _currentProtocol ?? fromProtocol,
              reason: reason,
              health: health,
              serverNodeId: _currentNode?.id,
              errorDetails: 'cascade_relay_failover',
            );
            if (!_failoverEventsController.isClosed) {
              _failoverEventsController.add(event);
            }
            return;
          }
          if (kDebugMode) {
            debugPrint(
              '[FailoverOrchestrator] Нет доступных протоколов для failover',
            );
          }
          return;
        }

        if (kDebugMode) {
          debugPrint(
            '[FailoverOrchestrator] Failover: ${fromProtocol.displayName} → ${toProtocol.displayName}',
          );
        }

        try {
          if (_onSwitchProtocol != null) {
            await _onSwitchProtocol!(toProtocol);
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
              '[FailoverOrchestrator] Ошибка переключения: ${e.runtimeType}',
            );
          }
          _failedProtocols.add(toProtocol);
          continue;
        }

        _currentProtocol = toProtocol;
        _canWrapAfterRelaySwitch = false;
        _healthMonitor.reset();

        final event = FailoverEvent(
          timestamp: DateTime.now(),
          fromProtocol: fromProtocol,
          toProtocol: toProtocol,
          reason: reason,
          health: health,
          serverNodeId: _currentNode?.id,
        );
        if (!_failoverEventsController.isClosed) {
          _failoverEventsController.add(event);
        }
        return;
      }
    } finally {
      _isFailoverInProgress = false;
      notifyListeners();
    }
  }

  /// Принудительный переход на следующий протокол (по запросу пользователя).
  Future<void> forceFailover() async {
    if (_currentProtocol == null || _currentNode == null) return;

    await _performFailover(
      reason: FailoverReason.manual,
      health: ProtocolHealth.healthy,
    );
  }

  @override
  void dispose() {
    _healthSubscription?.cancel();
    _healthSubscription = null;
    _healthMonitor.dispose();
    _failoverEventsController.close();
    super.dispose();
  }
}
