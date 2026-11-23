/// Platform channel для взаимодействия с нативным VPN-кодом (Android/iOS).
///
/// Основной интерфейс для:
/// - Подключения/отключения VPN
/// - Передачи sing-box конфигурации в нативный слой
/// - Получения статуса подключения и метрик
/// - Обработки событий из нативного кода
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

/// Исключение платформенного канала VPN.
class VpnChannelException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const VpnChannelException(this.message, {this.code, this.details});

  @override
  String toString() => 'VpnChannelException: $message (code: $code)';
}

/// Статус VPN-подключения из нативного слоя.
enum NativeVpnStatus {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error;

  factory NativeVpnStatus.fromString(String value) {
    return switch (value) {
      'disconnected' => NativeVpnStatus.disconnected,
      'connecting' => NativeVpnStatus.connecting,
      'connected' => NativeVpnStatus.connected,
      'disconnecting' => NativeVpnStatus.disconnecting,
      'error' => NativeVpnStatus.error,
      _ => NativeVpnStatus.disconnected,
    };
  }
}

/// Метрики VPN-подключения из нативного слоя.
class NativeVpnMetrics {
  final int uploadBytes;
  final int downloadBytes;
  final int uploadSpeed; // bytes/sec
  final int downloadSpeed; // bytes/sec
  final int ping; // ms
  final DateTime timestamp;

  const NativeVpnMetrics({
    required this.uploadBytes,
    required this.downloadBytes,
    required this.uploadSpeed,
    required this.downloadSpeed,
    required this.ping,
    required this.timestamp,
  });

  factory NativeVpnMetrics.fromMap(Map<dynamic, dynamic> map) {
    return NativeVpnMetrics(
      uploadBytes: map['uploadBytes'] as int? ?? 0,
      downloadBytes: map['downloadBytes'] as int? ?? 0,
      uploadSpeed: map['uploadSpeed'] as int? ?? 0,
      downloadSpeed: map['downloadSpeed'] as int? ?? 0,
      ping: map['ping'] as int? ?? 0,
      timestamp: DateTime.now(),
    );
  }
}

/// Platform channel для VPN операций.
///
/// Использует единственный канал 'com.fetu.app/method_channel' для всех операций.
/// Регистрирует обработчик нативных событий через setMethodCallHandler.
class VpnMethodChannel {
  static const _channel = MethodChannel('com.fetu.app/method_channel');

  /// Stream контроллер для событий статуса VPN.
  final _statusController = StreamController<NativeVpnStatus>.broadcast();

  /// Stream контроллер для метрик VPN.
  final _metricsController = StreamController<NativeVpnMetrics>.broadcast();

  /// Stream контроллер для ошибок VPN.
  final _errorController = StreamController<String>.broadcast();

  /// Единственный экземпляр (синглтон).
  static final VpnMethodChannel instance = VpnMethodChannel._();

