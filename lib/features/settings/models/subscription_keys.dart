/// Пара ключей vpn://-подписки (immutable, AGENTS.md правило 10).
library;

import 'package:flutter/foundation.dart';

/// Ключи подписки: Base64-строки из secure-storage.
@immutable
class SubscriptionKeys {
  /// Создаёт пару ключей.
  const SubscriptionKeys({this.verifyKey, this.decryptKey});

  /// Base64 публичного ключа Ed25519 или `hmac:` + Base64 секрета HMAC.
  final String? verifyKey;

  /// Ключ расшифровки AES-256, Base64.
  final String? decryptKey;

  static const _hmacPrefix = 'hmac:';

  /// HMAC используется только при явном выборе этого типа ключа.
  bool get usesHmac => verifyKey?.trim().startsWith(_hmacPrefix) ?? false;

  /// Проверочный ключ без необязательного префикса алгоритма.
  String? get verifyKeyMaterial {
    final key = verifyKey?.trim();
    return usesHmac ? key!.substring(_hmacPrefix.length).trim() : key;
  }

  /// Оба ключа пусты.
  bool get isEmpty =>
      (verifyKey == null || verifyKey!.isEmpty) &&
      (decryptKey == null || decryptKey!.isEmpty);
}
