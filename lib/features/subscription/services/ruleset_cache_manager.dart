/// Безопасный менеджер кэша бинарных `.srs` rule-set'ов.
///
/// AGENTS.md, правило 32: крупные списки правил НЕ передаются инлайн
/// в JSON-конфиг sing-box — они скачиваются как сжатые бинарные `.srs`
/// файлы с предзагрузкой по `ETag`, проверкой `sha256` и лимитом
/// `max_size_kb`. При любой ошибке скачивания возвращается
/// Last-Known-Good кэш — подписка обновляется всегда.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:dio/dio.dart';

import '../../../core/constants/subscription_constants.dart';
import '../../../core/network/http_connection_pool.dart';
import '../../../core/storage/key_value_storage.dart';

/// Итоговый статус загрузки rule-set'а.
enum RuleSetFetchStatus {
  /// Скачан новый набор (ETag изменился).
  updated,

  /// Сервер вернул 304 — актуален кэш.
  notModified,

  /// Скачивание не удалось, отдан Last-Known-Good кэш.
  lkgFallback,

  /// Скачать и вернуть нечего.
  failed,
}

/// Результат загрузки rule-set'а.
class RuleSetFetchResult {
  /// Создаёт результат.
  const RuleSetFetchResult({
    required this.status,
    this.ruleSet,
    this.error,
  });

  /// Статус.
  final RuleSetFetchStatus status;

  /// Данные (null только при [RuleSetFetchStatus.failed]).
  final CachedRuleSet? ruleSet;

  /// Причина сбоя (для UI/логов, без URL — правило 16).
  final String? error;

  /// Есть ли рабочие данные.
  bool get isAvailable =>
      status != RuleSetFetchStatus.failed && ruleSet != null;
}

/// Кэшированный бинарный rule-set с метаданными проверки.
class CachedRuleSet {
  /// Создаёт запись кэша.
  const CachedRuleSet({
    required this.bytes,
    required this.etag,
    required this.sha256,
    required this.cachedAt,
  });

  /// Бинарные данные `.srs`.
  final Uint8List bytes;

  /// ETag последней успешной загрузки.
  final String etag;

  /// sha256 данных.
  final String sha256;

  /// Время кэширования.
  final DateTime cachedAt;

  /// Размер в килобайтах.
  int get sizeKb => (bytes.length / 1024).ceil();

  /// Сериализует запись в JSON для хранилища.
  Map<String, dynamic> toJson() => {
        'etag': etag,
        'sha256': sha256,
        'cached_at': cachedAt.toIso8601String(),
        'data': base64Encode(bytes),
      };

  /// Восстанавливает запись из хранилища.
  static CachedRuleSet? fromJson(Map<String, dynamic> json) {
    final data = json['data'] as String?;
    if (data == null) return null;
    try {
      return CachedRuleSet(
        bytes: base64Decode(data),
        etag: json['etag'] as String? ?? '',
        sha256: json['sha256'] as String? ?? '',
        cachedAt: DateTime.tryParse(json['cached_at'] as String? ?? '') ??
            DateTime.now(),
      );
    } on FormatException {
      return null;
    }
  }
}

/// Ответ сетевого загрузчика (только для внутренних нужд менеджера).
class RuleSetDownload {
  /// Создаёт ответ загрузчика.
  const RuleSetDownload({
    required this.statusCode,
    this.bytes,
    this.etag,
  });

  /// HTTP-статус (200/304).
  final int statusCode;

  /// Тело ответа (null при 304).
  final Uint8List? bytes;

  /// ETag ответа.
  final String? etag;
}

/// Инъектируемый загрузчик rule-set'ов (для тестов).
typedef RuleSetFetcher = Future<RuleSetDownload?> Function(
  String url,
  String? etag,
);

/// Менеджер безопасного кэша `.srs` rule-set'ов.
class RuleSetCacheManager {
  /// Создаёт менеджер.
  ///
  /// [storage] — хранилище кэша; [fetcher] — сетевой загрузчик
  /// (по умолчанию Dio из [HttpConnectionPool], правило 3).
  RuleSetCacheManager({KeyValueStorage? storage, RuleSetFetcher? fetcher})
      : _storage = storage,
        _fetcher = fetcher ?? _defaultFetcher;

  final KeyValueStorage? _storage;
  final RuleSetFetcher _fetcher;

  /// Ключ хранилища для набора.
  static String storageKeyFor(String id) =>
      '${SubscriptionConstants.srsCacheKeyPrefix}$id';

