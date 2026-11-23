/// Контроллер темы приложения.
///
/// Управляет переключением между светлой и тёмной темой,
/// сохраняет выбор пользователя в локальное хранилище.
library;

import 'package:flutter/material.dart';
import '../../core/storage/key_value_storage.dart';

/// Режим темы приложения.
enum AppThemeMode {
  /// Светлая тема
  light,

  /// Тёмная тема (по умолчанию)
  dark,

  /// Автоматическое переключение (следует за системной темой)
  system,
}

/// Контроллер управления темой приложения.
///
/// Использует [ChangeNotifier] для уведомления UI об изменениях.
/// Сохраняет выбор пользователя через [KeyValueStorage].
class ThemeController extends ChangeNotifier {
  final KeyValueStorage _storage;

  /// Ключ для хранения выбранной темы
  static const String _themeKey = 'app_theme_mode';

  /// Текущий режим темы
  AppThemeMode _themeMode = AppThemeMode.dark;

  ThemeController(this._storage);

  /// Получить текущий режим темы
  AppThemeMode get themeMode => _themeMode;

  /// Получить Flutter ThemeMode для MaterialApp
  ThemeMode get flutterThemeMode {
    switch (_themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  /// Инициализировать контроллер темы (загрузить сохранённую тему).
  ///
  /// Вызывается при запуске приложения в main.dart.
  Future<void> initialize() async {
    final savedTheme = await _storage.read(key: _themeKey);

    if (savedTheme != null) {
      _themeMode = _parseThemeMode(savedTheme);
    } else {
      // По умолчанию — тёмная тема
      _themeMode = AppThemeMode.dark;
    }

    notifyListeners();
  }

  /// Изменить тему приложения.
  ///
  /// [mode] — новый режим темы.
  /// Сохраняет выбор в локальное хранилище и уведомляет слушателей.
  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    await _storage.write(key: _themeKey, value: mode.name);
    notifyListeners();
  }

  /// Переключить тему (dark ↔ light).
  ///
  /// Если текущая тема system, переключается на dark.
  Future<void> toggleTheme() async {
    final newMode = _themeMode == AppThemeMode.light
        ? AppThemeMode.dark
        : AppThemeMode.light;

    await setThemeMode(newMode);
  }

  /// Парсинг строкового значения в AppThemeMode
  AppThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      case 'system':
        return AppThemeMode.system;
      default:
        return AppThemeMode.dark;
    }
  }

  /// Проверить, является ли текущая тема тёмной.
  ///
  /// Учитывает системную тему, если выбран режим system.
  bool isDark(BuildContext context) {
    if (_themeMode == AppThemeMode.system) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return _themeMode == AppThemeMode.dark;
  }
}
