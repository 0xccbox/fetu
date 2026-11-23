import 'package:dio/dio.dart';

/// Синглтон пул HTTP-соединений с поддержкой Keep-Alive.
///
/// **ОБЯЗАТЕЛЬНОЕ ПРАВИЛО (из AGENTS.md #3):**
/// Никогда не создавай `HttpClient()` напрямую в сервисах — это приводит
/// к утечке сокетов и дескрипторов ОС. Всегда используй `HttpConnectionPool.instance.client`.
final class HttpConnectionPool {
  /// Глобальный синглтон экземпляр пула.
  static final HttpConnectionPool instance = HttpConnectionPool._internal();

  late final Dio _client;

  /// Доступ к настроенному Dio-клиенту с Keep-Alive.
  Dio get client => _client;

  HttpConnectionPool._internal() {
    _client = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        // Включаем Keep-Alive для переиспользования TCP-соединений.
        persistentConnection: true,
        // Устанавливаем разумный лимит редиректов.
        maxRedirects: 3,
        // Валидация статус-кодов (по умолчанию 200-299).
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
      ),
    );

    // Добавляем логирование запросов в debug-режиме.
    _client.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody:
            false, // Не логируем тело запроса (может содержать credentials).
        responseHeader: false,
        responseBody: false, // Не логируем тело ответа (может быть огромным).
        error: true,
        logPrint: (obj) => _debugLog(obj.toString()),
      ),
    );
  }

  /// Закрывает все открытые соединения при завершении работы приложения.
  void close() {
    _client.close(force: true);
  }

  /// Внутренний метод логирования (можно заменить на нормальный logger).
  void _debugLog(String message) {
    // В production этот метод не должен ничего делать.
    // В debug можно подключить `logger` пакет.
    assert(() {
      // ignore: avoid_print
      print('[HttpConnectionPool] $message');
      return true;
    }());
  }
}