  VpnMethodChannel._() {
    // Регистрируем обработчик событий из нативного кода
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  /// Stream статусов VPN.
  Stream<NativeVpnStatus> get statusStream => _statusController.stream;

  /// Stream метрик VPN.
  Stream<NativeVpnMetrics> get metricsStream => _metricsController.stream;

  /// Stream ошибок VPN.
  Stream<String> get errorStream => _errorController.stream;

  /// Обработчик вызовов из нативного кода.
  Future<dynamic> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onStatusChanged':
        final status = NativeVpnStatus.fromString(call.arguments as String);
        _statusController.add(status);
        break;

      case 'onMetricsUpdated':
        final metrics = NativeVpnMetrics.fromMap(call.arguments as Map);
        _metricsController.add(metrics);
        break;

      case 'onError':
        final error = call.arguments as String;
        _errorController.add(error);
        break;

      default:
        throw MissingPluginException(
          'Unknown method: ${call.method}',
        );
    }
  }

  /// Проверяет доступность VPN на устройстве.
  ///
  /// Returns: true если VPN поддерживается, false иначе.
  Future<bool> isVpnAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isVpnAvailable');
      return result ?? false;
    } on PlatformException catch (e) {
      throw VpnChannelException(
        'Failed to check VPN availability',
        code: e.code,
        details: e.details,
      );
    }
  }

  /// Запрашивает разрешение VPN у пользователя (Android).
  ///
  /// На iOS этот метод ничего не делает (разрешения запрашиваются автоматически).
  ///
  /// Returns: true если разрешение получено, false если отклонено.
  Future<bool> requestVpnPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestVpnPermission');
      return result ?? false;
    } on PlatformException catch (e) {
      throw VpnChannelException(
        'Failed to request VPN permission',
        code: e.code,
        details: e.details,
      );
    }
  }

  /// Подключается к VPN с указанной sing-box конфигурацией.
  ///
  /// [configJson] — JSON-строка с полной конфигурацией sing-box.
  ///
  /// Throws: [VpnChannelException] если подключение не удалось.
  Future<void> connect(String configJson) async {
    try {
      // Валидируем JSON перед отправкой
      final _ = jsonDecode(configJson);

      await _channel.invokeMethod<void>('connect', {
        'config': configJson,
      });
    } on FormatException catch (e) {
      throw VpnChannelException(
        'Invalid JSON configuration: ${e.message}',
        code: 'INVALID_CONFIG',
      );
    } on PlatformException catch (e) {
      throw VpnChannelException(
        'Failed to connect VPN: ${e.message}',
        code: e.code,
        details: e.details,
      );
    }
  }

  /// Отключается от VPN.
  ///
  /// Throws: [VpnChannelException] если отключение не удалось.
  Future<void> disconnect() async {
    try {
      await _channel.invokeMethod<void>('disconnect');
    } on PlatformException catch (e) {
      throw VpnChannelException(
        'Failed to disconnect VPN: ${e.message}',
        code: e.code,
        details: e.details,
      );
    }
  }

  /// Обновляет конфигурацию работающего VPN без разрыва туннеля.
  ///
  /// Zero-Drop Live Reload: sing-box применяет новую конфигурацию
  /// на лету (AGENTS.md, инвариант №8). Используется при смене
  /// правил раздельного туннелирования и failover протоколов.
  ///
  /// [configJson] — JSON-строка с полной конфигурацией sing-box.
  ///
  /// Throws: [VpnChannelException] если перезагрузка не удалась.
  Future<void> reloadConfig(String configJson) async {
    try {
      // Валидируем JSON перед отправкой
      final _ = jsonDecode(configJson);

      await _channel.invokeMethod<void>('reloadConfig', {
        'config': configJson,
      });
    } on FormatException catch (e) {
      throw VpnChannelException(
        'Invalid JSON configuration: ${e.message}',
        code: 'INVALID_CONFIG',
      );
    } on PlatformException catch (e) {
      throw VpnChannelException(
        'Failed to reload VPN config: ${e.message}',
        code: e.code,
        details: e.details,
      );
    }
  }

  /// Получает текущий статус VPN.
  ///
  /// Returns: Текущий статус VPN из нативного слоя.
  Future<NativeVpnStatus> getStatus() async {
    try {
      final result = await _channel.invokeMethod<String>('getStatus');
      return NativeVpnStatus.fromString(result ?? 'disconnected');
    } on PlatformException catch (e) {
      throw VpnChannelException(
        'Failed to get VPN status: ${e.message}',
        code: e.code,
        details: e.details,
      );
    }
  }

  /// Получает текущие метрики VPN.
  ///
  /// Returns: Метрики трафика и скорости из нативного слоя.
  /// Returns null если VPN не подключен.
  Future<NativeVpnMetrics?> getMetrics() async {
    try {
      final result = await _channel.invokeMethod<Map>('getMetrics');
      if (result == null) return null;
      return NativeVpnMetrics.fromMap(result);
    } on PlatformException catch (e) {
      throw VpnChannelException(
        'Failed to get VPN metrics: ${e.message}',
        code: e.code,
        details: e.details,
      );
    }
  }

  /// Очищает ресурсы (закрывает stream контроллеры).
  void dispose() {
    _statusController.close();
    _metricsController.close();
    _errorController.close();
  }
}
