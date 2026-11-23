/// Контроллер правил раздельного туннелирования.
///
/// Управляет списком правил, сохраняет их в KeyValueStorage
/// и уведомляет UI. После каждого изменения вызывает колбэк
/// [OnSplitRulesChanged] для Zero-Drop Live Reload конфигурации
/// работающего туннеля (AGENTS.md, правило 8).
///
/// Ошибки выставляются кодом [SplitTunnelError] (для локализации
/// в UI, правило 14); сырой текст — только debug-детали.
library;

import 'dart:convert';
import 'dart:io' show InternetAddress, InternetAddressType;

import 'package:flutter/foundation.dart';

import '../../../core/constants/split_tunnel_constants.dart';
import '../../../core/storage/key_value_storage.dart';
import '../models/rule_action.dart';
import '../models/rule_type.dart';
import '../models/split_rule.dart';
import '../models/split_tunnel_error.dart';
import '../services/domain_matcher.dart';
import '../services/preset_rule_sets.dart';

/// Колбэк, вызываемый после каждого изменения набора правил.
typedef OnSplitRulesChanged = Future<void> Function();

/// Контроллер Split Tunneling для UI (ChangeNotifier).
class SplitTunnelController extends ChangeNotifier {
  /// Создаёт контроллер.
  ///
  /// [storage] — хранилище для персистентности правил (опционально
  /// для тестов); [onRulesChanged] — колбэк перезагрузки конфига VPN.
  SplitTunnelController({
    KeyValueStorage? storage,
    OnSplitRulesChanged? onRulesChanged,
  })  : _storage = storage,
        _onRulesChanged = onRulesChanged;

  final KeyValueStorage? _storage;
  final OnSplitRulesChanged? _onRulesChanged;

  List<SplitRule> _rules = <SplitRule>[];
  String? _errorMessage;
  SplitTunnelError? _errorCode;

  /// Все правила в порядке применения (иммутабельный список).
  List<SplitRule> get rules => List.unmodifiable(_rules);

  /// Только активные правила.
  List<SplitRule> get activeRules =>
      List.unmodifiable(_rules.where((rule) => rule.enabled));

  /// Есть ли хотя бы одно правило.
  bool get hasRules => _rules.isNotEmpty;

  /// Сообщение об ошибке последней операции (debug-текст).
  String? get errorMessage => _errorMessage;

  /// Код ошибки последней операции (для локализации в UI).
  SplitTunnelError? get errorCode => _errorCode;

  /// Загружает правила из хранилища.
  ///
  /// Битые записи пропускаются, чтобы не ломать запуск приложения.
  Future<void> initialize() async {
    final storage = _storage;
    if (storage == null) return;

    try {
      final raw = await storage.read(key: SplitTunnelConstants.storageKey);
      if (raw == null || raw.isEmpty) return;

      final decoded = jsonDecode(raw) as List<dynamic>;
      _rules = [
        for (final entry in decoded)
          if (entry is Map<String, dynamic>) SplitRule.fromJson(entry),
      ].where((rule) => rule.id.isNotEmpty && rule.pattern.isNotEmpty).toList();
    } catch (e) {
      _setError(SplitTunnelError.loadFailed, 'Не удалось загрузить: $e');
    }
    notifyListeners();
  }

  /// Добавляет пользовательское правило.
  ///
  /// Паттерн нормализуется, дубликаты и переполнение отклоняются
  /// с сообщением в [errorCode].
  Future<void> addRule({
    required RuleType type,
    required String pattern,
    required RuleAction action,
  }) async {
    final error = _validate(type, pattern);
    if (error != null) return _setError(error);

    final rule = SplitRule(
      id: 'user:${DateTime.now().microsecondsSinceEpoch}',
      type: type,
      pattern: _normalizePattern(type, pattern),
      action: action,
    );
    _rules = [..._rules, rule];
    await _commit();
  }

