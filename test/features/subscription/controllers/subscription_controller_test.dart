import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:fetu/core/constants/subscription_constants.dart';
import 'package:fetu/features/split_tunnel/models/rule_action.dart';
import 'package:fetu/features/subscription/controllers/subscription_controller.dart';
import 'package:fetu/features/subscription/services/ruleset_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/subscription_fixtures.dart';
import '../../../helpers/test_storage.dart';

void main() {
  late TestStorage storage;
  late String fetchedResponse;

  SubscriptionController controller() => SubscriptionController(
        storage: storage,
        fetcher: (_) async => fetchedResponse,
      );

  setUp(() {
    storage = TestStorage();
    fetchedResponse = '';
  });

  group('SubscriptionController', () {
    test('initialize без записи — пустое состояние', () async {
      final controller_ = controller();
      await controller_.initialize();

      expect(controller_.subscription, isNull);
      expect(controller_.errorMessage, isNull);
      controller_.dispose();
    });

    test('addFromRaw парсит и сохраняет подписку', () async {
      final controller_ = controller();
      await controller_.addFromRaw(asJson(minimalSubscription()));

      expect(controller_.subscription, isNotNull);
      expect(controller_.subscription!.name, 'Test VPN');
      expect(controller_.nodes, hasLength(1));
      expect(controller_.errorMessage, isNull);
      controller_.dispose();
    });

    test('addFromUrl скачивает по URL и запоминает URL', () async {
      fetchedResponse = asJson(minimalSubscription());
      final controller_ = controller();

      await controller_.addFromUrl('https://provider/sub');

      expect(controller_.subscription, isNotNull);
      expect(controller_.subscriptionUrl, 'https://provider/sub');
      controller_.dispose();
    });

    test('addFromUrl удаляет NUL-байты и сохраняет URI-подписку при рестарте',
        () async {
      String? requestedUrl;
      final hy2Links = base64Encode(
        utf8.encode(
          'hysteria2://pw@vpn.example.com:8443?sni=edge.example.com#%F0%9F%87%A9%F0%9F%87%AA%20DE',
        ),
      );
      final controller1 = SubscriptionController(
        storage: storage,
        fetcher: (url) async {
          requestedUrl = url;
          return hy2Links;
        },
      );

      await controller1.addFromUrl(
        'https://sub.example.com/token\u0000\u0000\n',
      );
      expect(requestedUrl, 'https://sub.example.com/token');
      expect(controller1.nodes, hasLength(1));
      controller1.dispose();

      final controller2 = controller();
      await controller2.initialize();
      expect(controller2.errorCode, isNull);
      expect(controller2.nodes, hasLength(1));
      expect(controller2.nodes.single.primaryAddress, 'vpn.example.com');
      controller2.dispose();
    });

    test('невалидная подписка → ошибка, старая не теряется', () async {
      fetchedResponse = asJson(minimalSubscription());
      final controller_ = controller();
      await controller_.addFromUrl('https://provider/sub');
      final before = controller_.subscription;

      fetchedResponse = 'garbage {{{';
      await controller_.refresh();

      expect(
        controller_.subscription,
        same(before),
        reason: 'при сбое обновления остаётся прежняя подписка',
      );
      expect(controller_.errorMessage, isNotNull);
      controller_.dispose();
    });

    test('refresh обновляет данные по сохранённому URL', () async {
      fetchedResponse = asJson(minimalSubscription());
      final controller_ = controller();
      await controller_.addFromUrl('https://provider/sub');

      final updated = {
        ...minimalSubscription(),
        'name': 'Test VPN v2',
      };
      fetchedResponse = asJson(updated);
      await controller_.refresh();

      expect(controller_.subscription!.name, 'Test VPN v2');
      controller_.dispose();
    });

    test('refresh без URL → понятная ошибка', () async {
      final controller_ = controller();
      await controller_.addFromRaw(asJson(minimalSubscription()));

      await controller_.refresh();

      expect(controller_.errorMessage, contains('URL'));
      controller_.dispose();
    });

    test('addFromUrl из блока update предпочитает url провайдера', () async {
      fetchedResponse = asJson({
        ...minimalSubscription(),
        'update': {'url': 'https://api.provider/v2/sub'},
      });
      final controller_ = controller();

      await controller_.addFromUrl('https://mirror/sub');

      expect(controller_.subscriptionUrl, 'https://api.provider/v2/sub');
      controller_.dispose();
    });

    test('подписка восстанавливается из хранилища после рестарта', () async {
      fetchedResponse = asJson(minimalSubscription());
      final first = controller();
      await first.addFromUrl('https://provider/sub');
      first.dispose();

      fetchedResponse = '';
      final second = controller();
      await second.initialize();

      expect(second.subscription, isNotNull);
      expect(second.subscription!.name, 'Test VPN');
      expect(second.subscriptionUrl, 'https://provider/sub');
      second.dispose();
    });

    test('битая запись хранилища очищается без падения', () async {
      await storage.write(
        key: SubscriptionConstants.storageKey,
        value: '{{{broken',
      );
      final controller_ = controller();

      await controller_.initialize();

      expect(controller_.subscription, isNull);
      expect(controller_.errorMessage, isNotNull);
      expect(
        await storage.read(key: SubscriptionConstants.storageKey),
        isNull,
        reason: 'битая запись удалена',
      );
      controller_.dispose();
    });

    test('истёкшая подписка сохраняется для refresh после продления', () async {
      // Подписка была валидна при добавлении, истекла между запусками.
      await storage.write(
        key: SubscriptionConstants.storageKey,
        value: jsonEncode({
          'url': 'https://provider/sub',
          'raw': asJson(
            minimalSubscription(expireAt: '2020-01-01T00:00:00Z'),
          ),
        }),
      );

      final controller_ = controller();
      await controller_.initialize();

      // Запись НЕ удалена: URL пригодится после продления тарифа.
      expect(
        await storage.read(key: SubscriptionConstants.storageKey),
        isNotNull,
      );
      expect(controller_.subscription, isNull);
      expect(controller_.errorMessage, contains('истекла'));
      controller_.dispose();
    });

    test('remove очищает подписку и хранилище', () async {
      fetchedResponse = asJson(minimalSubscription());
      final controller_ = controller();
      await controller_.addFromUrl('https://provider/sub');

      await controller_.remove();

      expect(controller_.subscription, isNull);
      expect(controller_.subscriptionUrl, isNull);
      expect(
        await storage.read(key: SubscriptionConstants.storageKey),
        isNull,
      );
      controller_.dispose();
    });

    test('пустой URL отклоняется с ошибкой', () async {
      final controller_ = controller();

      await controller_.addFromUrl('   ');

      expect(controller_.subscription, isNull);
      expect(controller_.errorMessage, contains('URL'));
      controller_.dispose();
    });

    test('isLoading сбрасывается после ошибки', () async {
      fetchedResponse = 'garbage';
      final controller_ = controller();

      await controller_.addFromUrl('https://provider/sub');

      expect(controller_.isLoading, isFalse);
      expect(controller_.errorMessage, isNotNull);
      controller_.dispose();
    });

    test('syncRuleSets кэширует .srs и заполняет activeRuleSets', () async {
      final srsBytes = Uint8List.fromList([1, 2, 3, 4]);
      final expectedSha = crypto.sha256.convert(srsBytes).toString();
      final subJson = {
        ...minimalSubscription(),
        'features': {
          'split_tunnel': {
            'enabled': true,
            'rules': const [],
            'rule_sets': [
              {
                'id': 'geoip-ru',
                'url': 'https://cdn.example/geoip-ru.srs',
                'action': 'direct',
                'sha256': expectedSha,
              },
            ],
          },
        },
      };
      final manager = RuleSetCacheManager(
        storage: storage,
        fetcher: (_, __) async => RuleSetDownload(
          statusCode: 200,
          bytes: srsBytes,
          etag: '"v1"',
        ),
      );
      final controller_ = SubscriptionController(
        storage: storage,
        fetcher: (_) async => asJson(subJson),
        ruleSetCacheManager: manager,
        ruleSetFileWriter: (id, _) async => '/tmp/$id.srs',
      );

      await controller_.addFromUrl('https://provider/sub');
      await controller_.syncRuleSets();

      expect(controller_.activeRuleSets, hasLength(1));
      expect(controller_.activeRuleSets.single.tag, 'geoip-ru');
      expect(controller_.activeRuleSets.single.path, '/tmp/geoip-ru.srs');
      expect(controller_.activeRuleSets.single.action, RuleAction.direct);
      controller_.dispose();
    });
  });
}
