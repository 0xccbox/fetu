import 'dart:convert';
import 'dart:typed_data';

import 'package:fetu/features/subscription/services/vpn_subscription_url.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/subscription_fixtures.dart';

void main() {
  final aesKey = List<int>.generate(32, (i) => (i * 13) % 256);

  group('VpnSubscriptionUrl.parse', () {
    test('разбирает корректный URL', () {
      final payload = VpnSubscriptionUrl.parse(
        'vpn://subscribe?data=QUJD&sig=REVGRw==',
      );

      expect(payload, isNotNull);
      expect(payload!.data, 'QUJD');
      expect(payload.sig, 'REVGRw==');
    });

    test('игнорирует посторонние URL', () {
      expect(
        VpnSubscriptionUrl.parse('https://example.com/sub?data=x'),
        isNull,
      );
      expect(VpnSubscriptionUrl.parse('vpn://other?data=x&sig=y'), isNull);
      expect(VpnSubscriptionUrl.parse('vpn://subscribe?only=data'), isNull);
      expect(VpnSubscriptionUrl.parse('  '), isNull);
    });

    test('sanitizeUrl удаляет NUL-байты, управляющие и невидимые символы', () {
      expect(
        VpnSubscriptionUrl.sanitizeUrl(
          '  https://sub.example.com/token123\u0000\u0000\r\n\u200B\uFEFF  ',
        ),
        'https://sub.example.com/token123',
      );
      expect(
        VpnSubscriptionUrl.parse(
          'vpn://subscribe?data=QUJD&sig=REVGRw==\u0000\u0000',
        ),
        isNotNull,
      );
    });
  });

  group('VpnSubscriptionUrl decrypt/encrypt', () {
    test('round-trip: шифрование → расшифровка', () async {
      final plaintext = asJson(minimalSubscription());
      final data =
          VpnSubscriptionUrl.encryptData(plaintext: plaintext, key: aesKey);

      final decrypted = await VpnSubscriptionUrl.decryptData(
        dataBase64: data,
        key: aesKey,
      );

      expect(decrypted, plaintext);
    });

    test('повреждённые данные дают понятное исключение', () async {
      final data = VpnSubscriptionUrl.encryptData(
        plaintext: 'hello',
        key: aesKey,
      );
      final bytes = VpnSubscriptionUrl.decodeBase64(data);
      bytes[bytes.length - 1] ^= 0xFF;

      await expectLater(
        VpnSubscriptionUrl.decryptData(
          dataBase64: base64Url.encode(bytes),
          key: aesKey,
        ),
        throwsA(isA<VpnSubscriptionUrlException>()),
      );
    });

    test('неверный ключ отклоняется', () async {
      final data = VpnSubscriptionUrl.encryptData(
        plaintext: 'hello',
        key: aesKey,
      );

      await expectLater(
        VpnSubscriptionUrl.decryptData(
          dataBase64: data,
          key: List<int>.generate(32, (i) => i),
        ),
        throwsA(isA<VpnSubscriptionUrlException>()),
      );
    });

    test('ключ не 32 байта отклоняется сразу', () async {
      await expectLater(
        VpnSubscriptionUrl.decryptData(
          dataBase64: 'QUJD',
          key: [1, 2, 3],
        ),
        throwsA(isA<VpnSubscriptionUrlException>()),
      );
    });
  });

  group('VpnSubscriptionUrl.decodeBase64', () {
    test('понимает urlsafe и стандартный base64 с паддингом и без', () {
      final bytes = Uint8List.fromList([1, 2, 250, 251, 252, 253, 254]);

      final standard = base64.encode(bytes);
      final urlsafePadded = base64Url.encode(bytes);
      final urlsafeNoPad = urlsafePadded.replaceAll('=', '');

      expect(VpnSubscriptionUrl.decodeBase64(standard), bytes);
      expect(VpnSubscriptionUrl.decodeBase64(urlsafePadded), bytes);
      expect(VpnSubscriptionUrl.decodeBase64(urlsafeNoPad), bytes);
    });

    test('мусор даёт исключение', () {
      expect(
        () => VpnSubscriptionUrl.decodeBase64('!!!not-base64!!!'),
        throwsA(isA<VpnSubscriptionUrlException>()),
      );
    });
  });
}
