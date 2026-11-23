/// Модели каскадной маршрутизации подписки (`features.cascade`, контракт v2).
///
/// Описывает входные релеи (`relays`), связи резервирования (`backup_relay_ids`)
/// и привязку выходных узлов (`attached_exit_nodes`).
library;

import 'package:meta/meta.dart';

import '../../connection/models/server_node.dart';
import 'node_domain_entry.dart';
import 'node_protocol.dart';
import 'subscription_node.dart';

/// Режим топологии каскадов.
enum CascadeTopologyMode {
  /// Автоматическое переключение по графу `backup_relay_ids` и общим нодам.
  autoMesh,

  /// Изолированные ветки: релеи не взаимозаменяемы напрямую без смены выходной ноды.
  isolated,

  /// Одиночный входной каскад.
  single;

  /// Восстанавливает режим из контрактной строки `topology_mode`.
  factory CascadeTopologyMode.fromName(String? raw) =>
      switch (raw?.trim().toLowerCase()) {
        'auto_mesh' || 'automesh' => CascadeTopologyMode.autoMesh,
        'isolated' => CascadeTopologyMode.isolated,
        'single' => CascadeTopologyMode.single,
        _ => CascadeTopologyMode.autoMesh,
      };

  /// Контрактное имя для JSON.
  String get wireName => switch (this) {
        CascadeTopologyMode.autoMesh => 'auto_mesh',
        CascadeTopologyMode.isolated => 'isolated',
        CascadeTopologyMode.single => 'single',
      };
}

/// Входной каскадный узел (`features.cascade.relays[]`).
@immutable
class CascadeRelay {
  /// Создаёт описание входного каскадного релея.
  const CascadeRelay({
    required this.id,
    required this.name,
    this.priority = 999,
    this.backupRelayIds = const <String>[],
    this.attachedExitNodes = const <String>[],
    this.domains = const <NodeDomainEntry>[],
    this.protocols = const <NodeProtocol>[],
    this.interNodeProtection = const <String, dynamic>{},
    this.country,
  });

  /// Уникальный идентификатор релея (`cascade-msk-1`).
  final String id;

  /// Отображаемое имя релея.
  final String name;

  /// Приоритет выбора (меньше = выше).
  final int priority;

  /// Идентификаторы резервных релеев при падении текущего.
  final List<String> backupRelayIds;

  /// Идентификаторы выходных узлов, привязанных к этому релею.
  final List<String> attachedExitNodes;

  /// Адреса релея (домены или IP).
  final List<NodeDomainEntry> domains;

  /// Протоколы релея.
  final List<NodeProtocol> protocols;

  /// Параметры межузловой защиты (`multiplex`, `padding`).
  final Map<String, dynamic> interNodeProtection;

  /// Необязательный код страны.
  final String? country;

  /// Восстанавливает релей из JSON.
  ///
  /// В контракте `domains` может быть списком строк `["msk1.myvpn.com"]`
  /// или списком объектов [NodeDomainEntry].
  factory CascadeRelay.fromJson(Map<String, dynamic> json) {
    final rawDomains = json['domains'] as List? ?? const [];
    final parsedDomains = <NodeDomainEntry>[];
    for (var i = 0; i < rawDomains.length; i++) {
      final entry = rawDomains[i];
      if (entry is String && entry.trim().isNotEmpty) {
        final addr = entry.trim();
        parsedDomains.add(
          NodeDomainEntry(
            address: addr,
            priority: i + 1,
            type: _inferDomainType(addr),
            status: i == 0 ? NodeDomainStatus.active : NodeDomainStatus.backup,
          ),
        );
      } else if (entry is Map<String, dynamic>) {
        parsedDomains.add(NodeDomainEntry.fromJson(entry));
      }
    }

    return CascadeRelay(
      id: (json['id'] as String? ?? '').trim(),
      name: (json['name'] as String? ?? '').trim(),
      priority: (json['priority'] as num?)?.toInt() ?? 999,
      backupRelayIds: List.unmodifiable([
        for (final item in (json['backup_relay_ids'] as List? ?? const []))
          if (item is String && item.trim().isNotEmpty) item.trim(),
      ]),
      attachedExitNodes: List.unmodifiable([
        for (final item in (json['attached_exit_nodes'] as List? ?? const []))
          if (item is String && item.trim().isNotEmpty) item.trim(),
      ]),
      domains: List.unmodifiable(parsedDomains),
      protocols: List.unmodifiable([
        for (final entry in (json['protocols'] as List? ?? const []))
          if (entry is Map<String, dynamic>) NodeProtocol.fromJson(entry),
      ]),
      interNodeProtection: _safeMap(json['inter_node_protection']),
      country: (json['country'] as String?)?.trim(),
    );
  }

