/// Контроллер подписок: загрузка, парсинг, персистентность, обновление.
///
/// Кабинетная логика (аккаунт/объявления/карточки) читается из модели
/// [Subscription]; контроллер только управляет её жизненным циклом.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/subscription_constants.dart';
import '../../../core/network/http_connection_pool.dart';
import '../../../core/storage/key_value_storage.dart';
import '../../connection/models/local_rule_set_ref.dart';
import '../../settings/models/subscription_keys.dart';
import '../models/subscription.dart';
import '../models/subscription_error.dart';
import '../models/subscription_node.dart';
import '../models/subscription_split_tunnel.dart';
import '../services/ruleset_cache_manager.dart';
import '../services/subscription_parser.dart';
import '../services/subscription_updater.dart';
import '../services/vpn_subscription_url.dart';

/// Инъектируемый HTTP-загрузчик подписки (для тестов).
///
/// Возвращает тело ответа (JSON или vpn://-ссылку).
typedef SubscriptionFetcher = Future<String> Function(String url);

/// Провайдер ключей vpn://-подписки (Base64-пара из настроек).
typedef SubscriptionKeysLoader = Future<SubscriptionKeys> Function();

/// Инъектируемая запись бинарного `.srs`-набора на диск для sing-box.
typedef RuleSetFileWriter = Future<String?> Function(
  String id,
  Uint8List bytes,
);

/// Внутренняя ошибка ключей vpn:// (код для UI + debug-текст).
class _VpnKeysException implements Exception {
  const _VpnKeysException(this.code, this.debugMessage);

  final SubscriptionError code;
  final String debugMessage;

  @override
  String toString() => debugMessage;
}

/// Контроллер подписки для UI (ChangeNotifier).
class SubscriptionController extends ChangeNotifier {
  /// Создаёт контроллер.
  ///
  /// [storage] — персистентность; [fetcher] — загрузчик по URL
  /// (по умолчанию Dio из общего пула, AGENTS.md правило 3);
  /// [keysProvider] — ключи vpn://-подписок из secure-storage.
  SubscriptionController({
    KeyValueStorage? storage,
    SubscriptionFetcher? fetcher,
    SubscriptionKeysLoader? keysProvider,
    RuleSetCacheManager? ruleSetCacheManager,
    RuleSetFileWriter? ruleSetFileWriter,
    VoidCallback? onRuleSetsUpdated,
    SubscriptionUpdater? updater,
    bool enableAutoUpdate = false,
  })  : _storage = storage,
        _fetcher = fetcher ?? _defaultFetcher,
        _keysProvider = keysProvider,
        _ruleSetCacheManager = ruleSetCacheManager,
        _ruleSetFileWriter = ruleSetFileWriter ?? _defaultRuleSetWriter,
        _onRuleSetsUpdated = onRuleSetsUpdated,
        _updater =
            updater ?? (enableAutoUpdate ? SubscriptionUpdater() : null) {
    _updater?.bindRefreshHandler(_runScheduledRefresh);
  }

  final KeyValueStorage? _storage;
  final SubscriptionFetcher _fetcher;
  final SubscriptionKeysLoader? _keysProvider;
  final RuleSetCacheManager? _ruleSetCacheManager;
  final RuleSetFileWriter _ruleSetFileWriter;
  final VoidCallback? _onRuleSetsUpdated;
  final SubscriptionUpdater? _updater;

  /// Планировщик фонового автообновления (если подключён).
  SubscriptionUpdater? get updater => _updater;

  Future<void> _runScheduledRefresh() async {
    if (_isLoading || (_restoreFailed && _sessionOnly == false)) {
      throw StateError('Refresh skipped: busy or restoreFailed');
    }
    await refresh();
    if (_errorCode != null) {
      throw StateError('Scheduled refresh failed: $_errorCode');
    }
  }

  Subscription? _subscription;
  String? _subscriptionUrl;
  bool _isLoading = false;
  bool _savedSubscriptionExpired = false;
  bool _restoreFailed = false;
  bool _sessionOnly = false;
  int _generation = 0;
  String? _errorMessage;
  SubscriptionError? _errorCode;
  List<LocalRuleSetRef> _activeRuleSets = const <LocalRuleSetRef>[];

  /// Текущая подписка (null — не добавлена).
  Subscription? get subscription => _subscription;

