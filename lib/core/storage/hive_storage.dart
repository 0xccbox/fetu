import 'package:fetu/core/storage/key_value_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Реализация [KeyValueStorage] на основе Hive.
///
/// Использует Hive как быстрое и надёжное локальное хранилище без шифрования.
/// Для критически важных данных (пароли, ключи) используй [FlutterSecureStorage].
final class HiveStorage implements KeyValueStorage {
  late final Box<String> _box;

  /// Инициализирует Hive и открывает основной бокс для хранения настроек.
  ///
  /// При повреждении локального файла бокса пересоздаёт его, чтобы не
  /// блокировать запуск приложения.
  Future<void> init() async {
    await Hive.initFlutter();
    try {
      _box = await Hive.openBox<String>('app_storage');
    } catch (_) {
      await Hive.deleteBoxFromDisk('app_storage');
      _box = await Hive.openBox<String>('app_storage');
    }
  }

  @override
  Future<void> write({required String key, required String value}) async {
    await _box.put(key, value);
  }

  @override
  Future<String?> read({required String key}) async {
    return _box.get(key);
  }

  @override
  Future<void> delete({required String key}) async {
    await _box.delete(key);
  }

  /// Перезаписывает файл без предыдущих версий удалённых записей.
  Future<void> compact() => _box.compact();

  /// Полностью очищает хранилище (для тестирования или сброса настроек).
  Future<void> clear() async {
    await _box.clear();
  }

  /// Закрывает бокс при завершении работы приложения.
  Future<void> close() async {
    await _box.close();
  }
}