  static NodeDomainType _inferDomainType(String host) {
    final isIpv4 = RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(host);
    final isIpv6 = host.contains(':');
    return (isIpv4 || isIpv6) ? NodeDomainType.ip : NodeDomainType.domain;
  }

  static Map<String, dynamic> _safeMap(Object? value) {
    if (value is! Map) return const <String, dynamic>{};
    try {
      return Map.unmodifiable(Map<String, dynamic>.from(value));
    } catch (_) {
      return const <String, dynamic>{};
    }
  }

  /// Сериализует релей в JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'priority': priority,
        if (backupRelayIds.isNotEmpty) 'backup_relay_ids': backupRelayIds,
        if (attachedExitNodes.isNotEmpty)
          'attached_exit_nodes': attachedExitNodes,
        if (country != null) 'country': country,
        'domains': [for (final d in domains) d.toJson()],
        'protocols': [for (final p in protocols) p.toJson()],
        if (interNodeProtection.isNotEmpty)
          'inter_node_protection': interNodeProtection,
      };

  /// Лучший адрес релея (active → backup → fallback).
  String? get primaryAddress {
    if (domains.isEmpty) return null;
    return domains
        .reduce((a, b) => _domainRank(a) <= _domainRank(b) ? a : b)
        .address;
  }

  static int _domainRank(NodeDomainEntry entry) =>
      entry.status.index * 1000 + entry.priority;

  /// Лучший поддерживаемый протокол релея (исключая WireGuard/AWG endpoint-ы,
  /// которые не могут работать как outbound `detour` в sing-box).
  NodeProtocol? get bestProtocol {
    final candidates = toProtocolCandidates();
    if (candidates.isEmpty) return null;
    final supported = protocols.where((p) {
      final type = p.protocolType;
      return type != null &&
          type != ProtocolType.wireguard &&
          type != ProtocolType.amneziaWg;
    }).toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
    return supported.isEmpty ? null : supported.first;
  }

  /// Конвертирует релей в [ServerNode] для передачи в `relayNode`.
  ServerNode? toServerNode() {
    final candidates = toProtocolCandidates();
    return candidates.isEmpty ? null : candidates.first;
  }

  /// Возвращает все поддерживаемые протоколы релея в порядке приоритета.
  List<ServerNode> toProtocolCandidates() {
    final address = primaryAddress;
    if (address == null || address.isEmpty) return const <ServerNode>[];

    final supported = protocols.where((p) {
      final type = p.protocolType;
      return type != null &&
          type != ProtocolType.wireguard &&
          type != ProtocolType.amneziaWg;
    }).toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));

    return [
      for (final p in supported)
        ServerNode(
          id: id,
          name: name.isEmpty ? id : name,
          countryCode: country ?? 'RU',
          address: address,
          protocol: p.protocolType!,
          config: SubscriptionNode.buildProtocolConfig(p),
        ),
    ];
  }

  @override
  bool operator ==(Object other) =>
      other is CascadeRelay && other.id == id && other.priority == priority;

  @override
  int get hashCode => Object.hash(id, priority);

  @override
  String toString() => 'CascadeRelay($id, p$priority, ${protocols.length}p)';
}

/// Блок каскадной маршрутизации подписки (`features.cascade`).
@immutable
class SubscriptionCascade {
  /// Создаёт конфигурацию каскадов.
  const SubscriptionCascade({
    required this.enabled,
    this.clientAutoFailover = true,
    this.topologyMode = CascadeTopologyMode.autoMesh,
    this.relays = const <CascadeRelay>[],
    this.domainRotation = const <String, dynamic>{},
    this.protocolFailover = const <String, dynamic>{},
    this.serverSelection = const <String, dynamic>{},
  });

  /// Включена ли каскадная маршрутизация.
  final bool enabled;

  /// Разрешено ли клиентское авто-переключение каскада при сбое.
  final bool clientAutoFailover;

  /// Режим топологии (`auto_mesh` / `isolated` / `single`).
  final CascadeTopologyMode topologyMode;

  /// Входные каскадные релеи.
  final List<CascadeRelay> relays;