  /// URL активной подписки.
  String? get subscriptionUrl => _subscriptionUrl;

  /// Идёт ли загрузка/обновление.
  bool get isLoading => _isLoading;

  /// Ошибка последней операции: debug-текст (не для UI).
  String? get errorMessage => _errorMessage;

  /// Код ошибки последней операции (для локализации в UI).
  SubscriptionError? get errorCode => _errorCode;

  /// Срок сохранённой подписки истёк. Не зависит от последней ошибки импорта.
  bool get isExpired => _subscription?.isExpired ?? _savedSubscriptionExpired;

  /// Не удалось прочитать защищённое хранилище; запись не удалялась.
  bool get restoreFailed => _restoreFailed;

  /// Данные текущей подписки находятся только в памяти.
  bool get sessionOnly => _sessionOnly;

  /// Узлы подписки.
  List<SubscriptionNode> get nodes =>
      _subscription?.nodes ?? const <SubscriptionNode>[];

  /// Активные локальные `.srs`-наборы текущей подписки.
  List<LocalRuleSetRef> get activeRuleSets => _activeRuleSets;

  /// Загружает сохранённую подписку из хранилища.
  Future<void> initialize() async {
    final storage = _storage;
    if (storage == null || _isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      final String? raw;
      try {
        raw = await storage.read(key: SubscriptionConstants.storageKey);
      } catch (_) {
        _restoreFailed = true;
        _errorMessage = 'Не удалось прочитать подписку';
        _errorCode = SubscriptionError.loadFailed;
        return;
      }
      _restoreFailed = false;
      _errorMessage = null;
      _errorCode = null;
      if (raw == null || raw.isEmpty) return;
      final record = jsonDecode(raw);
      if (record is! Map<String, dynamic>) return;

      final savedUrl = record['url'] as String?;
      _subscriptionUrl =
          savedUrl == null ? null : VpnSubscriptionUrl.sanitizeUrl(savedUrl);
      final rawSubscription = record['raw'] as String?;
      if (rawSubscription == null || rawSubscription.isEmpty) return;

      _subscription = await SubscriptionParser.parse(rawSubscription);
      _sessionOnly = false;
      _savedSubscriptionExpired = false;
      _updater?.configure(_subscription);
      unawaited(syncRuleSets());
    } on SubscriptionParseException catch (e) {
      _errorMessage = e.message;
      _errorCode = _mapParseError(e.kind);
      _savedSubscriptionExpired = e.kind == SubscriptionParseErrorKind.expired;
    } catch (e) {
      _errorMessage = 'Сохранённая подписка повреждена';
      _errorCode = SubscriptionError.broken;
      if (kDebugMode) {
        debugPrint('[SubscriptionController] broken record: ${e.runtimeType}');
      }
      await _clearStorage();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Добавляет подписку по URL (`https://` JSON или `vpn://` ваучер).
  Future<void> addFromUrl(String url) => _addFromUrl(url, persist: true);

  /// Импортирует подписку на текущий сеанс, не меняя сохранённую запись.
  Future<void> addForSession(String url) => _addFromUrl(url, persist: false);

  Future<void> _addFromUrl(String url, {required bool persist}) async {
    final trimmed = VpnSubscriptionUrl.sanitizeUrl(url);
    if (trimmed.isEmpty) {
      return _setError('Введите URL подписки', SubscriptionError.enterUrl);
    }

    final isVoucher = _isVpnVoucher(trimmed);
    await _load(
      url: isVoucher ? null : trimmed,
      rawProvider: isVoucher ? () async => trimmed : () => _fetcher(trimmed),
      persist: persist,
    );
  }

  /// Добавляет подписку из сырого JSON или vpn://-ссылки (вставка/тесты).
  Future<void> addFromRaw(String rawJson) {
    return _load(url: null, rawProvider: () async => rawJson);
  }

  static bool _isVpnVoucher(String value) =>
      value.trimLeft().toLowerCase().startsWith('vpn://');

  /// Обновляет подписку по сохранённому URL.
  Future<void> refresh() async {
    final rawUrl = _subscriptionUrl;
    final url = rawUrl == null ? null : VpnSubscriptionUrl.sanitizeUrl(rawUrl);
    if (url == null || url.isEmpty) {
      return _setError(
        'URL обновления не задан',
        SubscriptionError.noUpdateUrl,
      );
    }
    _subscriptionUrl = url;
    await _load(
      url: url,
      rawProvider: () => _fetcher(url),
      persist: !_sessionOnly,
    );
  }

  /// Удаляет подписку.
  Future<void> remove() async {
    _generation++;
    final removeSaved = !_sessionOnly && !_restoreFailed;
    _subscription = null;
    _subscriptionUrl = null;
    _sessionOnly = false;
    _savedSubscriptionExpired = false;
    _activeRuleSets = const <LocalRuleSetRef>[];
    _errorMessage = null;
    _errorCode = null;
    _updater?.stop();
    if (removeSaved) await _clearStorage();
    notifyListeners();
  }

  @override
  void dispose() {
    _updater?.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // ВНУТРЕННЯЯ ЛОГИКА
  // --------------------------------------------------------------------------

  Future<void> _load({
    required String? url,
    required Future<String> Function() rawProvider,
    bool persist = true,
  }) async {
    // Не заменяем непрочитанную запись; явный импорт в память остаётся доступен.
    if (_isLoading || (persist && _restoreFailed)) return;
    _isLoading = true;
    _errorMessage = null;
    _errorCode = null;
    final opGeneration = _generation;
    notifyListeners();

    try {
      final raw = await rawProvider();

      final Subscription parsed;
      if (_isVpnVoucher(raw)) {
        parsed = await _parseVpnSubscription(raw);
      } else {
        parsed = await SubscriptionParser.parse(raw);
      }

      if (opGeneration != _generation) return;

      _subscription = parsed;
      _savedSubscriptionExpired = false;
      _sessionOnly = !persist;
      _subscriptionUrl = parsed.update?.url.isNotEmpty == true
          ? VpnSubscriptionUrl.sanitizeUrl(parsed.update!.url)
          : url;
      if (persist) {
        final isRawUriList =
            !raw.trimLeft().startsWith('{') && !_isVpnVoucher(raw);
        await _persist(rawOverride: isRawUriList ? raw : null);
      }
      if (opGeneration != _generation) return;
      _updater?.configure(parsed);
      unawaited(syncRuleSets());
    } on SubscriptionParseException catch (e) {
      _errorMessage = e.message;
      _errorCode = _mapParseError(e.kind);
    } on DioException catch (e) {
      // Правило 16: в пользовательские сообщения не попадают URL/хосты.
      if (kDebugMode) {
        debugPrint('[SubscriptionController] fetch failed: ${e.type}');
      }
      _errorMessage = 'Сеть недоступна или сервер подписки не ответил';
      _errorCode = SubscriptionError.network;
    } on _VpnKeysException catch (e) {
      _errorMessage = e.debugMessage;
      _errorCode = e.code;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SubscriptionController] load failed: ${e.runtimeType}');
      }
      _errorMessage = 'Не удалось загрузить подписку';
      _errorCode = SubscriptionError.loadFailed;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Расшифровывает и парсит vpn://-подписку с ключами из настроек.
  Future<Subscription> _parseVpnSubscription(String vpnUrl) async {
    final keysProvider = _keysProvider;
    if (keysProvider == null) {
      throw const _VpnKeysException(
        SubscriptionError.noKeys,
        'Ключи vpn:// не настроены',
      );
    }

    final keys = await keysProvider();
    final verifyKeyB64 = keys.verifyKeyMaterial;
    final decryptKeyB64 = keys.decryptKey?.trim();
    if ((verifyKeyB64 == null || verifyKeyB64.isEmpty) ||
        (decryptKeyB64 == null || decryptKeyB64.isEmpty)) {
      throw const _VpnKeysException(
        SubscriptionError.noKeys,
        'Ключи vpn:// не настроены',
      );
    }

    final verifyKey = _decodeKey(verifyKeyB64);
    final decryptKey = _decodeKey(decryptKeyB64);
    if (verifyKey == null ||
        verifyKey.isEmpty ||
        (!keys.usesHmac && verifyKey.length != 32) ||
        decryptKey == null ||
        decryptKey.length != 32) {
      throw const _VpnKeysException(
        SubscriptionError.invalidKey,
        'Некорректный ключ подписки',
      );
    }

    return SubscriptionParser.parseVpnUrl(
      vpnUrl,
      ed25519PublicKey: keys.usesHmac ? null : verifyKey,
      hmacKey: keys.usesHmac ? verifyKey : null,
      aesKey: decryptKey,
    );
  }

  /// Декодирует Base64-ключ; null при некорректном формате.
  static List<int>? _decodeKey(String base64Value) {
    try {
      return VpnSubscriptionUrl.decodeBase64(base64Value);
    } catch (_) {
      return null;
    }
  }

  static SubscriptionError _mapParseError(SubscriptionParseErrorKind kind) =>
      switch (kind) {
        SubscriptionParseErrorKind.invalid ||
        SubscriptionParseErrorKind.url =>
          SubscriptionError.invalid,
        SubscriptionParseErrorKind.outdatedVersion =>
          SubscriptionError.outdatedVersion,
        SubscriptionParseErrorKind.expired => SubscriptionError.expired,
        SubscriptionParseErrorKind.noNodes => SubscriptionError.noNodes,
        SubscriptionParseErrorKind.noTcpChannel =>
          SubscriptionError.noTcpChannel,
        SubscriptionParseErrorKind.signature => SubscriptionError.signature,
        SubscriptionParseErrorKind.key => SubscriptionError.invalidKey,
      };

  Future<void> _persist({String? rawOverride}) async {
    final storage = _storage;
    final subscription = _subscription;
    if (storage == null || subscription == null) return;
    try {
      final raw = rawOverride ?? jsonEncode(subscription.toJson());
      await storage.write(
        key: SubscriptionConstants.storageKey,
        value: jsonEncode({'url': _subscriptionUrl, 'raw': raw}),
      );
    } catch (e) {
      _errorMessage = 'Не удалось сохранить подписку: $e';
      _errorCode = SubscriptionError.saveFailed;
    }
  }

  Future<void> _clearStorage() async {
    final storage = _storage;
    if (storage == null) return;
    try {
      await storage.delete(key: SubscriptionConstants.storageKey);
    } catch (_) {}
  }

  void _setError(String message, SubscriptionError code) {
    _errorMessage = message;
    _errorCode = code;
    notifyListeners();
  }

  /// Синхронизирует внешние `.srs`-наборы подписки через [RuleSetCacheManager].
  ///
  /// Правило 32: сбой скачивания не ломает подписку — используется LKG-кэш.
  Future<void> syncRuleSets() async {
    final manager = _ruleSetCacheManager;
    final descriptors =
        _subscription?.splitTunnel?.ruleSets ?? const <SubscriptionRuleSet>[];
    if (manager == null || descriptors.isEmpty) {
      if (_activeRuleSets.isNotEmpty) {
        _activeRuleSets = const <LocalRuleSetRef>[];
        notifyListeners();
        _onRuleSetsUpdated?.call();
      }
      return;
    }

    final resolved = <LocalRuleSetRef>[];
    for (final d in descriptors) {
      if (d.id.isEmpty || d.url.isEmpty) continue;
      final res = await manager.fetch(
        id: d.id,
        url: d.url,
        expectedSha256: d.sha256,
      );
      final bytes = res.ruleSet?.bytes;
      if (!res.isAvailable || bytes == null) continue;
      final path = await _ruleSetFileWriter(d.id, bytes);
      if (path != null && path.isNotEmpty) {
        resolved.add(LocalRuleSetRef(tag: d.id, path: path, action: d.action));
      }
    }
    _activeRuleSets = List.unmodifiable(resolved);
    notifyListeners();
    _onRuleSetsUpdated?.call();
  }

  static Future<String?> _defaultRuleSetWriter(
    String id,
    Uint8List bytes,
  ) async {
    try {
      final dir = await getApplicationSupportDirectory();
      final safeId = id.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final rulesDir = Directory('${dir.path}${Platform.pathSeparator}rulesets')
        ..createSync(recursive: true);
      final file = File('${rulesDir.path}${Platform.pathSeparator}$safeId.srs');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  static Future<String> _defaultFetcher(String url) async {
    final response = await HttpConnectionPool.instance.client.get<String>(
      url,
      options: Options(
        responseType: ResponseType.plain,
        receiveTimeout: SubscriptionConstants.httpTimeout,
      ),
    );
    return response.data ?? '';
  }
}
