import 'package:fetu/features/split_tunnel/models/rule_action.dart';
import 'package:fetu/features/split_tunnel/models/rule_type.dart';
import 'package:fetu/features/split_tunnel/models/split_rule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SplitRule', () {
    const rule = SplitRule(
      id: 'user:1',
      type: RuleType.domainSuffix,
      pattern: 'vk.com',
      action: RuleAction.direct,
    );

    test('должен быть immutable и хранить все поля', () {
      expect(rule.id, 'user:1');
      expect(rule.type, RuleType.domainSuffix);
      expect(rule.pattern, 'vk.com');
      expect(rule.action, RuleAction.direct);
      expect(rule.enabled, isTrue);
      expect(rule.builtin, isFalse);
    });

    test('copyWith должен менять только переданные поля', () {
      final updated = rule.copyWith(enabled: false, action: RuleAction.block);

      expect(updated.id, rule.id);
      expect(updated.pattern, rule.pattern);
      expect(updated.enabled, isFalse);
      expect(updated.action, RuleAction.block);
      expect(rule.enabled, isTrue, reason: 'оригинал не изменяется');
    });

    test('== и hashCode должны учитывать все поля', () {
      const same = SplitRule(
        id: 'user:1',
        type: RuleType.domainSuffix,
        pattern: 'vk.com',
        action: RuleAction.direct,
      );
      const different = SplitRule(
        id: 'user:1',
        type: RuleType.domainSuffix,
        pattern: 'vk.com',
        action: RuleAction.direct,
        enabled: false,
      );

      expect(rule, same);
      expect(rule.hashCode, same.hashCode);
      expect(rule == different, isFalse);
    });

    test('toJson/fromJson должны давать round-trip', () {
      final restored = SplitRule.fromJson(rule.toJson());

      expect(restored, rule);
    });

    test('fromJson должен переживать повреждённый JSON', () {
      final restored = SplitRule.fromJson(const {
        'id': 'broken',
        'type': 'unknown_type',
        'pattern': 'example.com',
        'action': 'nonsense',
      });

      expect(restored.type, RuleType.domainSuffix, reason: 'safe default');
      expect(restored.action, RuleAction.proxy, reason: 'safe default');
      expect(restored.enabled, isTrue);
      expect(restored.builtin, isFalse);
    });
  });

  group('RuleAction', () {
    test('outboundTag должен совпадать с тегами sing-box', () {
      expect(RuleAction.proxy.outboundTag, 'proxy');
      expect(RuleAction.direct.outboundTag, 'direct');
      expect(RuleAction.block.outboundTag, 'block');
    });

    test('fromName должен безопасно обрабатывать мусор', () {
      expect(RuleAction.fromName('direct'), RuleAction.direct);
      expect(RuleAction.fromName(null), RuleAction.proxy);
      expect(RuleAction.fromName('42'), RuleAction.proxy);
    });
  });

  group('RuleType', () {
    test('singBoxKey должен соответствовать ключам route rule sing-box', () {
      expect(RuleType.domain.singBoxKey, 'domain');
      expect(RuleType.domainSuffix.singBoxKey, 'domain_suffix');
      expect(RuleType.domainKeyword.singBoxKey, 'domain_keyword');
      expect(RuleType.domainRegex.singBoxKey, 'domain_regex');
      expect(RuleType.ipCidr.singBoxKey, 'ip_cidr');
      expect(RuleType.geoip.singBoxKey, 'geoip');
      expect(RuleType.app.singBoxKey, 'package_name');
    });

    test('fromName должен восстанавливать тип по singBoxKey', () {
      for (final type in RuleType.values) {
        expect(RuleType.fromName(type.singBoxKey), type);
      }
      expect(RuleType.fromName('garbage'), RuleType.domainSuffix);
    });

    test('isDomainBased должен отделять доменные типы', () {
      expect(RuleType.domain.isDomainBased, isTrue);
      expect(RuleType.domainSuffix.isDomainBased, isTrue);
      expect(RuleType.ipCidr.isDomainBased, isFalse);
      expect(RuleType.app.isDomainBased, isFalse);
    });
  });
}
