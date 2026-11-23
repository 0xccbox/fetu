/// Абстрактный контракт локального ключ-значение хранилища.
abstract interface class KeyValueStorage {
  /// Записывает строковое значение [value] по ключу [key].
  Future<void> write({required String key, required String value});

  /// Читает строковое значение по ключу [key].
  Future<String?> read({required String key});

  /// Удаляет запись по ключу [key].
  Future<void> delete({required String key});
}
