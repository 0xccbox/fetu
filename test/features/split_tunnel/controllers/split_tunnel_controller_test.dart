import 'dart:convert';

import 'package:fetu/core/constants/split_tunnel_constants.dart';
import 'package:fetu/features/split_tunnel/controllers/split_tunnel_controller.dart';
import 'package:fetu/features/split_tunnel/models/rule_action.dart';
import 'package:fetu/features/split_tunnel/models/rule_type.dart';
import 'package:fetu/features/split_tunnel/models/split_rule.dart';
import 'package:fetu/features/split_tunnel/services/preset_rule_sets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_storage.dart';

void main() {
  late TestStorage storage;
  late List<List<SplitRule>> changeLog;
  late SplitTunnelController controller;

  setUp(() {
    storage = TestStorage();
    changeLog = [];
    controller = SplitTunnelController(
      storage: storage,
      onRulesChanged: () async {
        changeLog.add(controller.activeRules);
      },
    );
  });

  tearDown(() {
    controller.dispose();
  });

  group('SplitTunnelController', () {
    test('initialize без хранилища — пустой список без ошибок', () async {
      final bare = SplitTunnelController();
      await bare.initialize();

      expect(bare.rules, isEmpty);
      expect(bare.errorMessage, isNull);
      bare.dispose();
    });

    test('addRule добавляет правило и вызывает колбэк изменений', () async {
      await controller.addRule(
        type: RuleType.domainSuffix,
        pattern: 'VK.com',
        action: RuleAction.direct,
      );

      expect(controller.rules, hasLength(1));
      expect(
        controller.rules.first.pattern,
        'vk.com',
        reason: 'домены нормализуются',
      );
      expect(controller.errorMessage, isNull);
      expect(changeLog, hasLength(1));
      expect(changeLog.first, hasLength(1));
    });

    test('addRule отклоняет пустой и короткий паттерн', () async {
      await controller.addRule(
        type: RuleType.domain,
        pattern: 'v',
        action: RuleAction.proxy,
      );

      expect(controller.rules, isEmpty);
      expect(controller.errorMessage, isNotNull);
      expect(changeLog, isEmpty, reason: 'колбэк не должен вызываться');
    });

    test('addRule отклоняет некорректный regex', () async {
      await controller.addRule(
        type: RuleType.domainRegex,
        pattern: r'^[broken',
        action: RuleAction.block,
      );

      expect(controller.rules, isEmpty);
      expect(controller.errorMessage, 'Некорректное регулярное выражение');
    });

    test('addRule отклоняет дубликат типа+паттерна', () async {
      await controller.addRule(
        type: RuleType.domainSuffix,
        pattern: 'vk.com',
        action: RuleAction.direct,
      );
      await controller.addRule(
        type: RuleType.domainSuffix,
        pattern: 'vk.com',
        action: RuleAction.proxy,
      );

      expect(controller.rules, hasLength(1));
      expect(controller.errorMessage, 'Такое правило уже существует');
    });

    test('setRuleEnabled переключает правило и activeRules', () async {
      await controller.addRule(
        type: RuleType.domainSuffix,
        pattern: 'vk.com',
        action: RuleAction.direct,
      );
      final id = controller.rules.first.id;

      await controller.setRuleEnabled(id, false);

      expect(controller.rules.first.enabled, isFalse);
      expect(controller.activeRules, isEmpty);

      await controller.setRuleEnabled(id, true);
      expect(controller.activeRules, hasLength(1));
    });

    test('updateRule меняет правило по id', () async {
      await controller.addRule(
        type: RuleType.domainSuffix,
        pattern: 'vk.com',
        action: RuleAction.direct,
      );
      final id = controller.rules.first.id;

      await controller.updateRule(
        id,
        type: RuleType.domain,
        pattern: 'ok.ru',
        action: RuleAction.block,
      );

      expect(controller.rules, hasLength(1));
      expect(controller.rules.first.pattern, 'ok.ru');
      expect(controller.rules.first.action, RuleAction.block);
      expect(controller.rules.first.type, RuleType.domain);
    });

    test('removeRule и clearAll очищают список', () async {
      await controller.addRule(
        type: RuleType.domainSuffix,
        pattern: 'vk.com',
        action: RuleAction.direct,
      );
      await controller.removeRule(controller.rules.first.id);
      expect(controller.rules, isEmpty);

      await controller.addRule(
        type: RuleType.domainSuffix,
        pattern: 'vk.com',
        action: RuleAction.direct,
      );
      await controller.clearAll();
      expect(controller.rules, isEmpty);
    });

    test('applyPreset идемпотентен и помечается isPresetApplied', () async {
      await controller.applyPreset('ads_block');

      expect(
        controller.rules,
        hasLength(PresetRuleSets.adAndTrackers.rules.length),
      );
      expect(controller.isPresetApplied('ads_block'), isTrue);

      await controller.applyPreset('ads_block');
      expect(
        controller.rules,
        hasLength(PresetRuleSets.adAndTrackers.rules.length),
        reason: 'повторное применение не дублирует',
      );
    });

    test('isPresetApplied возвращает false при выключенном правиле', () async {
      await controller.applyPreset('ads_block');
      final id = controller.rules.first.id;

      await controller.setRuleEnabled(id, false);

      expect(controller.isPresetApplied('ads_block'), isFalse);
    });

    test('removePreset удаляет только правила набора', () async {
      await controller.applyPreset('ads_block');
      await controller.addRule(
        type: RuleType.domainSuffix,
        pattern: 'vk.com',
        action: RuleAction.direct,
      );

      await controller.removePreset('ads_block');

      expect(controller.rules, hasLength(1));
      expect(controller.rules.first.builtin, isFalse);
    });

    test('unknown preset отклоняется с ошибкой', () async {
      await controller.applyPreset('nope');

      expect(controller.rules, isEmpty);
      expect(controller.errorMessage, isNotNull);
    });

    test('правила персистятся в хранилище и восстанавливаются', () async {
      await controller.addRule(
        type: RuleType.domainSuffix,
        pattern: 'vk.com',
        action: RuleAction.direct,
      );
      await controller.applyPreset('social_proxy');

      final raw = await storage.read(key: SplitTunnelConstants.storageKey);
      expect(raw, isNotNull);

      final restored = SplitTunnelController(storage: storage);
      await restored.initialize();

      expect(
        restored.rules,
        hasLength(1 + PresetRuleSets.socialNetworks.rules.length),
      );
      expect(restored.rules.first.pattern, 'vk.com');
      expect(restored.errorMessage, isNull);
      restored.dispose();
    });

    test('битое хранилище не ломает initialize', () async {
      await storage.write(
        key: SplitTunnelConstants.storageKey,
        value: 'not json',
      );

      final broken = SplitTunnelController(storage: storage);
      await broken.initialize();

      expect(broken.rules, isEmpty);
      expect(broken.errorMessage, isNotNull);
      broken.dispose();
    });

    test('сбой reload не теряет правила и сообщает ошибку', () async {
      final failing = SplitTunnelController(
        storage: storage,
        onRulesChanged: () async => throw Exception('native channel down'),
      );

      await failing.addRule(
        type: RuleType.domainSuffix,
        pattern: 'vk.com',
        action: RuleAction.direct,
      );

      expect(failing.rules, hasLength(1), reason: 'правила сохранены');
      expect(failing.errorMessage, contains('native channel down'));
      failing.dispose();
    });

    test('toJson-снимок в хранилище проходит валидацию JSON', () async {
      await controller.addRule(
        type: RuleType.domainRegex,
        pattern: r'^ads\d*\.',
        action: RuleAction.block,
      );

      final raw = await storage.read(key: SplitTunnelConstants.storageKey);
      final decoded = jsonDecode(raw!) as List<dynamic>;
      final firstRule = decoded.first as Map<String, dynamic>;

      expect(decoded, isNotEmpty);
      expect(
        firstRule['pattern'],
        r'^ads\d*\.',
        reason: 'regex сохраняется как есть',
      );
    });
  });
}
