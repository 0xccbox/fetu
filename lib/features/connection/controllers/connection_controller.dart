import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/platform/vpn_method_channel.dart';
import '../models/connection_error.dart';
import '../models/connection_metrics.dart';
import '../models/connection_state.dart';
import '../models/server_node.dart';
import '../services/vpn_connection_service.dart';

/// Контроллер управления VPN-подключением для UI.
///
/// Оркестрирует работу VpnConnectionService и уведомляет UI об изменениях.
/// Подписывается на обновления метрик и пробрасывает их в виджеты.
class ConnectionController extends ChangeNotifier {
  final VpnConnectionService _service;

  Timer? _metricsPollingTimer;
  StreamSubscription<ConnectionState>? _stateSubscription;
  String? _errorMessage;
  ConnectionError? _errorCode;
  bool _starting = false;
  ({ServerNode node, Object? origin})? _lastConnectedSelection;

  /// Создаёт контроллер для сервиса подключения.
  ConnectionController(this._service) {
    _stateSubscription = _service.stateStream.listen((_) => notifyListeners());
    _startPollingMetrics();
  }

  /// Текущее состояние подключения
  ConnectionState get state => _service.currentState;

  /// Текущие метрики подключения
  ConnectionMetrics get metrics => _service.currentMetrics;

  /// Текущий узел подключения
  ServerNode? get currentNode => _service.currentNode;

  /// Текущий входной каскадный узел (если используется мульти-каскад).
  ServerNode? get currentRelayNode => _service.currentRelayNode;

  /// Строка подписки, из которой запущен текущий узел, если известна.
  Object? get currentNodeOrigin {
    final selection = _lastConnectedSelection;
    return selection != null && identical(currentNode, selection.node)
        ? selection.origin
        : null;
  }

  /// Сообщение об ошибке (debug-текст, не для UI)
  String? get errorMessage => _errorMessage;

  /// Код ошибки последней операции (для локализации в UI).
  ConnectionError? get errorCode => _errorCode;

  /// Подключиться к явно указанному серверу; [origin] — источник для UI.
  Future<void> connect(
    ServerNode node, {
    Object? origin,
    List<ServerNode> fallbackNodes = const <ServerNode>[],
    List<ServerNode> relayCandidates = const <ServerNode>[],
  }) async {
    _errorMessage = null;
    _errorCode = null;
    notifyListeners();

    try {
      await _service.connect(
        node,
        fallbackNodes: fallbackNodes,
        relayCandidates: relayCandidates,
      );
      _lastConnectedSelection = (
        node: _service.currentNode ?? node,
        origin: origin,
      );
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Не удалось подключиться';
      _errorCode = e is VpnChannelException && e.code == 'VPN_CORE_UNAVAILABLE'
          ? ConnectionError.coreUnavailable
          : ConnectionError.connectFailed;
      // Правило 16: в логи не попадают адреса/URL — только тип ошибки.
      if (kDebugMode) {
        debugPrint('[ConnectionController] connect failed: ${e.runtimeType}');
      }
      notifyListeners();
      rethrow;
    }
  }

  /// Отключиться от VPN
  Future<void> disconnect() async {
    _errorMessage = null;
    _errorCode = null;
    notifyListeners();

    try {
      await _service.disconnect();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Не удалось отключиться: $e';
      _errorCode = ConnectionError.disconnectFailed;
      // Правило 16: только тип ошибки, без адресов.
      if (kDebugMode) {
        debugPrint(
          '[ConnectionController] disconnect failed: ${e.runtimeType}',
        );
      }
      notifyListeners();
      rethrow;
    }
  }

  /// Переключает VPN из UI, передавая [origin] при новом подключении.
  Future<void> toggle({
    ServerNode Function()? resolveNode,
    List<ServerNode> Function()? resolveCandidates,
    List<ServerNode> Function()? resolveRelays,
    Object? origin,
  }) async {
    if (state.isTransitioning) return;
    if (state.isActive) {
      try {
        await disconnect();
      } catch (_) {
        // disconnect уже выставил локализуемый код ошибки.
      }
    } else if (resolveNode != null) {
      await connectFromSelection(
        resolveNode,
        resolveCandidates: resolveCandidates,
        resolveRelays: resolveRelays,
        origin: origin,
      );
    } else {
      _errorMessage = null;
      _errorCode = ConnectionError.nodeMissing;
      notifyListeners();
    }
  }

  /// Подключает выбранный узел; [origin] используется только для индикации.
  Future<void> connectFromSelection(
    ServerNode Function() resolveNode, {
    List<ServerNode> Function()? resolveCandidates,
    List<ServerNode> Function()? resolveRelays,
    Object? origin,
  }) async {
    if (state.isActive || state.isTransitioning || _starting) return;
    _starting = true;
    try {
      final ServerNode node;
      final List<ServerNode> candidates;
      final List<ServerNode> relays;
      try {
        node = resolveNode();
        candidates = resolveCandidates?.call() ?? const <ServerNode>[];
        relays = resolveRelays?.call() ?? const <ServerNode>[];
      } catch (e) {
        _errorMessage = null;
        _errorCode = ConnectionError.connectFailed;
        if (kDebugMode) {
          debugPrint('[ConnectionController] invalid node: ${e.runtimeType}');
        }
        notifyListeners();
        return;
      }
      await connect(
        node,
        origin: origin,
        fallbackNodes: candidates,
        relayCandidates: relays,
      );
    } catch (_) {
      // connect уже выставил локализуемый код ошибки.
    } finally {
      _starting = false;
    }
  }

  /// Запустить polling метрик (вызывается раз в секунду)
  void _startPollingMetrics() {
    _metricsPollingTimer?.cancel();
    _metricsPollingTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        // Уведомляем UI об обновлении метрик
        if (state.isActive) {
          notifyListeners();
        }
      },
    );
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _metricsPollingTimer?.cancel();
    _service.dispose();
    super.dispose();
  }
}