  /// Сырой блок настроек ротации доменов.
  final Map<String, dynamic> domainRotation;

  /// Сырой блок настроек protocol_failover.
  final Map<String, dynamic> protocolFailover;

  /// Сырой блок настроек server_selection.
  final Map<String, dynamic> serverSelection;

  /// Восстанавливает блок каскада из JSON.
  factory SubscriptionCascade.fromJson(Map<String, dynamic> json) =>
      SubscriptionCascade(
        enabled: json['enabled'] as bool? ?? false,
        clientAutoFailover: json['client_auto_failover'] as bool? ?? true,
        topologyMode:
            CascadeTopologyMode.fromName(json['topology_mode'] as String?),
        relays: List.unmodifiable([
          for (final entry in (json['relays'] as List? ?? const []))
            if (entry is Map<String, dynamic>) CascadeRelay.fromJson(entry),
        ]),
        domainRotation: CascadeRelay._safeMap(json['domain_rotation']),
        protocolFailover: CascadeRelay._safeMap(json['protocol_failover']),
        serverSelection: CascadeRelay._safeMap(json['server_selection']),
      );

  /// Сериализует блок каскада в JSON.
  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'client_auto_failover': clientAutoFailover,
        'topology_mode': topologyMode.wireName,
        if (relays.isNotEmpty)
          'relays': [for (final relay in relays) relay.toJson()],
        if (domainRotation.isNotEmpty) 'domain_rotation': domainRotation,
        if (protocolFailover.isNotEmpty) 'protocol_failover': protocolFailover,
        if (serverSelection.isNotEmpty) 'server_selection': serverSelection,
      };

  /// Возвращает упорядоченную цепочку входных релеев для выходного узла [exitNodeId].
  ///
  /// Логика:
  /// 1. Находит релеи, явно привязанные через `attached_exit_nodes`,
  ///    отсортированные по `priority` (если привязок нет ни у одного релея —
  ///    считает все релеи подходящими).
  /// 2. Разворачивает связанные резервные релеи через `backup_relay_ids`
  ///    (BFS без циклов).
  /// 3. В режиме `autoMesh` добавляет оставшиеся релеи в порядке `priority`
  ///    на случай падения всей основной ветки.
  List<CascadeRelay> resolveRelaysForExitNode(String exitNodeId) {
    if (!enabled || relays.isEmpty) return const <CascadeRelay>[];

    final byId = <String, CascadeRelay>{
      for (final relay in relays)
        if (relay.id.isNotEmpty) relay.id: relay,
    };
    final sorted = [...relays]
      ..sort((a, b) => a.priority.compareTo(b.priority));

    final hasExplicitAttachments =
        sorted.any((r) => r.attachedExitNodes.isNotEmpty);
    final primaryMatches = hasExplicitAttachments
        ? sorted.where((r) => r.attachedExitNodes.contains(exitNodeId)).toList()
        : sorted;

    if (primaryMatches.isEmpty &&
        topologyMode == CascadeTopologyMode.isolated) {
      return const <CascadeRelay>[];
    }

    final seeds = primaryMatches.isNotEmpty ? primaryMatches : sorted;
    final ordered = <CascadeRelay>[];
    final visited = <String>{};
    final queue = <CascadeRelay>[...seeds];

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final key = current.id.isNotEmpty ? current.id : current.name;
      if (!visited.add(key)) continue;
      ordered.add(current);

      if (clientAutoFailover) {
        for (final backupId in current.backupRelayIds) {
          final backup = byId[backupId];
          if (backup != null && !visited.contains(backup.id)) {
            queue.add(backup);
          }
        }
      }
    }

    if (clientAutoFailover && topologyMode == CascadeTopologyMode.autoMesh) {
      for (final relay in sorted) {
        final key = relay.id.isNotEmpty ? relay.id : relay.name;
        if (visited.add(key)) {
          ordered.add(relay);
        }
      }
    }

    return List.unmodifiable(ordered);
  }

  /// Преобразует разрешённые релеи для [exitNodeId] в список [ServerNode]
  /// (включая все протоколы каждого релея в порядке приоритета).
  List<ServerNode> resolveRelayServerNodes(String exitNodeId) {
    final resolved = resolveRelaysForExitNode(exitNodeId);
    final result = <ServerNode>[];
    for (final relay in resolved) {
      result.addAll(relay.toProtocolCandidates());
    }
    return List.unmodifiable(result);
  }
}
