/// Сервис чтения/записи настроек приложения.
///
/// Обёртка над [KeyValueStorage]: хранит режим интерфейса
/// ([UiExperienceMode]) и сообщает, выбирал ли пользователь режим
/// при первом запуске.
library;

import 'package:fetu/core/storage/key_value_storage.dart';

import '../../../core/constants/settings_constants.dart';
import '../models/ui_experience_mode.dart';

/// Персистентное состояние настроек интерфейса.
class SettingsService {
  /// Создаёт сервис.
  ///
  /// [storage] — хранилище (опционально для тестов).
  SettingsService({KeyValueStorage? storage}) : _storage = storage;

  final KeyValueStorage? _storage;

  /// Загружает выбранный режим; null — режим ещё не выбран.
  ///
  /// Повреждённое значение трактуется как «не выбран»,
  /// чтобы не ломать запуск приложения.
  Future<UiExperienceMode?> loadMode() async {
    final storage = _storage;
    if (storage == null) return null;

    try {
      return UiExperienceMode.fromStorage(
        await storage.read(key: SettingsConstants.uiModeStorageKey),
      );
    } catch (_) {
      // Битая запись — считаем режим невыбранным; пользователь
      // увидит экран выбора и запишет корректное значение.
      return null;
    }
  }

  /// Сохраняет выбранный режим.
  Future<void> saveMode(UiExperienceMode mode) async {
    final storage = _storage;
    if (storage == null) return;
    await storage.write(
      key: SettingsConstants.uiModeStorageKey,
      value: mode.storageName,
    );
  }
}
