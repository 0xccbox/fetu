import 'package:fetu/core/storage/key_value_storage.dart';

/// Простая in-memory реализация [KeyValueStorage] для тестов.
///
/// Не требует инициализации Hive или нативных плагинов.
class TestStorage implements KeyValueStorage {
  final Map<String, String> _storage = {};

  /// Инициализация (не требуется для in-memory хранилища)
  Future<void> init() async {
    // Нет реальной инициализации для тестов
  }

  @override
  Future<void> write({required String key, required String value}) async {
    _storage[key] = value;
  }

  @override
  Future<String?> read({required String key}) async {
    return _storage[key];
  }

  @override
  Future<void> delete({required String key}) async {
    _storage.remove(key);
  }

  /// Очистить всё хранилище (не в интерфейсе, дополнительный метод)
  Future<void> clear() async {
    _storage.clear();
  }

  /// Закрыть хранилище (не в интерфейсе, дополнительный метод)
  Future<void> close() async {
    _storage.clear();
  }
}
