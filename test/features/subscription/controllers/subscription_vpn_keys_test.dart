import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:fetu/features/settings/models/subscription_keys.dart';
import 'package:fetu/features/subscription/controllers/subscription_controller.dart';
import 'package:fetu/features/subscription/models/subscription_error.dart';
import 'package:fetu/features/subscription/services/vpn_subscription_url.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/subscription_fixtures.dart';
import '../../../helpers/test_storage.dart';

String b64(List<int> bytes) => base64Url.encode(bytes);

void main() {
  // Ключи фикстуры (как в subscription_parser_test).
  final hmacKey = List<int>.generate(32, (i) => i * 7 + 1);
  final aesKey = List<int>.generate(32, (i) => 255 - i);

  /// vpn://-подписка, подписанная HMAC (по base64-строке data).
  String buildHmacVpnUrl({List<int>? signWith}) {
    final json = asJson(minimalSubscription());
    final data = VpnSubscriptionUrl.encryptData(plaintext: json, key: aesKey);
    final key = signWith ?? hmacKey;
    final mac = crypto.Hmac(crypto.sha256, key).convert(utf8.encode(data));
    return 'vpn://subscribe?data=$data&sig=${base64Url.encode(mac.bytes)}';
  }

  group('SubscriptionController: vpn:// с ключами из настроек', () {
    test('Вставленный HMAC-ваучер разбирается без HTTP', () async {
      var fetched = false;
      final controller = SubscriptionController(
        storage: TestStorage(),
        fetcher: (_) async {
          fetched = true;
          return buildHmacVpnUrl();
        },
        keysProvider: () async => SubscriptionKeys(
          verifyKey: 'hmac:${b64(hmacKey)}',
          decryptKey: b64(aesKey),
        ),
      );

      await controller.addFromUrl(buildHmacVpnUrl());

      expect(fetched, isFalse);
      expect(controller.subscriptionUrl, isNull);
      expect(controller.errorCode, isNull);
      expect(controller.subscription, isNotNull);
      expect(controller.subscription!.name, 'Test VPN');
      expect(controller.nodes, hasLength(1));
    });

    test('Ed25519-ключ не используется как HMAC-секрет при отказе', () async {
      final controller = SubscriptionController(
        keysProvider: () async => SubscriptionKeys(
          verifyKey: b64(hmacKey),
          decryptKey: b64(aesKey),
        ),
      );
      await controller.addFromUrl(buildHmacVpnUrl());
      expect(controller.errorCode, SubscriptionError.signature);
      expect(controller.subscription, isNull);
    });

    test('неверный ключ подписи → код signature', () async {
      final controller = SubscriptionController(
        storage: TestStorage(),
        fetcher: (_) async => '',
        keysProvider: () async => SubscriptionKeys(
          verifyKey: 'hmac:${b64(List<int>.generate(31, (i) => i))}',
          decryptKey: b64(aesKey),
        ),
      );

      await controller.addFromRaw(
        buildHmacVpnUrl(signWith: List<int>.generate(32, (i) => i + 3)),
      );

      expect(controller.errorCode, SubscriptionError.signature);
      expect(controller.subscription, isNull);
    });

    test('ключи не заданы → код noKeys', () async {
      final controller = SubscriptionController(
        storage: TestStorage(),
        fetcher: (_) async => '',
        keysProvider: () async => const SubscriptionKeys(),
      );

      await controller.addFromRaw(buildHmacVpnUrl());

      expect(controller.errorCode, SubscriptionError.noKeys);
    });

    test('мусорный ключ (не Base64) → код invalidKey', () async {
      final controller = SubscriptionController(
        storage: TestStorage(),
        fetcher: (_) async => '',
        keysProvider: () async => const SubscriptionKeys(
          verifyKey: '!!!не-base64',
          decryptKey: '====',
        ),
      );

      await controller.addFromRaw(buildHmacVpnUrl());

      expect(controller.errorCode, SubscriptionError.invalidKey);
    });

    test('ключ расшифровки не 32 байта → код invalidKey', () async {
      final controller = SubscriptionController(
        storage: TestStorage(),
        fetcher: (_) async => '',
        keysProvider: () async => SubscriptionKeys(
          verifyKey: 'hmac:${b64(hmacKey)}',
          decryptKey: b64(List<int>.generate(16, (i) => i)),
        ),
      );

      await controller.addFromRaw(buildHmacVpnUrl());

      expect(controller.errorCode, SubscriptionError.invalidKey);
    });

    test('без провайдера ключей → код noKeys', () async {
      final controller = SubscriptionController(
        storage: TestStorage(),
        fetcher: (_) async => '',
      );

      await controller.addFromRaw(buildHmacVpnUrl());

      expect(controller.errorCode, SubscriptionError.noKeys);
    });

    test('plain JSON по-прежнему работает без ключей', () async {
      final controller = SubscriptionController(
        storage: TestStorage(),
        fetcher: (_) async => '',
        keysProvider: () async => const SubscriptionKeys(),
      );

      await controller.addFromRaw(asJson(minimalSubscription()));

      expect(controller.errorCode, isNull);
      expect(controller.subscription!.name, 'Test VPN');
    });
  });
}
