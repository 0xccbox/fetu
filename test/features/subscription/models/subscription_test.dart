import 'package:fetu/features/connection/models/server_node.dart';
import 'package:fetu/features/split_tunnel/models/rule_action.dart';
import 'package:fetu/features/split_tunnel/models/rule_type.dart';
import 'package:fetu/features/subscription/models/subscription.dart';
import 'package:fetu/features/subscription/models/subscription_node.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/subscription_fixtures.dart';

void main() {
  group('Subscription (полный контракт)', () {
    late Subscription subscription;

    setUpAll(() {
      subscription = Subscription.fromJson(fullSubscription());
    });

    test('парсит базовые поля и блоки', () {
      expect(subscription.version, 2);
      expect(subscription.name, 'Test VPN');
      expect(subscription.isExpired, isFalse);
      expect(subscription.nodes, hasLength(1));
      expect(subscription.update?.url, 'https://api.test-vpn.com/sub/user123');
      expect(subscription.update?.signaturePublicKey, 'MCowBQYDK2VwAyEA');
    });

    test('парсит узел: домены, протоколы, бейджи', () {
      final node = subscription.nodes.first;

      expect(node.id, 'nl-1');
      expect(node.country, 'NL');
      expect(node.domains, hasLength(3));
      expect(node.primaryAddress, 'nl1.vpn.com');
      expect(node.protocols, hasLength(3));
      expect(node.hasTcpFallback, isTrue);
      expect(node.badges, containsAll(['streaming', 'gaming']));
    });

    test('парсит протоколы: reality, credentials, приоритеты', () {
      final vless = subscription.nodes.first.protocols[1];

      expect(vless.type, 'vless');
      expect(vless.hasReality, isTrue);
      expect(vless.isTcpFallback, isTrue);
      expect(vless.protocolType, ProtocolType.vlessReality);
      expect(
        subscription.nodes.first.protocols.first.protocolType,
        ProtocolType.hysteria2,
      );
      expect(
        subscription.nodes.first.bestProtocol?.type,
        'hysteria2',
        reason: 'приоритет 1 выше',
      );
    });

    test('toServerNode конвертирует в модель подключения', () {
      final serverNode = subscription.nodes.first.toServerNode();

      expect(serverNode.id, 'nl-1');
      expect(serverNode.address, 'nl1.vpn.com');
      expect(serverNode.protocol, ProtocolType.hysteria2);
      expect(serverNode.config['port'], 443);
      expect(serverNode.config['password'], 'hy2-pass');

      final vlessNode = subscription.nodes.first
          .toServerNode(protocol: subscription.nodes.first.protocols[1]);
      expect(vlessNode.protocol, ProtocolType.vlessReality);
      expect(vlessNode.config['uuid'], startsWith('550e'));
    });

    test('парсит кабинет: аккаунт, объявления, карточки, метаданные', () {
      final cabinet = subscription.cabinet!;
      final account = cabinet.account!;

      expect(account.planName, 'Pro Unlimited');
      expect(account.status, 'active');
      expect(account.isExpired, isFalse);
      expect(account.traffic.usedBytes, 48318382080);
      expect(account.traffic.usedFraction, inExclusiveRange(0.0, 1.0));
      expect(account.devices.currentCount, 2);
      expect(account.billing.balanceFormatted, '450 ₽');

      expect(cabinet.announcements, hasLength(2));
      expect(
        cabinet.activeAnnouncements,
        hasLength(1),
        reason: 'истекшие отфильтрованы',
      );
      expect(cabinet.announcements.first.title, contains('Финляндии'));

      expect(cabinet.customCards, hasLength(1));
      expect(cabinet.customCards.first.copyValue, 'FRIEND123');

      expect(cabinet.badgeById('gaming')?.label, 'Для игр');

      expect(cabinet.developerMeta?.abTestGroup, 'xhttp_reality_v2');
      expect(cabinet.developerMeta?.backendNode, 'api-eu-west-2');
    });

    test('парсит брендинг', () {
      final branding = subscription.branding!;

      expect(branding.appName, 'Test VPN Pro');
      expect(branding.logoUrl, isNotNull);
      expect(branding.telegramUrl, 'https://t.me/test_vpn');
      expect(branding.colors['accent'], '#38BDF8');
      expect(branding.primaryLinkUrl, 'https://t.me/test_vpn');
    });

    test('split_tunnel: маппинг в SplitRule с нормализацией', () {
      final split = subscription.splitTunnel!;

      expect(split.enabled, isTrue);
      final rules = split.toSplitRules();

      // .ru → ru (нормализация), process → app (многозначный join).
      final ruRule = rules.firstWhere(
        (r) => r.type == RuleType.domainSuffix && r.pattern == 'ru',
      );
      expect(ruRule.action, RuleAction.direct);
      expect(ruRule.builtin, isTrue);
      expect(ruRule.id, 'provider:domain_suffix:ru');

      expect(
        rules.where((r) => r.type == RuleType.domainKeyword).length,
        2,
        reason: 'два keyword-паттерна → два правила',
      );
      expect(
        rules.where((r) => r.type == RuleType.geoip).single.pattern,
        'private',
      );
      expect(
        rules.where((r) => r.type == RuleType.app).single.pattern,
        'com.sberbank.android',
      );
    });

    test('toJson → fromJson round-trip сохраняет данные', () {
      final restored = Subscription.fromJson(subscription.toJson());

      expect(restored.name, subscription.name);
      expect(restored.version, subscription.version);
      expect(restored.nodes, hasLength(1));
      expect(restored.nodes.first.primaryAddress, 'nl1.vpn.com');
      expect(restored.branding?.appName, 'Test VPN Pro');
      expect(restored.cabinet?.account?.planName, 'Pro Unlimited');
      expect(restored.splitTunnel?.enabled, isTrue);
    });
  });

  group('Subscription (повреждённые данные)', () {
    test('кабинет отсутствует → null, подписка живёт', () {
      final sub = Subscription.fromJson(minimalSubscription());

      expect(sub.cabinet, isNull);
      expect(sub.branding, isNull);
      expect(sub.splitTunnel, isNull);
    });

    test('некорректные поля не роняют парсер', () {
      final sub = Subscription.fromJson({
        'version': 2,
        'name': 'Broken',
        'expire_at': 'not-a-date',
        'nodes': ['not-a-map', validNode()],
        'features': 'not-a-map',
      });

      expect(sub.expireAt, isNull);
      expect(sub.nodes, hasLength(1), reason: 'мусорные записи пропущены');
      expect(sub.splitTunnel, isNull);
    });
  });

  group('SubscriptionNode', () {
    test('primaryAddress выбирает active-домен по приоритету', () {
      final node = SubscriptionNode.fromJson(validNode());

      expect(node.primaryAddress, 'nl1.vpn.com');

      final nodeWithoutDomains = SubscriptionNode.fromJson(udpOnlyNode());
      expect(nodeWithoutDomains.primaryAddress, isNull);
    });

    test('toServerNode падает без адреса или протокола', () {
      final broken = SubscriptionNode.fromJson(const {
        'id': 'x',
        'name': 'No domains',
        'protocols': [
          {'type': 'hysteria2', 'port': 443, 'password': 'pw'},
        ],
      });
      expect(() => broken.toServerNode(), throwsStateError);

      final unknownProtocol = SubscriptionNode.fromJson(const {
        'id': 'y',
        'name': 'Unknown proto',
        'domains': [
          {'address': 'a.com'},
        ],
        'protocols': [
          {'type': 'trojan', 'port': 443},
        ],
      });
      expect(() => unknownProtocol.toServerNode(), throwsStateError);
    });

    test('ServerNode-модель остаётся совместимой с генератором', () {
      final serverNode = SubscriptionNode.fromJson(validNode()).toServerNode();

      expect(serverNode.protocol.isTcp || serverNode.protocol.isUdp, isTrue);
      expect(serverNode.config, isA<Map<String, dynamic>>());
      expect(ServerNode.fromJson(serverNode.toJson()).id, serverNode.id);
    });
  });
}
