/// Контроллер списка серверов, измерения задержек (кэш 5 минут)
/// и умного подбора через [SmartNodeScorer].
library;

import 'package:flutter/foundation.dart';

import '../../connection/models/server_node.dart';
import '../../subscription/models/subscription.dart';
import '../../subscription/models/subscription_node.dart';
import '../models/server_info.dart';
import '../services/network_profile_memory.dart';
import '../services/ping_service.dart';
import '../services/server_list_service.dart';
import '../services/smart_node_scorer.dart';

/// Провайдер актуальной подписки (внедряется через DI).
typedef ActiveSubscriptionProvider = Subscription? Function();

/// Контроллер фичи `servers/`.
class ServerListController extends ChangeNotifier {
  /// Создаёт контроллер серверов.
  ServerListController({
    required PingService pingService,
    required SmartNodeScorer scorer,
    ServerListService listService = const ServerListService(),
    NetworkProfileMemory? networkMemory,
    ActiveSubscriptionProvider? subscriptionProvider,
  })  : _pingService = pingService,
        _scorer = scorer,
        _listService = listService,
        _networkMemory = networkMemory,
        _subscriptionProvider = subscriptionProvider;

  final PingService _pingService;
  final SmartNodeScorer _scorer;
  final ServerListService _listService;
  final NetworkProfileMemory? _networkMemory;
  final ActiveSubscriptionProvider? _subscriptionProvider;

  final Map<String, ServerInfo> _cachedById = <String, ServerInfo>{};
  List<ServerInfo> _servers = const <ServerInfo>[];
  String? _countryFilter;
  ProtocolType? _protocolFilter;
  String _searchQuery = '';
  ServerSortOrder _sortOrder = ServerSortOrder.providerDefault;
  bool _isMeasuring = false;
  SmartSelectionResult? _lastSmartResult;

  /// Все серверы текущей подписки с кэшированными замерами.
  List<ServerInfo> get allServers => _servers;

  /// Отфильтрованный и отсортированный список серверов.
  List<ServerInfo> get filteredServers => _listService.filterAndSort(
        _servers,
        countryFilter: _countryFilter,
        protocolFilter: _protocolFilter,
        query: _searchQuery,
        sortOrder: _sortOrder,
      );

  /// Доступные страны для фильтрации.
  List<String> get availableCountries =>
      _listService.availableCountries(_servers);

  /// Текущий фильтр страны.
  String? get countryFilter => _countryFilter;

  /// Текущий фильтр протокола.
  ProtocolType? get protocolFilter => _protocolFilter;

  /// Поисковый запрос.
  String get searchQuery => _searchQuery;

  /// Текущая сортировка.
  ServerSortOrder get sortOrder => _sortOrder;

  /// Идёт ли замер задержек или умный подбор.
  bool get isMeasuring => _isMeasuring;

  /// Последний результат умного подбора.
  SmartSelectionResult? get lastSmartResult => _lastSmartResult;

  /// Возвращает кэшированный пинг узла (мс) или null.
  int? latencyForNode(String nodeId) => _cachedById[nodeId]?.latencyMs;

  /// Синхронизирует список серверов при изменении подписки.
  void syncWithSubscription([Subscription? subscription]) {
    final sub = subscription ?? _subscriptionProvider?.call();
    if (sub == null || sub.isExpired) {
      if (_servers.isNotEmpty || _lastSmartResult != null) {
        _servers = const <ServerInfo>[];
        _lastSmartResult = null;
        notifyListeners();
      }
      return;
    }

    _servers = _listService.buildServerList(
      sub.nodes,
      cachedById: _cachedById,
    );
    notifyListeners();
  }

  /// Измеряет задержку и рассчитывает [NodeHealthScore] для узлов подписки.
  ///
  /// При [forceRefresh] = false использует 5-минутный кэш (правило 22).
  Future<void> refreshLatencies({
    Subscription? subscription,
    bool forceRefresh = false,
  }) async {
    final sub = subscription ?? _subscriptionProvider?.call();
    if (sub == null || sub.isExpired || sub.nodes.isEmpty) return;
    if (_isMeasuring) return;

    _isMeasuring = true;
    notifyListeners();
    try {
      if (forceRefresh) {
        _pingService.clearCache();
      }
      final scored = await _scorer.scoreNodes(
        sub.nodes,
        cascade: sub.cascade,
        forceRefresh: forceRefresh,
      );
      for (final info in scored) {
        _cachedById[info.id] = info;
      }
      _servers = scored;
    } finally {
      _isMeasuring = false;
      notifyListeners();
    }
  }

  /// Запускает умный подбор лучшего узла (`SmartSelectionButton`).
  Future<SubscriptionNode?> selectSmartServer([
    Subscription? subscription,
  ]) async {
    final sub = subscription ?? _subscriptionProvider?.call();
    if (sub == null || sub.isExpired || sub.nodes.isEmpty) return null;
    if (_isMeasuring) return null;

    _isMeasuring = true;
    notifyListeners();
    try {
      final result = await _scorer.selectBestNode(
        sub.nodes,
        smartSelectionUrl: sub.branding?.smartSelectionUrl,
        cascade: sub.cascade,
      );
      if (result == null) return null;
      _lastSmartResult = result;
      for (final info in result.scoredServers) {
        _cachedById[info.id] = info;
      }
      _cachedById[result.server.id] = result.server;
      _servers = _listService.buildServerList(
        sub.nodes,
        cachedById: _cachedById,
      );
      return result.server.node;
    } finally {
      _isMeasuring = false;
      notifyListeners();
    }
  }

  /// Записывает успешное подключение для памяти сетевого профиля.
  Future<void> recordConnectionSuccess({
    required ProtocolType protocol,
    String? relayId,
  }) async {
    await _networkMemory?.recordSuccess(protocol: protocol, relayId: relayId);
  }

  void setCountryFilter(String? country) {
    _countryFilter = country == _countryFilter ? null : country;
    notifyListeners();
  }

  void setProtocolFilter(ProtocolType? protocol) {
    _protocolFilter = protocol == _protocolFilter ? null : protocol;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  void setSortOrder(ServerSortOrder order) {
    if (_sortOrder == order) return;
    _sortOrder = order;
    notifyListeners();
  }
}
