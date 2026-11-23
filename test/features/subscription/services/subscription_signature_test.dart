import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'package:fetu/features/subscription/services/subscription_signature.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SubscriptionSignatureVerifier.verifyHmac', () {
    final key = List<int>.generate(32, (i) => i + 1);
    final message = utf8.encode('subscription-data');

    test('валидная подпись принимается', () {
      final mac = crypto.Hmac(crypto.sha256, key).convert(message);

      expect(
        SubscriptionSignatureVerifier.verifyHmac(
          message: message,
          signature: mac.bytes,
          key: key,
        ),
        isTrue,
      );
    });

    test('подделанная подпись отклоняется', () {
      final mac = crypto.Hmac(crypto.sha256, key).convert(message);
      final forged = [...mac.bytes]..[0] = mac.bytes[0] ^ 0xFF;

      expect(
        SubscriptionSignatureVerifier.verifyHmac(
          message: message,
          signature: forged,
          key: key,
        ),
        isFalse,
      );
    });

    test('чужой ключ отклоняется', () {
      final mac = crypto.Hmac(crypto.sha256, key).convert(message);

      expect(
        SubscriptionSignatureVerifier.verifyHmac(
          message: message,
          signature: mac.bytes,
          key: List<int>.generate(32, (i) => i + 2),
        ),
        isFalse,
      );
    });
  });

  group('SubscriptionSignatureVerifier.verifyEd25519', () {
    final message = utf8.encode('ed25519-payload');

    test('валидная подпись принимается', () async {
      final algorithm = Ed25519();
      final keyPair = await algorithm.newKeyPair();
      final signature = await algorithm.sign(
        message,
        keyPair: keyPair,
      );
      final publicKey = await keyPair.extractPublicKey();

      expect(
        await SubscriptionSignatureVerifier.verifyEd25519(
          message: message,
          signature: signature.bytes,
          publicKey: publicKey.bytes,
        ),
        isTrue,
      );
    });

    test('подделанная подпись отклоняется', () async {
      final algorithm = Ed25519();
      final keyPair = await algorithm.newKeyPair();
      final signature = await algorithm.sign(message, keyPair: keyPair);
      final publicKey = await keyPair.extractPublicKey();
      final forged = [...signature.bytes]..[5] ^= 0x01;

      expect(
        await SubscriptionSignatureVerifier.verifyEd25519(
          message: message,
          signature: forged,
          publicKey: publicKey.bytes,
        ),
        isFalse,
      );
    });

    test('некорректные длины безопасно отклоняются', () async {
      expect(
        await SubscriptionSignatureVerifier.verifyEd25519(
          message: message,
          signature: [1, 2, 3],
          publicKey: [4, 5],
        ),
        isFalse,
      );
    });
  });

  group('constantTimeEquals', () {
    test('равные и неравные последовательности', () {
      expect(
        SubscriptionSignatureVerifier.constantTimeEquals(
          [1, 2, 3],
          [1, 2, 3],
        ),
        isTrue,
      );
      expect(
        SubscriptionSignatureVerifier.constantTimeEquals(
          [1, 2, 3],
          [1, 2, 4],
        ),
        isFalse,
      );
      expect(
        SubscriptionSignatureVerifier.constantTimeEquals(
          [1, 2],
          [1, 2, 3],
        ),
        isFalse,
      );
    });
  });
}
