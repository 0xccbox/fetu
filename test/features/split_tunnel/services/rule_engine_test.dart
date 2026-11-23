import 'package:fetu/core/constants/split_tunnel_constants.dart';
import 'package:fetu/features/split_tunnel/models/rule_action.dart';
import 'package:fetu/features/split_tunnel/models/rule_type.dart';
import 'package:fetu/features/split_tunnel/models/split_rule.dart';
import 'package:fetu/features/split_tunnel/services/rule_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RuleEngine resolveActionForDomain', () {
    test('должен возвращать proxy по умолчанию без правил', () {
      const engine = RuleEngine();
      expect(
        engine.resolveActionForDomain('example.com', const []),
        RuleAction.proxy,
      );
    });

    test('побеждает первое совпавшее правило', () {
      const engine = RuleEngine();
      const rules = [
        SplitRule(
          id: '1',
          type: RuleType.domain,
          pattern: 'vk.com',
          action: RuleAction.block,
        ),
        SplitRule(
          id: '2',
          type: RuleType.domainSuffix,
          pattern: 'vk.com',
          action: RuleAction.direct,
        ),
      ];

      expect(engine.resolveActionForDomain('vk.com', rules), RuleAction.block);
      expect(
        engine.resolveActionForDomain('m.vk.com', rules),
        RuleAction.direct,
      );
    });

    test('выключенные правила пропускаются', () {
      const engine = RuleEngine();
      const rules = [
        SplitRule(
          id: '1',
          type: RuleType.domainSuffix,
          pattern: 'vk.com',
          action: RuleAction.block,
          enabled: false,
        ),
      ];

      expect(engine.resolveActionForDomain('vk.com', rules), RuleAction.proxy);
    });

    test('не-доменные правила не участвуют в локальном матчинге', () {
      const engine = RuleEngine();
      const rules = [
        SplitRule(
          id: '1',
          type: RuleType.geoip,
          pattern: 'ru',
          action: RuleAction.direct,
        ),
      ];

      expect(engine.resolveActionForDomain('vk.com', rules), RuleAction.proxy);
    });
  });

  group('RuleEngine buildRouteRules', () {
    test(
        'каждое активное правило → отдельный JSON-объект с сохранением порядка',
        () {
      const rules = [
        SplitRule(
          id: '1',
          type: RuleType.domainSuffix,
          pattern: 'VK.com',
          action: RuleAction.direct,
        ),
        SplitRule(
          id: '2',
          type: RuleType.domainKeyword,
          pattern: 'youtube',
          action: RuleAction.proxy,
        ),
        SplitRule(
          id: '3',
          type: RuleType.domainRegex,
          pattern: r'^ads\d*\.',
          action: RuleAction.block,
        ),
      ];

      final jsonRules = RuleEngine.buildRouteRules(rules);

      expect(jsonRules, hasLength(3));
      expect(jsonRules[0], {
        'domain_suffix': ['vk.com'],
        'outbound': 'direct',
      });
      expect(jsonRules[1], {
        'domain_keyword': ['youtube'],
        'outbound': 'proxy',
      });
      expect(
        jsonRules[2]['domain_regex'],
        [r'^ads\d*\.'],
        reason: 'regex не нормализуется',
      );
      expect(jsonRules[2]['action'], 'reject');
      expect(jsonRules[2].containsKey('outbound'), isFalse);
    });

    test('выключенные правила не попадают в конфигурацию', () {
      const rules = [
        SplitRule(
          id: '1',
          type: RuleType.domainSuffix,
          pattern: 'vk.com',
          action: RuleAction.direct,
          enabled: false,
        ),
      ];

      expect(RuleEngine.buildRouteRules(rules), isEmpty);
    });

    test('многозначные типы разбивают паттерн на список', () {
      const rules = [
        SplitRule(
          id: '1',
          type: RuleType.ipCidr,
          pattern: '192.168.1.0/24, 10.0.0.0/8',
          action: RuleAction.direct,
        ),
        SplitRule(
          id: '2',
          type: RuleType.app,
          pattern: 'com.vk.android,com.example.app',
          action: RuleAction.proxy,
        ),
      ];

      final jsonRules = RuleEngine.buildRouteRules(rules);

      expect(jsonRules[0]['ip_cidr'], ['192.168.1.0/24', '10.0.0.0/8']);
      expect(
        jsonRules[1]['package_name'],
        ['com.vk.android', 'com.example.app'],
      );
    });

    test('должен бросать исключение при превышении лимита инлайн-правил', () {
      final rules = List.generate(
        SplitTunnelConstants.maxInlineRules + 1,
        (i) => SplitRule(
          id: 'r$i',
          type: RuleType.domainSuffix,
          pattern: 'domain$i.com',
          action: RuleAction.proxy,
        ),
      );

      expect(
        () => RuleEngine.buildRouteRules(rules),
        throwsA(isA<SplitRuleLimitException>()),
      );
    });
  });
}
