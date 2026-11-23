import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'package:fetu/features/subscription/services/subscription_parser.dart';
import 'package:fetu/features/subscription/services/vpn_subscription_url.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/subscription_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SubscriptionParser.parse', () {
    test('парсит валидную подписку (в фоне, в Isolate)', () async {
      final subscription = await SubscriptionParser.parse(
        asJson(minimalSubscription()),
      );

      expect(subscription.name, 'Test VPN');
      expect(subscription.nodes, hasLength(1));
    });

    test('отклоняет пустую строку', () async {
      await expectLater(
        SubscriptionParser.parse('   '),
        throwsA(
          isA<SubscriptionParseException>().having(
            (e) => e.message,
            'message',
            contains('Пустая'),
          ),
        ),
      );
    });

    test('отклоняет некорректный JSON', () async {
      await expectLater(
        SubscriptionParser.parse('{broken json'),
        throwsA(
          isA<SubscriptionParseException>().having(
            (e) => e.message,
            'message',
            contains('JSON'),
          ),
        ),
      );
    });

    test('отклоняет не-объект JSON', () async {
      await expectLater(
        SubscriptionParser.parse('[1,2,3]'),
        throwsA(isA<SubscriptionParseException>()),
      );
    });

    test('отклоняет устаревшую версию', () async {
      await expectLater(
        SubscriptionParser.parse(
          asJson(minimalSubscription(version: 1)),
        ),
        throwsA(
          isA<SubscriptionParseException>().having(
            (e) => e.message,
            'message',
            contains('версия'),
          ),
        ),
      );
    });

    test('отклоняет истёкшую подписку', () async {
      await expectLater(
        SubscriptionParser.parse(
          asJson(minimalSubscription(expireAt: '2020-01-01T00:00:00Z')),
        ),
        throwsA(
          isA<SubscriptionParseException>().having(
            (e) => e.message,
            'message',
            contains('истекла'),
          ),
        ),
      );
    });

    test('отклоняет подписку без узлов', () async {
      await expectLater(
        SubscriptionParser.parse(
          asJson(minimalSubscription(nodes: [])),
        ),
        throwsA(
          isA<SubscriptionParseException>().having(
            (e) => e.message,
            'message',
            contains('серверов'),
          ),
        ),
      );
    });

    test('правило 9: отклоняет узел без TCP-канала', () async {
      await expectLater(
        SubscriptionParser.parse(
          asJson(minimalSubscription(nodes: [udpOnlyNode()])),
        ),
        throwsA(
          isA<SubscriptionParseException>().having(
            (e) => e.message,
            'message',
            allOf(contains('TCP'), contains('правило 9')),
          ),
        ),
      );
    });

    test('защита памяти: отклоняет слишком много узлов', () async {
      final nodes = List.generate(
        201,
        (i) => validNode(id: 'node-$i'),
      );

      await expectLater(
        SubscriptionParser.parse(asJson(minimalSubscription(nodes: nodes))),
        throwsA(isA<SubscriptionParseException>()),
      );
    });

    test('парсит Base64-подписку с hysteria2://, vless:// и ss://', () async {
      final rawLinks = [
        'hysteria2://pass-1@mosk.example.com:8447?alpn=h3&obfs=salamander&obfs-password=secret&sni=germ.example.com#%F0%9F%87%A9%F0%9F%87%AA%20Germany',
        'vless://11111111-1111-1111-1111-111111111111@nl.example.com:443?security=reality&pbk=PubKey&sid=abcd&sni=www.microsoft.com&flow=xtls-rprx-vision#%F0%9F%87%B3%F0%9F%87%B1%20NL',
        'ss://${base64Encode(utf8.encode('2022-blake3-aes-256-gcm:ss-pass'))}@jp.example.com:8388#%F0%9F%87%AF%F0%9F%87%B5%20Tokyo',
      ].join('\n');
      final encoded = base64Encode(utf8.encode(rawLinks));

      final sub = await SubscriptionParser.parse(encoded);

      expect(sub.nodes, hasLength(3));
      expect(sub.nodes[0].name, '🇩🇪 Germany');
      expect(sub.nodes[0].country, 'DE');
      expect(sub.nodes[0].primaryAddress, 'mosk.example.com');
      expect(sub.nodes[0].protocols.single.type, 'hysteria2');
      expect(sub.nodes[0].protocols.single.port, 8447);
      expect(sub.nodes[0].protocols.single.obfuscation['type'], 'salamander');
      expect(
        sub.nodes[1].protocols.single.reality['public_key'],
        'PubKey',
      );
      expect(sub.nodes[2].protocols.single.type, 'shadowsocks');
    });

    test('URI-парсер не падает на IPv6-хостах, неэкранированном % и VLESS TLS',
        () async {
      final rawLinks = [
        'hysteria2://pass%raw@1.2.3.4:8443#100%Ready',
        'vless://11111111-1111-1111-1111-111111111111@[2001:db8::1]:443?security=tls&sni=tls.example.com&insecure=1#IPv6',
      ].join('\n');

      final sub = await SubscriptionParser.parse(rawLinks);

      expect(sub.nodes, hasLength(2));
      expect(sub.nodes[0].protocols.single.credentials['password'], 'pass%raw');
      expect(sub.nodes[0].name, '100%Ready');
      expect(sub.nodes[1].primaryAddress, '2001:db8::1');
      final serverNode = sub.nodes[1].toServerNode();
      expect(serverNode.config['tls_sni'], 'tls.example.com');
      expect(serverNode.config['tls_insecure'], isTrue);
    });
  });

  group('SubscriptionParser.parseVpnUrl (HMAC)', () {
    final hmacKey = List<int>.generate(32, (i) => i * 7 + 1);
    final aesKey = List<int>.generate(32, (i) => 255 - i);

    String buildVpnUrl({List<int>? signWith}) {
      final json = asJson(minimalSubscription());
      final data = VpnSubscriptionUrl.encryptData(plaintext: json, key: aesKey);
      final key = signWith ?? hmacKey;
      final mac =
          crypto.Hmac(crypto.sha256, key).convert(utf8.encode(data)).bytes;
      return 'vpn://subscribe?data=$data&sig=${base64Url.encode(mac)}';
    }

    test('полный цикл: подпись → расшифровка → парсинг', () async {
      final subscription = await SubscriptionParser.parseVpnUrl(
        buildVpnUrl(),
        hmacKey: hmacKey,
        aesKey: aesKey,
      );

      expect(subscription.name, 'Test VPN');
      expect(subscription.nodes, hasLength(1));
    });

    test('невалидная подпись отклоняется до расшифровки', () async {
      await expectLater(
        SubscriptionParser.parseVpnUrl(
          buildVpnUrl(signWith: List<int>.generate(32, (i) => i)),
          hmacKey: hmacKey,
          aesKey: aesKey,
        ),
        throwsA(
          isA<SubscriptionParseException>().having(
            (e) => e.message,
            'message',
            'Подпись подписки невалидна',
          ),
        ),
      );
    });

    test('без ключей верификации — отказ', () async {
      await expectLater(
        SubscriptionParser.parseVpnUrl(buildVpnUrl(), aesKey: aesKey),
        throwsA(isA<SubscriptionParseException>()),
      );
    });

    test('мусорный URL — отказ', () async {
      await expectLater(
        SubscriptionParser.parseVpnUrl('https://example.com/sub'),
        throwsA(isA<SubscriptionParseException>()),
      );
    });
  });

  group('SubscriptionParser.parseVpnUrl (Ed25519)', () {
    final aesKey = List<int>.generate(32, (i) => 255 - i);

    /// Подпись Ed25519 по СЫРОМУ ciphertext (контракт:
    /// `private_key.sign(ciphertext)`), base64-строка — только для HMAC.
    Future<({String url, List<int> publicKey})> buildEd25519Url() async {
      final json = asJson(minimalSubscription());
      final data = VpnSubscriptionUrl.encryptData(plaintext: json, key: aesKey);
      final algorithm = Ed25519();
      final keyPair = await algorithm.newKeyPair();
      final signature = await algorithm.sign(
        VpnSubscriptionUrl.decodeBase64(data),
        keyPair: keyPair,
      );
      final publicKey = await keyPair.extractPublicKey();

      return (
        url:
            'vpn://subscribe?data=$data&sig=${base64Url.encode(signature.bytes)}',
        publicKey: publicKey.bytes,
      );
    }

    test('полный цикл: Ed25519 по ciphertext → расшифровка → парсинг',
        () async {
      final bundle = await buildEd25519Url();

      final subscription = await SubscriptionParser.parseVpnUrl(
        bundle.url,
        ed25519PublicKey: bundle.publicKey,
        aesKey: aesKey,
      );

      expect(subscription.name, 'Test VPN');
      expect(subscription.nodes, hasLength(1));
    });

    test('ошибки расшифровки заворачиваются в SubscriptionParseException',
        () async {
      final bundle = await buildEd25519Url();

      // Подпись валидна, но AES-ключ неверен → обёрнутое исключение.
      await expectLater(
        SubscriptionParser.parseVpnUrl(
          bundle.url,
          ed25519PublicKey: bundle.publicKey,
          aesKey: List<int>.generate(32, (i) => i),
        ),
        throwsA(
          isA<SubscriptionParseException>().having(
            (e) => e.message,
            'message',
            contains('расшифровать'),
          ),
        ),
      );
    });
  });
}
