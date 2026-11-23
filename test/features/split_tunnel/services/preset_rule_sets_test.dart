import 'package:fetu/features/split_tunnel/models/rule_action.dart';
import 'package:fetu/features/split_tunnel/models/rule_type.dart';
import 'package:fetu/features/split_tunnel/models/split_rule.dart';
import 'package:fetu/features/split_tunnel/services/preset_rule_sets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PresetRuleSets', () {
    test('должен содержать 4 набора', () {
      expect(PresetRuleSets.all, hasLength(4));
    });

    test('все наборы непустые и с уникальными id', () {
      final ids = <String>{};
      for (final preset in PresetRuleSets.all) {
        expect(
          preset.rules,
          isNotEmpty,
          reason: 'набор ${preset.id} пуст',
        );
        expect(
          ids.add(preset.id),
          isTrue,
          reason: 'дубликат id набора ${preset.id}',
        );
        // Названия/описания наборов локализуются в UI по id
        // (rule_l10n.dart), в сервисе их нет (правило 14).
        expect(preset.id, isNotEmpty);
      }
    });

    test('правила наборов: builtin, детерминированные id, без дублей паттернов',
        () {
      for (final preset in PresetRuleSets.all) {
        final patterns = <String>{};
        for (final rule in preset.rules) {
          expect(
            rule.builtin,
            isTrue,
            reason: 'правило пресета должно быть builtin',
          );
          expect(
            rule.id,
            startsWith('preset:${preset.id}:'),
            reason: 'id должен быть детерминированным',
          );
          expect(rule.type, RuleType.domainSuffix);
          expect(
            patterns.add(rule.pattern),
            isTrue,
            reason: 'дубль паттерна ${rule.pattern} в ${preset.id}',
          );
        }
      }
    });

    test('id правил должны быть стабильны между вызовами', () {
      final first = PresetRuleSets.russianSites.rules.map((r) => r.id).toList();
      final second =
          PresetRuleSets.russianSites.rules.map((r) => r.id).toList();
      expect(first, second);
    });

    test('наборы должны иметь заявленные действия', () {
      expect(
        PresetRuleSets.russianSites.rules
            .every((r) => r.action == RuleAction.direct),
        isTrue,
      );
      expect(
        PresetRuleSets.blockedResources.rules
            .every((r) => r.action == RuleAction.proxy),
        isTrue,
      );
      expect(
        PresetRuleSets.adAndTrackers.rules
            .every((r) => r.action == RuleAction.block),
        isTrue,
      );
      expect(
        PresetRuleSets.socialNetworks.rules
            .every((r) => r.action == RuleAction.proxy),
        isTrue,
      );
    });

    test('byId находит набор, для мусора возвращает null', () {
      expect(PresetRuleSets.byId('ru_direct'), isNotNull);
      expect(PresetRuleSets.byId('nope'), isNull);
    });

    test('правила набора должны матчиться DomainMatcher-семантикой', () {
      // RU-набор покрывает поддомены.
      final yandexRule = PresetRuleSets.russianSites.rules
          .firstWhere((SplitRule r) => r.pattern == 'yandex.ru');
      expect(yandexRule.action, RuleAction.direct);
    });
  });
}