  /// Обновляет существующее правило по идентификатору.
  Future<void> updateRule(
    String id, {
    required RuleType type,
    required String pattern,
    required RuleAction action,
  }) async {
    if (!_rules.any((rule) => rule.id == id)) {
      return _setError(SplitTunnelError.ruleNotFound);
    }

    final error = _validate(type, pattern, ignoreRuleId: id);
    if (error != null) return _setError(error);

    _rules = [
      for (final rule in _rules)
        if (rule.id == id)
          rule.copyWith(
            type: type,
            pattern: _normalizePattern(type, pattern),
            action: action,
          )
        else
          rule,
    ];
    await _commit();
  }

  /// Удаляет правило по идентификатору.
  Future<void> removeRule(String id) async {
    _rules = _rules.where((rule) => rule.id != id).toList();
    await _commit();
  }

  /// Включает или выключает правило.
  Future<void> setRuleEnabled(String id, bool enabled) async {
    _rules = [
      for (final rule in _rules)
        rule.id == id ? rule.copyWith(enabled: enabled) : rule,
    ];
    await _commit();
  }

  /// Применяет пресет: добавляет недостающие правила набора.
  ///
  /// Идемпотентно — повторное применение ничего не дублирует.
  Future<void> applyPreset(String presetId) async {
    final preset = PresetRuleSets.byId(presetId);
    if (preset == null) {
      return _setError(SplitTunnelError.presetUnknown);
    }

    final existingIds = _rules.map((rule) => rule.id).toSet();
    final additions =
        preset.rules.where((rule) => !existingIds.contains(rule.id)).toList();

    // Лимит считается по активным правилам (как в buildRouteRules).
    final activeCount = _rules.where((rule) => rule.enabled).length;
    if (activeCount + additions.length > SplitTunnelConstants.maxInlineRules) {
      return _setError(SplitTunnelError.limitReached);
    }

    _rules = [..._rules, ...additions];
    await _commit();
  }

  /// Удаляет все правила пресета.
  Future<void> removePreset(String presetId) async {
    final preset = PresetRuleSets.byId(presetId);
    if (preset == null) return;

    final presetIds = preset.rules.map((rule) => rule.id).toSet();
    _rules = _rules.where((rule) => !presetIds.contains(rule.id)).toList();
    await _commit();
  }

  /// Полностью ли применён пресет (все правила присутствуют и активны).
  bool isPresetApplied(String presetId) {
    final preset = PresetRuleSets.byId(presetId);
    if (preset == null) return false;
    return preset.rules.every(
      (presetRule) => _rules.any(
        (rule) => rule.id == presetRule.id && rule.enabled,
      ),
    );
  }

  /// Применяет правила провайдера из подписки (ФАЗА 9).
  ///
  /// Идемпотентно: правила с уже известными id не дублируются.
  /// Маппинг контракта → [SplitRule] выполняет
  /// `SubscriptionSplitTunnel.toSplitRules()`.
  Future<void> applyProviderRules(List<SplitRule> rules) async {
    if (rules.isEmpty) {
      return _setError(SplitTunnelError.noProviderRules);
    }

    final existingIds = _rules.map((rule) => rule.id).toSet();
    final additions =
        rules.where((rule) => !existingIds.contains(rule.id)).toList();

    if (additions.isEmpty) {
      _errorMessage = null;
      _errorCode = null;
      notifyListeners();
      return;
    }

    final activeCount = _rules.where((rule) => rule.enabled).length;
    if (activeCount + additions.length > SplitTunnelConstants.maxInlineRules) {
      return _setError(SplitTunnelError.limitReached);
    }

    _rules = [..._rules, ...additions];
    await _commit();
  }

  /// Удаляет все правила (пользовательские и пресетные).
  Future<void> clearAll() async {
    _rules = <SplitRule>[];
    await _commit();
  }

  // --------------------------------------------------------------------------
  // ВНУТРЕННЯЯ ЛОГИКА
  // --------------------------------------------------------------------------

  /// Фиксирует изменение: уведомляет UI, сохраняет, дергает reload.
  Future<void> _commit() async {
    _errorMessage = null;
    _errorCode = null;
    notifyListeners();

    await _persist();

    final callback = _onRulesChanged;
    if (callback == null) return;
    try {
      await callback();
    } catch (e) {
      // Туннель продолжает работать на старых правилах — сообщаем в UI.
      _setError(
        SplitTunnelError.reloadFailed,
        'Правила сохранены, но reload не удался: $e',
      );
    }
  }

