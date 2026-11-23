/// Разбор и расшифровка `vpn://subscribe?data=…&sig=…`-URL.
///
/// Формат (см. `docs/reference/ФОРМАТ_API_ПОДПИСОК.md`):
/// `data = Base64Url(nonce(12 байт) + AES-256-GCM(JSON))`,
/// `sig = Base64Url(подпись)`.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:meta/meta.dart';

/// Исключение разбора/расшифровки vpn://-подписки.
class VpnSubscriptionUrlException implements Exception {
  /// Сообщение об ошибке.
  final String message;

  const VpnSubscriptionUrlException(this.message);

  @override
  String toString() => 'VpnSubscriptionUrlException: $message';
}

/// Payload vpn://-URL: зашифрованные данные и подпись.
typedef VpnSubscriptionPayload = ({String data, String sig});

/// Утилитарный класс для vpn://-схемы подписок.
class VpnSubscriptionUrl {
  const VpnSubscriptionUrl._();

  /// Схема URL подписок.
  static const String scheme = 'vpn://';

  /// Хост подписочных URL (`vpn://subscribe?…`).
  static const String host = 'subscribe';

  /// Длина nonce AES-GCM.
  static const int nonceLengthBytes = 12;

  /// Управляющие и невидимые символы (включая NUL `\u0000`), которые могут
  /// попасть при копировании URL из буфера обмена.
  static final RegExp controlCharsPattern = RegExp(
    r'[\u0000-\u001F\u007F\u200B-\u200F\u202A-\u202E\u2060\uFEFF]',
  );

  /// Очищает URL подписки от NUL-байтов, управляющих/невидимых символов и
  /// крайних пробелов.
  static String sanitizeUrl(String url) =>
      url.replaceAll(controlCharsPattern, '').trim();

  /// Разбирает vpn://-URL на компоненты.
  ///
  /// Returns: null если URL не является подписочной ссылкой.
  static VpnSubscriptionPayload? parse(String url) {
    final trimmed = sanitizeUrl(url);
    if (!trimmed.toLowerCase().startsWith(scheme)) return null;

    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host.toLowerCase() != host) return null;

    final data = uri.queryParameters['data'];
    final sig = uri.queryParameters['sig'];
    if (data == null || data.isEmpty || sig == null || sig.isEmpty) {
      return null;
    }
    return (data: data, sig: sig);
  }

  /// Гибкое декодирование Base64 (urlsafe и стандартный, с паддингом и без).
  static Uint8List decodeBase64(String encoded) {
    final normalized = encoded.replaceAll(' ', '');
    final candidates = [
      normalized,
      normalized.replaceAll('-', '+').replaceAll('_', '/'),
    ];
    for (final candidate in candidates) {
      try {
        return base64Decode(_withPadding(candidate));
      } on FormatException {
        continue;
      }
    }
    throw const VpnSubscriptionUrlException('Некорректный Base64');
  }

  static String _withPadding(String value) {
    final remainder = value.length % 4;
    if (remainder == 0) return value;
    return value + '=' * (4 - remainder);
  }

  /// Расшифровывает `data` (base64(nonce + ciphertext)) AES-256-GCM.
  ///
  /// [key] — 32 байта shared secret.
  ///
  /// Returns: расшифрованный JSON подписки.
  /// Throws: [VpnSubscriptionUrlException] при ошибке расшифровки.
  static Future<String> decryptData({
    required String dataBase64,
    required List<int> key,
  }) async {
    if (key.length != 32) {
      throw const VpnSubscriptionUrlException(
        'Ключ расшифровки должен быть 32 байта (AES-256)',
      );
    }

    try {
      final raw = decodeBase64(dataBase64);
      if (raw.length <= nonceLengthBytes) {
        throw const VpnSubscriptionUrlException('Данные слишком короткие');
      }

      final nonce = raw.sublist(0, nonceLengthBytes);
      final ciphertext = raw.sublist(nonceLengthBytes);

      final encrypter = encrypt.Encrypter(
        encrypt.AES(
          encrypt.Key(Uint8List.fromList(key)),
          mode: encrypt.AESMode.gcm,
        ),
      );
      final decrypted = encrypter.decryptBytes(
        encrypt.Encrypted(Uint8List.fromList(ciphertext)),
        iv: encrypt.IV(Uint8List.fromList(nonce)),
      );
      return utf8.decode(decrypted);
    } on VpnSubscriptionUrlException {
      rethrow;
    } catch (e) {
      throw VpnSubscriptionUrlException('Не удалось расшифровать: $e');
    }
  }

  /// Шифрует JSON подписки в формат `data` (только для тестов).
  @visibleForTesting
  static String encryptData({
    required String plaintext,
    required List<int> key,
  }) {
    final nonce = encrypt.IV.fromSecureRandom(nonceLengthBytes);
    final encrypter = encrypt.Encrypter(
      encrypt.AES(
        encrypt.Key(Uint8List.fromList(key)),
        mode: encrypt.AESMode.gcm,
      ),
    );
    final encrypted = encrypter.encryptBytes(
      utf8.encode(plaintext),
      iv: nonce,
    );
    final combined = BytesBuilder()
      ..add(nonce.bytes)
      ..add(encrypted.bytes);
    return base64Url.encode(combined.toBytes());
  }
}
