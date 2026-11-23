/// Иммутабельная модель правила раздельного туннелирования.
library;

import 'package:meta/meta.dart';

import 'rule_action.dart';
import 'rule_type.dart';

/// Правило маршрутизации трафика (Split Tunneling).
///
/// Совпавший с [pattern] трафик направляется согласно [action].
/// Порядок применения правил определяется их позицией в списке
/// контроллера — первое совпадение выигрывает.
@immutable
class SplitRule {
  /// Создаёт правило.
  const SplitRule({
    required this.id,
    required this.type,
    required this.pattern,
    required this.action,
    this.enabled = true,
    this.builtin = false,
  });

  /// Уникальный идентификатор правила.
  ///
  /// Пользовательские: `user:<timestamp>`;
  /// из пресетов: `preset:<setId>:<pattern>` (детерминированный).
  final String id;

  /// Тип сопоставления.
  final RuleType type;

  /// Паттерн (домен, CIDR, regex, GeoIP-код или пакет приложения).
  final String pattern;

  /// Действие над совпавшим трафиком.
  final RuleAction action;

  /// Активно ли правило (выключенное не попадает в конфигурацию).
  final bool enabled;

  /// Правило пришло из предустановленного набора.
  final bool builtin;

  /// Восстанавливает правило из JSON хранилища.
  factory SplitRule.fromJson(Map<String, dynamic> json) => SplitRule(
        id: (json['id'] as String? ?? '').trim(),
        type: RuleType.fromName(json['type'] as String?),
        pattern: (json['pattern'] as String? ?? '').trim(),
        action: RuleAction.fromName(json['action'] as String?),
        enabled: json['enabled'] as bool? ?? true,
        builtin: json['builtin'] as bool? ?? false,
      );

  /// Сериализует правило в JSON для хранилища.
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.singBoxKey,
        'pattern': pattern,
        'action': action.name,
        'enabled': enabled,
        'builtin': builtin,
      };

  /// Копия правила с заменёнными полями.
  SplitRule copyWith({
    String? id,
    RuleType? type,
    String? pattern,
    RuleAction? action,
    bool? enabled,
    bool? builtin,
  }) =>
      SplitRule(
        id: id ?? this.id,
        type: type ?? this.type,
        pattern: pattern ?? this.pattern,
        action: action ?? this.action,
        enabled: enabled ?? this.enabled,
        builtin: builtin ?? this.builtin,
      );

  @override
  bool operator ==(Object other) =>
      other is SplitRule &&
      other.id == id &&
      other.type == type &&
      other.pattern == pattern &&
      other.action == action &&
      other.enabled == enabled &&
      other.builtin == builtin;

  @override
  int get hashCode => Object.hash(id, type, pattern, action, enabled, builtin);

  @override
  String toString() =>
      'SplitRule($id, ${type.singBoxKey} $pattern → ${action.outboundTag}'
      '${enabled ? '' : ', off'})';
}