  /// Сохраняет правила в хранилище (сбой не прерывает работу UI).
  Future<void> _persist() async {
    final storage = _storage;
    if (storage == null) return;

    try {
      final encoded = jsonEncode([
        for (final rule in _rules) rule.toJson(),
      ]);
      await storage.write(key: SplitTunnelConstants.storageKey, value: encoded);
    } catch (e) {
      _setError(SplitTunnelError.saveFailed, 'Не удалось сохранить: $e');
    }
  }

  /// Валидирует паттерн правила; возвращает код ошибки или null.
  SplitTunnelError? _validate(
    RuleType type,
    String pattern, {
    String? ignoreRuleId,
  }) {
    final value = pattern.trim();

    if (value.length < SplitTunnelConstants.minPatternLength) {
      return SplitTunnelError.patternTooShort;
    }
    if (value.length > SplitTunnelConstants.maxPatternLength) {
      return SplitTunnelError.patternTooLong;
    }

    // Edge-кейс: паттерн вроде «..» нормализуется в пустоту.
    if (type.isDomainBased && DomainMatcher.normalize(value).isEmpty) {
      return SplitTunnelError.patternEmpty;
    }

    // Per-type валидация: мусорный паттерн не должен попадать
    // в конфигурацию sing-box (иначе упадёт весь туннель).
    final typeError = _validateByType(type, value);
    if (typeError != null) return typeError;

    final normalized = _normalizePattern(type, value);
    final duplicate = _rules.any(
      (rule) =>
          rule.id != ignoreRuleId &&
          rule.type == type &&
          rule.pattern == normalized,
    );
    if (duplicate) {
      return SplitTunnelError.duplicate;
    }

    // Лимит считается по активным правилам (как в buildRouteRules).
    final activeCount =
        _rules.where((rule) => rule.id != ignoreRuleId && rule.enabled).length;
    if (activeCount >= SplitTunnelConstants.maxInlineRules) {
      return SplitTunnelError.limitReached;
    }
    return null;
  }

  // --------------------------------------------------------------------------
  // PER-TYPE ВАЛИДАЦИЯ ПАТТЕРНОВ
  // --------------------------------------------------------------------------

  /// Домен: буквы/цифры/дефисы, метки через точку.
  static final RegExp _domainPattern = RegExp(
    r'^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?'
    r'(\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)*$',
  );

