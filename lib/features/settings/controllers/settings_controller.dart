/// Контроллер настроек приложения для UI (ChangeNotifier).
///
/// Управляет режимом интерфейса ([UiExperienceMode], AGENTS.md
/// правило 33) и ключами vpn://-подписок. Экран выбора режима при
/// первом запуске показывается, пока режим не сохранён.
library;

import 'package:flutter/foundation.dart';

import '../models/subscription_keys.dart';
import '../models/ui_experience_mode.dart';
import '../services/settings_service.dart';
import '../services/subscription_key_store.dart';

/// Контроллер настроек.
class SettingsController extends ChangeNotifier {
  /// Создаёт контроллер.
  ///
  /// [service] — персистентность режима; [keyStore] — secure-хранилище
  /// ключей подписки (опционально для тестов).
  SettingsController({
    required SettingsService service,
    SubscriptionKeyStore? keyStore,
  })  : _service = service,
        _keyStore = keyStore;

  final SettingsService _service;
  final SubscriptionKeyStore? _keyStore;

  UiExperienceMode? _mode;
  String? _errorMessage;

  /// Загружает сохранённый режим при старте приложения.
  Future<void> initialize() async {
    _mode = await _service.loadMode();
    notifyListeners();
  }

  /// Текущий режим (до выбора — [UiExperienceMode.simple]).
  UiExperienceMode get mode => _mode ?? UiExperienceMode.simple;

  /// Выбирал ли пользователь режим (false — показать экран выбора).
  bool get isModeSelected => _mode != null;

  /// Сообщение об ошибке последней операции (debug-текст).
  String? get errorMessage => _errorMessage;

  /// Выбирает и сохраняет режим (первый запуск или настройки).
  Future<void> setMode(UiExperienceMode mode) async {
    _errorMessage = null;
    _mode = mode;
    notifyListeners();
    try {
      await _service.saveMode(mode);
    } catch (e) {
      _errorMessage = 'Не удалось сохранить режим: $e';
      notifyListeners();
    }
  }

  /// Загружает ключи подписки из secure-storage.
  Future<SubscriptionKeys> loadKeys() async {
    final store = _keyStore;
    if (store == null) return const SubscriptionKeys();
    return store.load();
  }

  /// Сохраняет ключи подписки.
  ///
  /// Returns: true при успехе; false — ключи некорректны
  /// (детали в [errorMessage]).
  Future<bool> saveKeys(SubscriptionKeys keys) async {
    _errorMessage = null;
    final store = _keyStore;
    if (store == null) return true;

    final error = _validateKeys(keys);
    if (error != null) {
      _errorMessage = error;
      notifyListeners();
      return false;
    }

    try {
      await store.save(keys);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Не удалось сохранить ключи: $e';
      notifyListeners();
      return false;
    }
  }

  /// Удаляет ключи подписки.
  Future<void> clearKeys() async {
    _errorMessage = null;
    final store = _keyStore;
    if (store == null) return;
    try {
      await store.clear();
    } catch (e) {
      _errorMessage = 'Не удалось удалить ключи: $e';
    }
    notifyListeners();
  }

  /// Проверка: ключи должны быть пустыми или корректным Base64,
  /// который декодируется (длина проверяется при использовании).
  String? _validateKeys(SubscriptionKeys keys) {
    if (keys.usesHmac && (keys.verifyKeyMaterial?.isEmpty ?? true)) {
      return 'После hmac: нужен ключ в Base64';
    }
    for (final value in [keys.verifyKeyMaterial, keys.decryptKey]) {
      final key = value?.trim();
      if (key == null || key.isEmpty) continue;
      if (!base64Pattern.hasMatch(key)) {
        return 'Ключ должен быть корректным Base64';
      }
    }
    return null;
  }

  static final RegExp base64Pattern = RegExp(
    r'^[A-Za-z0-9+/=_-]+$',
  );
}
