/// Константы фичи настроек (AGENTS.md, правило 12: без magic numbers).
abstract final class SettingsConstants {
  /// Ключ хранения выбранного режима интерфейса.
  static const String uiModeStorageKey = 'fetu.settings.ui_experience_mode';

  /// Значение режима «простой» в хранилище.
  static const String simpleModeValue = 'simple';

  /// Значение режима «расширенный» в хранилище.
  static const String advancedModeValue = 'advanced';

  /// Поле secure-storage для ключа проверки подписи vpn://.
  static const String verifyKeyField = 'subscription_verify_key';

  /// Поле secure-storage для ключа расшифровки vpn://.
  static const String decryptKeyField = 'subscription_decrypt_key';

  /// Ожидаемая длина ключа AES-256 / Ed25519 в байтах.
  static const int subscriptionKeyLengthBytes = 32;

  /// Минимальная длина HMAC-ключа подписи в байтах.
  static const int hmacKeyMinLengthBytes = 16;
}
