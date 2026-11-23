/// Описание локального бинарного `.srs` rule-set'а для sing-box.
library;

import 'package:meta/meta.dart';

import '../../split_tunnel/models/rule_action.dart';

/// Иммутабельная ссылка на кэшированный `.srs`-файл на устройстве.
@immutable
class LocalRuleSetRef {
  /// Создаёт ссылку на локальный `.srs`-файл.
  const LocalRuleSetRef({
    required this.tag,
    required this.path,
    this.action = RuleAction.direct,
  });

  /// Уникальный тег набора в `route.rule_set`.
  final String tag;

  /// Абсолютный путь к `.srs`-файлу на диске.
  final String path;

  /// Действие маршрутизации для совпавших адресов/доменов.
  final RuleAction action;

  @override
  bool operator ==(Object other) =>
      other is LocalRuleSetRef &&
      other.tag == tag &&
      other.path == path &&
      other.action == action;

  @override
  int get hashCode => Object.hash(tag, path, action);
}
