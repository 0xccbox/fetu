/// Предустановленные наборы правил раздельного туннелирования.
///
/// Компактные curated-наборы (не тысячи доменов — крупные списки
/// подключаются `.srs`-наборами в ФАЗЕ 9, AGENTS.md правило 32).
library;

import 'package:meta/meta.dart';

import '../models/rule_action.dart';
import '../models/rule_type.dart';
import '../models/split_rule.dart';

/// Иммутабельный набор правил, поставляемый с приложением.
///
/// Названия/описания не хранятся здесь: UI берёт их из локализации
/// по [id] (AGENTS.md, правило 14).
@immutable
class PresetRuleSet {
  /// Создаёт набор.
  const PresetRuleSet({required this.id, required this.rules});

  /// Идентификатор набора (стабильный, для персистентности и l10n).
  final String id;

  /// Правила набора (все `builtin: true`, с детерминированными id).
  final List<SplitRule> rules;
}

/// Каталог предустановленных наборов правил.
class PresetRuleSets {
  const PresetRuleSets._();

  static const String _idPrefix = 'preset:';

  /// Все доступные пресеты.
  static List<PresetRuleSet> get all => [
        russianSites,
        blockedResources,
        adAndTrackers,
        socialNetworks,
      ];

  /// Популярные российские ресурсы — напрямую, без VPN.
  static PresetRuleSet get russianSites => _build(
        id: 'ru_direct',
        action: RuleAction.direct,
        patterns: [
          'yandex.ru',
          'ya.ru',
          'mail.ru',
          'gosuslugi.ru',
          'sberbank.ru',
          'tinkoff.ru',
          'ozon.ru',
          'wildberries.ru',
          'avito.ru',
          'dns-shop.ru',
        ],
      );

  /// Заблокированные ресурсы — через VPN.
  static PresetRuleSet get blockedResources => _build(
        id: 'blocked_proxy',
        action: RuleAction.proxy,
        patterns: [
          'instagram.com',
          'facebook.com',
          'x.com',
          'twitter.com',
          'youtube.com',
          'netflix.com',
          'hbo.com',
          'discord.com',
        ],
      );

  /// Реклама и трекеры — блокировка.
  static PresetRuleSet get adAndTrackers => _build(
        id: 'ads_block',
        action: RuleAction.block,
        patterns: [
          'doubleclick.net',
          'googlesyndication.com',
          'google-analytics.com',
          'adservice.google.com',
          'adfox.ru',
          'adriver.ru',
          'criteo.com',
          'scorecardresearch.com',
        ],
      );

  /// Социальные сети — через VPN.
  static PresetRuleSet get socialNetworks => _build(
        id: 'social_proxy',
        action: RuleAction.proxy,
        patterns: [
          'vk.com',
          'ok.ru',
          'tiktok.com',
          'snapchat.com',
          'threads.net',
          'reddit.com',
        ],
      );

  /// Ищет пресет по идентификатору.
  static PresetRuleSet? byId(String id) {
    for (final preset in all) {
      if (preset.id == id) return preset;
    }
    return null;
  }

  /// Собирает набор суффикс-правил с детерминированными id.
  ///
  /// Список правил иммутабельный (AGENTS.md, правило 10).
  static PresetRuleSet _build({
    required String id,
    required RuleAction action,
    required List<String> patterns,
  }) =>
      PresetRuleSet(
        id: id,
        rules: List.unmodifiable([
          for (final pattern in patterns)
            SplitRule(
              id: '$_idPrefix$id:$pattern',
              type: RuleType.domainSuffix,
              pattern: pattern,
              action: action,
              builtin: true,
            ),
        ]),
      );
}