  /// Загружает rule-set с кэшированием по ETag и LKG-fallback.
  ///
  /// [id] — стабильный идентификатор набора; [url] — источник;
  /// [expectedSha256] — ожидаемый sha256 из подписки (если задан —
  /// данные с несовпавшим хэшем отбрасываются).
  Future<RuleSetFetchResult> fetch({
    required String id,
    required String url,
    String? expectedSha256,
  }) async {
    final cached = await _loadCached(id);

    // 1. Кэш не пуст и набор не изменился на сервере → 304.
    final download = await _fetcher(url, cached?.etag);

    if (download == null) {
      return _lkgOrFailure(cached, 'Сеть недоступна');
    }
    if (download.statusCode == 304) {
      return RuleSetFetchResult(
        status: RuleSetFetchStatus.notModified,
        ruleSet: cached,
      );
    }
    if (download.statusCode != 200 || download.bytes == null) {
      return _lkgOrFailure(cached, 'Некорректный ответ сервера');
    }

    final bytes = download.bytes!;

    // 2. Лимит размера (правило 32 — защита от OOM).
    if (bytes.length > SubscriptionConstants.srsMaxSizeKb * 1024) {
      return _lkgOrFailure(
        cached,
        'Набор превышает лимит ${SubscriptionConstants.srsMaxSizeKb} KB',
      );
    }

    // 3. Контроль целостности.
    final sha256 = crypto.sha256.convert(bytes).toString();
    if (expectedSha256 != null && sha256 != expectedSha256) {
      return _lkgOrFailure(cached, 'sha256 не совпал');
    }

    final fresh = CachedRuleSet(
      bytes: bytes,
      etag: download.etag ?? '',
      sha256: sha256,
      cachedAt: DateTime.now(),
    );

    // 4. Кэшируем (сбой записи не фатален — данные уже валидны).
    await _store(id, fresh);

    return RuleSetFetchResult(
      status: RuleSetFetchStatus.updated,
      ruleSet: fresh,
    );
  }

  /// Возвращает кэшированный набор без сети (LKG).
  Future<CachedRuleSet?> cachedSet(String id) => _loadCached(id);

  /// Удаляет кэш набора.
  Future<void> invalidate(String id) async {
    final storage = _storage;
    if (storage == null) return;
    await storage.delete(key: storageKeyFor(id));
  }

  static RuleSetFetchResult _lkgOrFailure(
    CachedRuleSet? cached,
    String error,
  ) =>
      cached == null
          ? RuleSetFetchResult(
              status: RuleSetFetchStatus.failed,
              error: error,
            )
          : RuleSetFetchResult(
              status: RuleSetFetchStatus.lkgFallback,
              ruleSet: cached,
              error: error,
            );

  Future<CachedRuleSet?> _loadCached(String id) async {
    final storage = _storage;
    if (storage == null) return null;
    try {
      final raw = await storage.read(key: storageKeyFor(id));
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final cached = CachedRuleSet.fromJson(decoded);
      if (cached == null) return null;

      // Защита от подмены через хранилище: контрольная сумма данных
      // обязана совпадать с сохранённой (правило 32).
      final actualSha = crypto.sha256.convert(cached.bytes).toString();
      if (cached.sha256.isNotEmpty && actualSha != cached.sha256) {
        return null;
      }
      return cached;
    } catch (_) {
      return null;
    }
  }

  Future<void> _store(String id, CachedRuleSet ruleSet) async {
    final storage = _storage;
    if (storage == null) return;
    try {
      await storage.write(
        key: storageKeyFor(id),
        value: jsonEncode(ruleSet.toJson()),
      );
    } catch (_) {
      // Кэш — оптимизация: сбой записи не должен ломать обновление.
    }
  }

  /// Сетевой загрузчик по умолчанию: Dio из общего пула (правило 3).
  static Future<RuleSetDownload?> _defaultFetcher(
    String url,
    String? etag,
  ) async {
    try {
      final response = await HttpConnectionPool.instance.client.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: SubscriptionConstants.srsDownloadTimeout,
          validateStatus: (status) => status == 200 || status == 304,
          headers: {
            if (etag != null && etag.isNotEmpty) 'If-None-Match': etag,
          },
        ),
      );
      return RuleSetDownload(
        statusCode: response.statusCode ?? 0,
        etag: response.headers.value('etag'),
        bytes: response.data == null || response.data!.isEmpty
            ? null
            : Uint8List.fromList(response.data!),
      );
    } on DioException {
      return null;
    }
  }
}
