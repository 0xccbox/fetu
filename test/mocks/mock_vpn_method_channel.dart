/// Мокированная реализация VPN Platform Channel для unit тестов.
library;

import 'dart:async';

import 'package:fetu/core/platform/vpn_method_channel.dart';
import 'package:flutter/services.dart';

/// Mock реализация VpnMethodChannel для тестирования без нативного кода.
class MockVpnMethodChannel implements VpnMethodChannel {
  bool _isConnected = false;
  String? _currentConfig;

  /// Сколько раз вызывался reloadConfig (для проверок в тестах).
  int reloadCalls = 0;

  /// Сколько раз вызывался disconnect (для Zero-Drop проверок).
  int disconnectCalls = 0;

  final _statusController = StreamController<NativeVpnStatus>.broadcast();
  final _metricsController = StreamController<NativeVpnMetrics>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  @override
  Stream<NativeVpnStatus> get statusStream => _statusController.stream;

  @override
  Stream<NativeVpnMetrics> get metricsStream => _metricsController.stream;

  @override
  Stream<String> get errorStream => _errorController.stream;

  @override
  Future<bool> isVpnAvailable() async => true;

  @override
  Future<bool> requestVpnPermission() async => true;

  @override
  Future<void> connect(String configJson) async {
    if (_isConnected) {
      throw PlatformException(
        code: 'ALREADY_CONNECTED',
        message: 'VPN already connected',
      );
    }

    _currentConfig = configJson;

    // Симуляция подключения
    _statusController.add(NativeVpnStatus.connecting);
    await Future.delayed(const Duration(milliseconds: 100));
    _isConnected = true;
    _statusController.add(NativeVpnStatus.connected);
  }

  @override
  Future<void> disconnect() async {
    if (!_isConnected) {
      return;
    }

    disconnectCalls++;

    // Симуляция отключения
    _statusController.add(NativeVpnStatus.disconnecting);
    await Future.delayed(const Duration(milliseconds: 50));
    _isConnected = false;
    _currentConfig = null;
    _statusController.add(NativeVpnStatus.disconnected);
  }

  @override
  Future<void> reloadConfig(String configJson) async {
    if (!_isConnected) {
      throw PlatformException(
        code: 'NOT_CONNECTED',
        message: 'VPN not connected, nothing to reload',
      );
    }

    // Zero-Drop Live Reload: конфигурация меняется, статус не трогаем.
    _currentConfig = configJson;
    reloadCalls++;
  }

  @override
  Future<NativeVpnStatus> getStatus() async {
    return _isConnected
        ? NativeVpnStatus.connected
        : NativeVpnStatus.disconnected;
  }

  @override
  Future<NativeVpnMetrics?> getMetrics() async {
    if (!_isConnected) {
      return null;
    }

    // Симуляция реальных метрик
    return NativeVpnMetrics(
      uploadBytes: 5 * 1024 * 1024, // 5 MB
      downloadBytes: 10 * 1024 * 1024, // 10 MB
      uploadSpeed: 512 * 1024, // 512 KB/s
      downloadSpeed: 1024 * 1024, // 1 MB/s
      ping: 50, // 50 ms
      timestamp: DateTime.now(),
    );
  }

  @override
  void dispose() {
    _statusController.close();
    _metricsController.close();
    _errorController.close();
  }

  // Утилитные методы для тестирования

  /// Симулирует ошибку VPN
  void simulateError(String error) {
    _errorController.add(error);
    _statusController.add(NativeVpnStatus.error);
  }

  /// Симулирует обновление метрик
  void simulateMetricsUpdate(NativeVpnMetrics metrics) {
    _metricsController.add(metrics);
  }

  /// Проверяет, была ли установлена конфигурация
  bool get hasConfig => _currentConfig != null;

  /// Получает текущую конфигурацию (для проверки в тестах)
  String? get currentConfig => _currentConfig;
}
