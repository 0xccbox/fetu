import 'dart:async';

import '../models/connection_metrics.dart';

/// Генератор мок-метрик трафика для режима [VpnServiceMode.mock].
class MockTrafficTracker {
  Timer? _timer;
  DateTime? _startTime;
  int _totalDownloaded = 0;
  int _totalUploaded = 0;

  /// Запускает периодическое обновление метрик раз в секунду.
  void start(void Function(ConnectionMetrics metrics) onTick) {
    stop();
    _startTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      final downloadSpeed = 500000 + (now.millisecond * 100);
      final uploadSpeed = 100000 + (now.millisecond * 50);
      _totalDownloaded += downloadSpeed;
      _totalUploaded += uploadSpeed;
      final duration =
          _startTime != null ? now.difference(_startTime!).inSeconds : 0;

      onTick(
        ConnectionMetrics(
          downloadSpeed: downloadSpeed,
          uploadSpeed: uploadSpeed,
          totalDownloaded: _totalDownloaded,
          totalUploaded: _totalUploaded,
          connectionDuration: duration,
          latency: 45 + (now.millisecond % 20),
        ),
      );
    });
  }

  /// Останавливает трекер и сбрасывает счётчики.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _startTime = null;
    _totalDownloaded = 0;
    _totalUploaded = 0;
  }
}
