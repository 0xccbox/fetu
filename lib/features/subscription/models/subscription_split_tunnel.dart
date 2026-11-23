/// Split Tunneling-блок подписки (`features.split_tunnel`) и его
/// трансляция в правила ФАЗЫ 8.
library;

import 'package:meta/meta.dart';

import '../../split_tunnel/models/rule_action.dart';
import '../../split_tunnel/models/rule_type.dart';
import '../../split_tunnel/models/split_rule.dart';
import '../../split_tunnel/services/domain_matcher.dart';

/// Правило провайдера из подписки (до нормализации).
@immutable
class SubscriptionSplitRule {
  /// Создаёт правило провайдера.
  const SubscriptionSplitRule({
    required this.type,
    required this.patterns,
    required this.action,
    this.name,
  });

  /// Сырой тип правила из контракта.
  final String type;

  /// Паттерны правила.
  final List<String> patterns;

  /// Действие.
  final RuleAction action;

  /// Человекочитаемое имя (не используется в конфиге).
  final String? name;

  /// Маппинг контрактного типа на [RuleType]; null — не поддерживается.
  static RuleType? _mapType(String raw) => switch (raw) {
        'domain_suffix' => RuleType.domainSuffix,
        'domain_keyword' => RuleType.domainKeyword,
        'domain_exact' || 'domain' => RuleType.domain,
        'ip_cidr' => RuleType.ipCidr,
        'geoip' => RuleType.geoip,
        'process' || 'package_name' => RuleType.app,
        _ => null,
      };

  /// Восстанавливает правило из JSON.
  factory SubscriptionSplitRule.fromJson(Map<String, dynamic> json) =>
      SubscriptionSplitRule(
        type: (json['type'] as String? ?? '').trim().toLowerCase(),
        patterns: List.unmodifiable([
          for (final pattern in (json['patterns'] as List? ?? const []))
            if (pattern is String) pattern.trim(),
        ]),
        action: RuleAction.fromName(json['action'] as String?),
        name: json['name'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        'type': type,
        'patterns': patterns,
        'action': action.name,
      };
}

/// Описание внешнего бинарного `.srs`-набора правил провайдера.
@immutable
class SubscriptionRuleSet {
  /// Создаёт описание rule-set'а.
  const SubscriptionRuleSet({
    required this.id,
    required this.url,
    required this.action,
    this.sha256,
  });

  /// Стабильный идентификатор (используется как тег и имя кэша).
  final String id;

  /// URL скачивания `.srs`-файла.
  final String url;

  /// Действие маршрутизации (`proxy` / `direct` / `block`).
  final RuleAction action;

  /// Ожидаемая контрольная сумма sha256 (если задана провайдером).
  final String? sha256;

  /// Восстанавливает описание из JSON.
  factory SubscriptionRuleSet.fromJson(Map<String, dynamic> json) =>
      SubscriptionRuleSet(
        id: (json['id'] as String? ?? json['tag'] as String? ?? '').trim(),
        url: (json['url'] as String? ?? '').trim(),
        action: RuleAction.fromName(json['action'] as String? ?? 'direct'),
        sha256: (json['sha256'] as String?)?.trim(),
      );

  /// Сериализует описание в JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'action': action.name,
        if (sha256 != null && sha256!.isNotEmpty) 'sha256': sha256,
      };
}

/// Блок `features.split_tunnel` подписки.
@immutable
class SubscriptionSplitTunnel {
  /// Создаёт блок.
  const SubscriptionSplitTunnel({
    required this.enabled,
    required this.rules,
    this.ruleSets = const <SubscriptionRuleSet>[],
    this.defaultAction = RuleAction.proxy,
  });

  /// Включён ли split tunneling у провайдера.
  final bool enabled;

  /// Правила провайдера.
  final List<SubscriptionSplitRule> rules;

  /// Внешние `.srs`-наборы правил (правило 32).
  final List<SubscriptionRuleSet> ruleSets;

  /// Действие по умолчанию.
  final RuleAction defaultAction;

  /// Восстанавливает блок из JSON.
  factory SubscriptionSplitTunnel.fromJson(Map<String, dynamic> json) =>
      SubscriptionSplitTunnel(
        enabled: json['enabled'] as bool? ?? false,
        defaultAction: RuleAction.fromName(
          json['default_action'] as String? ?? 'proxy',
        ),
        rules: List.unmodifiable([
          for (final entry in (json['rules'] as List? ?? const []))
            if (entry is Map<String, dynamic>)
              SubscriptionSplitRule.fromJson(entry),
        ]),
        ruleSets: List.unmodifiable([
          for (final entry in (json['rule_sets'] as List? ?? const []))
            if (entry is Map<String, dynamic> &&
                (entry['id'] ?? entry['tag']) is String &&
                entry['url'] is String)
              SubscriptionRuleSet.fromJson(entry),
        ]),
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'default_action': defaultAction.name,
        'rules': [for (final rule in rules) rule.toJson()],
        if (ruleSets.isNotEmpty)
          'rule_sets': [for (final set in ruleSets) set.toJson()],
      };

  /// Транслирует правила провайдера в [SplitRule] приложения.
  ///
  /// Id детерминированные (`provider:<type>:<pattern>`), применение
  /// идемпотентно. Неподдерживаемые типы пропускаются. Доменные
  /// паттерны нормализуются (`.ru` → `ru`).
  List<SplitRule> toSplitRules() {
    final result = <SplitRule>[];
    for (final rule in rules) {
      final type = SubscriptionSplitRule._mapType(rule.type);
      if (type == null) continue;

      if (type.isMultiValue) {
        if (rule.patterns.isEmpty) continue;
        result.add(
          SplitRule(
            id: 'provider:${rule.type}:${rule.patterns.join(',')}',
            type: type,
            pattern: rule.patterns.join(', '),
            action: rule.action,
            builtin: true,
          ),
        );
      } else {
        for (final pattern in rule.patterns) {
          final normalized = DomainMatcher.normalize(pattern);
          if (normalized.isEmpty) continue;
          result.add(
            SplitRule(
              id: 'provider:${rule.type}:$normalized',
              type: type,
              pattern: normalized,
              action: rule.action,
              builtin: true,
            ),
          );
        }
      }
    }
    return result;
  }
}
