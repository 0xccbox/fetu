/// Проверка криптографических подписей подписок.
///
/// Поддерживает HMAC-SHA256 (симметричный ключ) и Ed25519
/// (асимметричный, `signature_public_key` из блока `update`).
library;

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';

/// Утилитарный верификатор подписей (только статические методы).
class SubscriptionSignatureVerifier {
  const SubscriptionSignatureVerifier._();

  /// Проверяет подпись HMAC-SHA256.
  ///
  /// [message] — подписанные байты (обычно поле `data` из vpn://-URL);
  /// [signature] — байты подписи; [key] — симметричный ключ.
  ///
  /// Returns: true если подпись валидна.
  static bool verifyHmac({
    required List<int> message,
    required List<int> signature,
    required List<int> key,
  }) {
    final digest = crypto.Hmac(crypto.sha256, key).convert(message);
    return constantTimeEquals(digest.bytes, signature);
  }

  /// Проверяет подпись Ed25519.
  ///
  /// [message] — подписанные байты; [signature] — 64 байта подписи;
  /// [publicKey] — 32 байта публичного ключа провайдера.
  ///
  /// Некорректные длины/ключи безопасно возвращают `false`.
  ///
  /// Returns: true если подпись валидна.
  static Future<bool> verifyEd25519({
    required List<int> message,
    required List<int> signature,
    required List<int> publicKey,
  }) async {
    try {
      final algorithm = Ed25519();
      final key = SimplePublicKey(
        publicKey,
        type: KeyPairType.ed25519,
      );
      return await algorithm.verify(
        message,
        signature: Signature(signature, publicKey: key),
      );
    } catch (_) {
      return false;
    }
  }

  /// Сравнение байтов за постоянное время (защита от timing-атак).
  static bool constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
