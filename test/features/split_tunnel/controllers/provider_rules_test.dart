import 'package:fetu/features/split_tunnel/controllers/split_tunnel_controller.dart';
import 'package:fetu/features/split_tunnel/models/rule_action.dart';
import 'package:fetu/features/split_tunnel/models/rule_type.dart';
import 'package:fetu/features/split_tunnel/models/split_rule.dart';
import 'package:fetu/features/subscription/models/subscription_split_tunnel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_storage.dart';

void main() {
  late TestStorage storage;
  late SplitTunnelController controller;

  Map<String, dynamic> providerBlock() => {
        'enabled': true,
        'rules': [
          {
            'name': 'Российские сайты',
            'type': 'domain_suffix',
            'patterns': ['.ru', '.рф'],
            'action': 'direct',
          },
          {
            'name': 'Банки',
            'type': 'process',
            'patterns': ['com.sberbank.android'],
            'action': 'direct',
          },
        ],
      };

  setUp(() {
    storage = TestStorage();
    controller = SplitTunnelController(storage: storage);
  });

  tearDown(() {
    controller.dispose();
  });

  group('SplitTunnelController.applyProviderRules', () {
    test('применяет правила провайдера из подписки', () async {
      final rules =
          SubscriptionSplitTunnel.fromJson(providerBlock()).toSplitRules();

      await controller.applyProviderRules(rules);

      expect(
        controller.rules,
        hasLength(3),
        reason: 'ru + рф + один process',
      );
      expect(
        controller.rules
            .where((r) => r.type == RuleType.domainSuffix)
            .map((r) => r.pattern),
        containsAll(['ru', 'рф']),
      );
      expect(controller.activeRules.every((r) => r.builtin), isTrue);
      expect(controller.errorMessage, isNull);
    });

    test('идемпотентен: повторное применение не дублирует', () async {
      final rules =
          SubscriptionSplitTunnel.fromJson(providerBlock()).toSplitRules();

      await controller.applyProviderRules(rules);
      await controller.applyProviderRules(rules);

      expect(controller.rules, hasLength(3));
    });

    test('пустой список → понятная ошибка', () async {
      await controller.applyProviderRules(const <SplitRule>[]);

      expect(controller.rules, isEmpty);
      expect(controller.errorMessage, contains('правил'));
    });

    test('сосуществует с пользовательскими правилами', () async {
      await controller.addRule(
        type: RuleType.domainSuffix,
        pattern: 'custom.com',
        action: RuleAction.proxy,
      );
      final rules =
          SubscriptionSplitTunnel.fromJson(providerBlock()).toSplitRules();

      await controller.applyProviderRules(rules);

      expect(controller.rules, hasLength(4));
      expect(
        controller.rules.any((r) => r.pattern == 'custom.com'),
        isTrue,
      );
    });

    test('правила провайдера видны в снапшоте route.rules', () async {
      final rules =
          SubscriptionSplitTunnel.fromJson(providerBlock()).toSplitRules();

      await controller.applyProviderRules(rules);

      final persisted = await storage.read(key: 'split_tunnel.rules.v1');
      expect(persisted, contains('provider:domain_suffix:ru'));
      expect(persisted, contains('com.sberbank.android'));
    });
  });
}
