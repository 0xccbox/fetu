/// Движок правил раздельного туннелирования.
///
/// Отвечает за локальное разрешение действия по правилам
/// (первое совпадение выигрывает) и за трансляцию активных
/// правил в JSON-секцию route.rules конфигурации sing-box.
library;

import '../../../core/constants/split_tunnel_constants.dart';
import '../models/rule_action.dart';
import '../models/rule_type.dart';
import '../models/split_rule.dart';
import 'domain_matcher.dart';

/// Исключение: превышен лимит инлайн-правил (AGENTS.md, правило 32).
class SplitRuleLimitException implements Exception {
  /// Лимит, который был превышен.
  final int limit;

  const SplitRuleLimitException(this.limit);

  @override
  String toString() =>
      'SplitRuleLimitException: превышен лимит инлайн-правил ($limit); '
      'большие списки подключаются .srs-наборами (ФАЗА 9)';
}

/// Движок применения правил к трафику.
class RuleEngine {
  const RuleEngine();

  /// Действие по умолчанию, если ни одно правило не совпало.
  ///
  /// Соответствует `route.final = 'proxy'`: весь неопознанный
  /// трафик идёт через VPN (защита от утечек, AGENTS.md правило 18).
  static const RuleAction defaultAction = RuleAction.proxy;

  /// Разрешает действие для [domain] по списку [rules].
  ///
  /// Правила проверяются сверху вниз, побеждает первое совпадение.
  /// Выключенные правила и не-доменные типы (ip_cidr/geoip/app)
  /// пропускаются — их матчит сам sing-box.
  RuleAction resolveActionForDomain(String domain, List<SplitRule> rules) {
    for (final rule in rules) {
      if (!rule.enabled || !rule.type.isDomainBased) continue;
      if (DomainMatcher.matches(domain, rule.type, rule.pattern)) {
        return rule.action;
      }
    }
    return defaultAction;
  }

  /// Транслирует активные правила в route.rules для sing-box.
  ///
  /// Каждое правило становится отдельным JSON-объектом с сохранением
  /// порядка (в sing-box побеждает первое совпадение). Многозначные
  /// типы (ip_cidr/geoip/app) разбивают паттерн на список значений.
  ///
  /// Throws: [SplitRuleLimitException] если активных правил больше
  /// [SplitTunnelConstants.maxInlineRules].
  static List<Map<String, dynamic>> buildRouteRules(List<SplitRule> rules) {
    final active = rules.where((r) => r.enabled).toList();
    if (active.length > SplitTunnelConstants.maxInlineRules) {
      throw const SplitRuleLimitException(SplitTunnelConstants.maxInlineRules);
    }
    return [for (final rule in active) _ruleToJson(rule)];
  }

  static Map<String, dynamic> _ruleToJson(SplitRule rule) {
    final values = rule.type.isMultiValue
        ? [
            for (final v in rule.pattern.split(RegExp(r'[,\s]+')))
              if (v.isNotEmpty) _normalizeMultiValue(rule.type, v),
          ]
        : [_patternValue(rule)];
    return {
      rule.type.singBoxKey: values,
      if (rule.action == RuleAction.block)
        'action': 'reject'
      else
        'outbound': rule.action.outboundTag,
    };
  }

  /// Нормализация многозначного значения.
  ///
  /// Имена Android-пакетов регистрозависимы — не приводятся к нижнему
  /// регистру (Java-конвенция); GeoIP-коды, наоборот, всегда нижние.
  static String _normalizeMultiValue(RuleType type, String value) =>
      type == RuleType.app ? value.trim() : value.trim().toLowerCase();

  /// Значение паттерна для однозначных типов.
  ///
  /// Regex не нормализуется регистром (иначе сломаются `[A-Z]`-классы),
  /// доменные типы приводятся к каноническому виду.
  static String _patternValue(SplitRule rule) {
    final pattern = rule.pattern.trim();
    return rule.type == RuleType.domainRegex
        ? pattern
        : DomainMatcher.normalize(pattern);
  }
}
