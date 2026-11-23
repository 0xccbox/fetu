/// Сервис фильтрации, сортировки и сборки списка серверов из подписки.
library;

import '../../connection/models/server_node.dart';
import '../../subscription/models/subscription_node.dart';
import '../models/server_info.dart';

/// Режим сортировки серверов.
enum ServerSortOrder {
  /// По порядку провайдера.
  providerDefault,

  /// По возрастанию пинга (недоступные в конце).
  lowestLatency,

  /// По убыванию умного рейтинга [NodeHealthScore].
  bestScore,

  /// По алфавиту.
  alphabetical,
}

/// Сервис подготовки списка серверов.
class ServerListService {
  /// Создаёт сервис списка серверов.
  const ServerListService();

  /// Объединяет узлы подписки с кэшированными метриками [samplesById].
  List<ServerInfo> buildServerList(
    List<SubscriptionNode> nodes, {
    Map<String, ServerInfo> cachedById = const <String, ServerInfo>{},
  }) {
    return List.unmodifiable([
      for (final node in nodes)
        cachedById[node.id]?.copyWith(node: node) ?? ServerInfo(node: node),
    ]);
  }

  /// Фильтрует и сортирует список серверов.
  List<ServerInfo> filterAndSort(
    List<ServerInfo> servers, {
    String? countryFilter,
    ProtocolType? protocolFilter,
    String query = '',
    ServerSortOrder sortOrder = ServerSortOrder.providerDefault,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final normalizedCountry = countryFilter?.trim().toUpperCase();

    final filtered = servers.where((info) {
      if (normalizedCountry != null &&
          normalizedCountry.isNotEmpty &&
          info.country?.toUpperCase() != normalizedCountry) {
        return false;
      }
      if (protocolFilter != null &&
          !info.node.protocols.any((p) => p.protocolType == protocolFilter)) {
        return false;
      }
      if (normalizedQuery.isNotEmpty) {
        final nameMatch = info.name.toLowerCase().contains(normalizedQuery);
        final cityMatch =
            (info.city ?? '').toLowerCase().contains(normalizedQuery);
        final countryMatch =
            (info.country ?? '').toLowerCase().contains(normalizedQuery);
        if (!nameMatch && !cityMatch && !countryMatch) return false;
      }
      return true;
    }).toList();

    switch (sortOrder) {
      case ServerSortOrder.providerDefault:
        break;
      case ServerSortOrder.lowestLatency:
        filtered.sort((a, b) {
          final latA = a.latencyMs ?? 1 << 30;
          final latB = b.latencyMs ?? 1 << 30;
          return latA.compareTo(latB);
        });
      case ServerSortOrder.bestScore:
        filtered.sort((a, b) {
          final scoreA = a.healthScore?.score ?? -1;
          final scoreB = b.healthScore?.score ?? -1;
          final cmp = scoreB.compareTo(scoreA);
          if (cmp != 0) return cmp;
          return (a.latencyMs ?? 1 << 30).compareTo(b.latencyMs ?? 1 << 30);
        });
      case ServerSortOrder.alphabetical:
        filtered.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
    }

    return List.unmodifiable(filtered);
  }

  /// Возвращает уникальный отсортированный список кодов стран в подписке.
  List<String> availableCountries(List<ServerInfo> servers) {
    final codes = <String>{
      for (final s in servers)
        if (s.country != null && s.country!.trim().isNotEmpty)
          s.country!.trim().toUpperCase(),
    }.toList()
      ..sort();
    return List.unmodifiable(codes);
  }
}
