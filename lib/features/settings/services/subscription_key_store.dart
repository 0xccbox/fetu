/// Безопасное хранилище ключей vpn://-подписок (AGENTS.md, правило 17).
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/constants/settings_constants.dart';
import '../../../core/storage/serialized_secure_storage.dart';
import '../models/subscription_keys.dart';

/// Репозиторий ключей проверки и расшифровки ваучера.
class SubscriptionKeyStore {
  /// [serialized] — общее хранилище с конфигурацией подписки;
  /// [storage] позволяет подменить платформенный плагин в тестах.
  SubscriptionKeyStore({
    FlutterSecureStorage? storage,
    SerializedSecureStorage? serialized,
  }) : _storage = serialized ??
            SerializedSecureStorage(storage ?? const FlutterSecureStorage());

  final SerializedSecureStorage _storage;

  /// Загружает пару ключей; при отказе плагина возвращает пустую пару.
  Future<SubscriptionKeys> load() async {
    try {
      return await _storage.run(
        (secure) async => SubscriptionKeys(
          verifyKey: await secure.read(key: SettingsConstants.verifyKeyField),
          decryptKey: await secure.read(key: SettingsConstants.decryptKeyField),
        ),
      );
    } catch (_) {
      return const SubscriptionKeys();
    }
  }

  /// Сохраняет или удаляет оба ключа в одном проходе очереди.
  Future<void> save(SubscriptionKeys keys) => _storage.run((secure) async {
        await _write(secure, SettingsConstants.verifyKeyField, keys.verifyKey);
        await _write(
          secure,
          SettingsConstants.decryptKeyField,
          keys.decryptKey,
        );
      });

  /// Удаляет оба ключа.
  Future<void> clear() => save(const SubscriptionKeys());

  Future<void> _write(
    FlutterSecureStorage secure,
    String field,
    String? value,
  ) async {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      await secure.delete(key: field);
    } else {
      await secure.write(key: field, value: normalized);
    }
  }
}