  /// Ключевое слово: буквы/цифры/точки/дефисы, начинается с буквы или цифры.
  static final RegExp _keywordPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9.-]*$');

  /// GeoIP-код: 2-8 латинских букв (`ru`, `private`).
  static final RegExp _geoipPattern = RegExp(r'^[A-Za-z]{2,8}$');

  /// Android-пакет: `com.example.app` (минимум две метки).
  static final RegExp _packagePattern =
      RegExp(r'^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*)+$');

  /// Разбирает список значений (для многозначных типов).
  static List<String> _splitValues(String pattern) =>
      pattern.split(RegExp(r'[,\s]+')).where((v) => v.isNotEmpty).toList();

  /// Валидирует паттерн по типу правила; null = корректен.
  static SplitTunnelError? _validateByType(RuleType type, String value) =>
      switch (type) {
        RuleType.domain || RuleType.domainSuffix => _validateDomain(value),
        RuleType.domainKeyword => _validateKeyword(value),
        RuleType.domainRegex => _validateRegex(value),
        RuleType.ipCidr => _validateCidrList(value),
        RuleType.geoip => _validateGeoipList(value),
        RuleType.app => _validatePackageList(value),
      };

  static SplitTunnelError? _validateRegex(String value) {
    try {
      RegExp(value);
      return null;
    } on FormatException {
      return SplitTunnelError.invalidRegex;
    }
  }

  static SplitTunnelError? _validateDomain(String value) {
    if (value.contains('*')) {
      // Wildcard не поддерживается этим типом — нужен Regex.
      return SplitTunnelError.invalidDomain;
    }
    if (!_domainPattern.hasMatch(value)) {
      return SplitTunnelError.invalidDomain;
    }
    return null;
  }

  static SplitTunnelError? _validateKeyword(String value) {
    if (value.contains('*')) {
      return SplitTunnelError.invalidKeyword;
    }
    if (!_keywordPattern.hasMatch(value)) {
      return SplitTunnelError.invalidKeyword;
    }
    return null;
  }

  static SplitTunnelError? _validateGeoipList(String value) {
    for (final part in _splitValues(value)) {
      if (!_geoipPattern.hasMatch(part)) {
        return SplitTunnelError.invalidGeoip;
      }
    }
    return null;
  }

  static SplitTunnelError? _validatePackageList(String value) {
    for (final part in _splitValues(value)) {
      if (!_packagePattern.hasMatch(part)) {
        return SplitTunnelError.invalidPackage;
      }
    }
    return null;
  }

  static SplitTunnelError? _validateCidrList(String value) {
    for (final part in _splitValues(value)) {
      if (_invalidCidrToken(part) != null) {
        return SplitTunnelError.invalidCidr;
      }
    }
    return null;
  }

  /// Проверяет IP или CIDR-токен; возвращает токен, если он некорректен.
  static String? _invalidCidrToken(String token) {
    final parts = token.split('/');
    if (parts.length > 2) return token;

    final address = InternetAddress.tryParse(parts[0]);
    if (address == null) return token;

    if (parts.length == 2) {
      final prefix = int.tryParse(parts[1]);
      final maxPrefix = address.type == InternetAddressType.IPv4 ? 32 : 128;
      if (prefix == null || prefix < 0 || prefix > maxPrefix) {
        return token;
      }
    }
    return null;
  }

  /// Нормализует паттерн под тип правила.
  ///
  /// Домены — канонический вид [DomainMatcher.normalize]; regex и
  /// имена пакетов не меняют регистр (иначе ломаются `[A-Z]`-классы
  /// и Java-конвенция имён пакетов).
  static String _normalizePattern(RuleType type, String pattern) =>
      switch (type) {
        RuleType.domain ||
        RuleType.domainSuffix ||
        RuleType.domainKeyword =>
          DomainMatcher.normalize(pattern),
        RuleType.domainRegex || RuleType.app => pattern.trim(),
        RuleType.ipCidr || RuleType.geoip => pattern.trim().toLowerCase(),
      };

  /// Устанавливает ошибку и уведомляет UI.
  ///
  /// [debugDetails] — детали для логов (без адресов, правило 16).
  void _setError(SplitTunnelError code, [String? debugDetails]) {
    _errorCode = code;
    _errorMessage = debugDetails ?? _debugTextFor(code);
    notifyListeners();
  }

  /// Debug-текст по коду ошибки (логи и тесты; не для UI).
  static String _debugTextFor(SplitTunnelError code) => switch (code) {
        SplitTunnelError.loadFailed => 'Не удалось загрузить правила',
        SplitTunnelError.saveFailed => 'Не удалось сохранить правила',
        SplitTunnelError.ruleNotFound => 'Правило не найдено',
        SplitTunnelError.presetUnknown => 'Неизвестный набор правил',
        SplitTunnelError.noProviderRules => 'В подписке нет применимых правил',
        SplitTunnelError.limitReached =>
          'Достигнут лимит правил (${SplitTunnelConstants.maxInlineRules})',
        SplitTunnelError.patternTooShort => 'Паттерн слишком короткий',
        SplitTunnelError.patternTooLong => 'Паттерн слишком длинный',
        SplitTunnelError.patternEmpty => 'Паттерн пуст после нормализации',
        SplitTunnelError.duplicate => 'Такое правило уже существует',
        SplitTunnelError.invalidRegex => 'Некорректное регулярное выражение',
        SplitTunnelError.invalidDomain => 'Ожидается домен',
        SplitTunnelError.invalidKeyword => 'Некорректное ключевое слово',
        SplitTunnelError.invalidGeoip => 'Ожидается GeoIP-код',
        SplitTunnelError.invalidPackage => 'Ожидается имя пакета',
        SplitTunnelError.invalidCidr => 'Некорректный IP/CIDR',
        SplitTunnelError.reloadFailed =>
          'Правила сохранены, но применить их к VPN не удалось',
      };
}
