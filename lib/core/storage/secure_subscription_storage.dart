import 'package:flutter/foundation.dart';

import 'key_value_storage.dart';

/// Хранилище активной подписки, включая пароли, UUID и URL обновления.
/// Переносит старую запись из обычного хранилища в защищённое.
final class SecureSubscriptionStorage implements KeyValueStorage {
  /// [secure] использует те же платформенные настройки, что и хранилище ключей.
  /// [compactLegacy] переписывает файл без удалённых записей после миграции.
  SecureSubscriptionStorage({
    required KeyValueStorage legacy,
    required KeyValueStorage secure,
    Future<void> Function()? compactLegacy,
  })  : _legacy = legacy,
        _secure = secure,
        _compactLegacy = compactLegacy;

  final KeyValueStorage _legacy;
  final KeyValueStorage _secure;
  final Future<void> Function()? _compactLegacy;

  @override
  Future<String?> read({required String key}) async {
    final current = await _secure.read(key: key);
    if (current != null) {
      // Повторяем компактацию даже после ранее удалённого ключа: очистка
      // файла могла прерваться между удалением и завершением компактации.
      await _cleanUpMigratedValue(key, compactOnRead: true);
      return current;
    }
    final previous = await _legacy.read(key: key);
    if (previous == null) return null;
    await write(key: key, value: previous);
    return previous;
  }

  @override
  Future<void> write({required String key, required String value}) async {
    await _secure.write(key: key, value: value);
    // Не удаляем последнюю копию, пока защищённая запись не удалась.
    await _cleanUpMigratedValue(key);
  }

  @override
  Future<void> delete({required String key}) async {
    // Сначала убираем старую копию, иначе она может восстановиться при чтении.
    final removed = await _deleteLegacy(key);
    await _secure.delete(key: key);
    if (removed) await _compactLegacy?.call();
  }

  Future<void> _cleanUpMigratedValue(
    String key, {
    bool compactOnRead = false,
  }) async {
    try {
      final removed = await _deleteLegacy(key);
      if (removed || compactOnRead) await _compactLegacy?.call();
    } catch (e) {
      // Защищённая запись уже есть. Не блокируем чтение из-за сбоя очистки.
      if (kDebugMode) {
        debugPrint(
          '[SubscriptionStorage] legacy cleanup failed: ${e.runtimeType}',
        );
      }
    }
  }

  Future<bool> _deleteLegacy(String key) async {
    if (await _legacy.read(key: key) == null) return false;
    await _legacy.delete(key: key);
    return true;
  }
}
