/// Планировщик фонового автообновления подписки по `update.interval`
/// с защитой Last-Known-Good (LKG-fallback при любой ошибке сети/парсинга).
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/constants/subscription_constants.dart';
import '../models/subscription.dart';

/// Колбэк выполнения одного обновления подписки.
typedef SubscriptionRefreshCallback = Future<void> Function();

/// Статус последнего фонового автообновления.
enum SubscriptionUpdateStatus {
  /// Ожидание следующего тика.
  idle,

  /// Идёт фоновое обновление.
  updating,

  /// Последнее обновление прошло успешно.
  succeeded,

  /// Ошибка обновления: сохранена LKG-подписка.
  fallbackLkg,
}

/// Сервис фонового автообновления подписки.
class SubscriptionUpdater {
  /// Создаёт планировщик автообновления.
  SubscriptionUpdater({
    SubscriptionRefreshCallback? onRefresh,
    int minIntervalSeconds = SubscriptionConstants.minAutoUpdateIntervalSeconds,
  })  : _onRefresh = onRefresh,
        _minIntervalSeconds = minIntervalSeconds;

  SubscriptionRefreshCallback? _onRefresh;
  final int _minIntervalSeconds;

  Timer? _timer;
  Duration? _activeInterval;
  bool _isUpdating = false;
  DateTime? _lastAttemptAt;
  DateTime? _lastSuccessAt;
  SubscriptionUpdateStatus _status = SubscriptionUpdateStatus.idle;

  /// Текущий статус автообновления.
  SubscriptionUpdateStatus get status => _status;

  /// Интервал активного расписания (null если автообновление остановлено).
  Duration? get activeInterval => _activeInterval;

  /// Время последней попытки обновления.
  DateTime? get lastAttemptAt => _lastAttemptAt;

  /// Время последнего успешного обновления.
  DateTime? get lastSuccessAt => _lastSuccessAt;

  /// Задаёт колбэк обновления (удобно при связывании в конструкторе контроллера).
  void bindRefreshHandler(SubscriptionRefreshCallback handler) {
    _onRefresh = handler;
  }

  /// Настраивает расписание по [subscription.update].
  ///
  /// Если у подписки нет URL обновления или `interval <= 0`, останавливает таймер.
  void configure(Subscription? subscription) {
    final update = subscription?.update;
    if (subscription == null ||
        update == null ||
        update.url.trim().isEmpty ||
        update.intervalSeconds <= 0) {
      stop();
      return;
    }

    final clampedSeconds = update.intervalSeconds < _minIntervalSeconds
        ? _minIntervalSeconds
        : update.intervalSeconds;
    final interval = Duration(seconds: clampedSeconds);
    if (_timer != null && _activeInterval == interval) return;

    stop();
    _activeInterval = interval;
    _timer = Timer.periodic(interval, (_) {
      unawaited(triggerNow());
    });
  }

  /// Немедленно запускает цикл обновления с защитой от повторного входа и LKG-fallback.
  ///
  /// Returns: `true` при успешном обновлении, `false` при сбое (LKG сохранён).
  Future<bool> triggerNow({bool Function()? isSuccess}) async {
    final handler = _onRefresh;
    if (handler == null || _isUpdating) return false;

    _isUpdating = true;
    _status = SubscriptionUpdateStatus.updating;
    _lastAttemptAt = DateTime.now();

    try {
      await handler();
      final ok = isSuccess?.call() ?? true;
      if (ok) {
        _lastSuccessAt = DateTime.now();
        _status = SubscriptionUpdateStatus.succeeded;
        return true;
      }
      _status = SubscriptionUpdateStatus.fallbackLkg;
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SubscriptionUpdater] LKG fallback: ${e.runtimeType}');
      }
      _status = SubscriptionUpdateStatus.fallbackLkg;
      return false;
    } finally {
      _isUpdating = false;
    }
  }

  /// Останавливает фоновое автообновление.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _activeInterval = null;
  }

  /// Освобождает ресурсы.
  void dispose() {
    stop();
  }
}
