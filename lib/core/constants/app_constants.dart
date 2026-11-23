/// Глобальные константы приложения Fetu.
abstract final class AppConstants {
  /// Отображаемое имя приложения по умолчанию.
  static const String appName = 'Fetu';

  /// Версия приложения для UI и диагностического отчёта.
  static const String appVersion = '1.0.0-mvp';

  /// Текущая поддерживаемая версия схемы JSON-подписки.
  static const int subscriptionSchemaVersion = 2;

  /// Максимальное число инлайн-правил маршрутизации до выноса в `.srs`.
  static const int maxInlineRoutingRules = 500;
}
