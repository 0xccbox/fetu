import 'package:fetu/core/network/http_connection_pool.dart';
import 'package:fetu/core/storage/key_value_storage.dart';
import 'package:fetu/design_system/theme/theme_controller.dart';
import 'package:fetu/design_system/typography/app_typography.dart';
import 'package:fetu/features/connection/controllers/connection_controller.dart';
import 'package:fetu/features/connection/services/vpn_connection_service.dart';
import 'package:fetu/features/diagnostics/controllers/diagnostics_controller.dart';
import 'package:fetu/features/diagnostics/models/diagnostic_report.dart';
import 'package:fetu/features/diagnostics/services/diagnostic_report_builder.dart';
import 'package:fetu/features/diagnostics/services/real_delay_probe.dart';
import 'package:fetu/features/failover/services/failover_orchestrator.dart';
import 'package:fetu/features/failover/services/protocol_health_monitor.dart';
import 'package:fetu/features/servers/controllers/server_list_controller.dart';
import 'package:fetu/features/servers/services/network_profile_memory.dart';
import 'package:fetu/features/servers/services/ping_service.dart';
import 'package:fetu/features/servers/services/smart_node_scorer.dart';
import 'package:fetu/features/settings/controllers/settings_controller.dart';
import 'package:fetu/features/settings/models/subscription_keys.dart';
import 'package:fetu/features/settings/services/settings_service.dart';
import 'package:fetu/features/split_tunnel/controllers/split_tunnel_controller.dart';
import 'package:fetu/features/subscription/controllers/subscription_controller.dart';
import 'package:get_it/get_it.dart';

import 'test_storage.dart';

final GetIt sl = GetIt.instance;

/// Настраивает зависимости для тестового окружения.
///
/// Использует mock-реализации (TestStorage вместо HiveStorage)
/// для избежания зависимостей от нативных плагинов.
Future<void> setupTestDependencies({SubscriptionFetcher? fetcher}) async {
  AppTypography.useSystemFonts = true;

  // 1. Используем in-memory storage для тестов
  final testStorage = TestStorage();
  await testStorage.init();
  sl.registerLazySingleton<KeyValueStorage>(() => testStorage);

  // 2. Регистрируем HTTP Connection Pool
  sl.registerLazySingleton<HttpConnectionPool>(
    () => HttpConnectionPool.instance,
  );

  // 3. Регистрируем контроллер темы
  final themeController = ThemeController(sl<KeyValueStorage>());
  await themeController.initialize();
  sl.registerLazySingleton<ThemeController>(() => themeController);

  // 4. Регистрируем контроллер настроек (ФАЗА 10): режим
  //    интерфейса в TestStorage; ключи подписки — фейковый
  //    провайдер без secure-storage (нативный плагин недоступен).
  final settingsController = SettingsController(
    service: SettingsService(storage: sl<KeyValueStorage>()),
    keyStore: null,
  );
  await settingsController.initialize();
  sl.registerLazySingleton<SettingsController>(() => settingsController);

  // 5. Регистрируем failover и VPN connection service.
  sl.registerLazySingleton<FailoverOrchestrator>(
    () => FailoverOrchestrator(
      healthMonitor: ProtocolHealthMonitor(
        healthProbe: (_) async => true,
        canaryProbe: (_, __) async => true,
      ),
    ),
  );
  sl.registerLazySingleton<VpnConnectionService>(
    () => VpnConnectionService(
      splitRulesProvider: () => sl<SplitTunnelController>().activeRules,
      ruleSetsProvider: () => sl<SubscriptionController>().activeRuleSets,
    ),
  );
  sl.registerLazySingleton<ConnectionController>(
    () => ConnectionController(sl<VpnConnectionService>()),
  );

  // 6. Регистрируем контроллер Split Tunneling (test-хранилище).
  final splitTunnelController = SplitTunnelController(
    storage: testStorage,
    onRulesChanged: () => sl<VpnConnectionService>().applySplitRules(),
  );
  await splitTunnelController.initialize();
  sl.registerLazySingleton<SplitTunnelController>(() => splitTunnelController);

  // 7. Регистрируем контроллер подписок (test-хранилище, без сети;
  //    ключи vpn:// — инъекцируемая заглушка для тестов).
  final subscriptionController = SubscriptionController(
    storage: testStorage,
    fetcher: fetcher ?? ((_) async => ''),
    keysProvider: () async => const SubscriptionKeys(),
  );
  await subscriptionController.initialize();
  sl.registerLazySingleton<SubscriptionController>(
    () => subscriptionController,
  );

  // 7.5. Регистрируем фичу серверов без реальных сокетов в тестах.
  final pingService = PingService(
    tcpProbe: (_, __, ___) async => const Duration(milliseconds: 28),
    realDelayProbe: (_, __) async => const Duration(milliseconds: 42),
  );
  final networkMemory = NetworkProfileMemory(
    storage: testStorage,
    fingerprintProvider: () async => 'test:default',
  );
  final scorer = SmartNodeScorer(
    pingService: pingService,
    networkMemory: networkMemory,
    apiFetcher: (_) async => null,
  );
  final serverListController = ServerListController(
    pingService: pingService,
    scorer: scorer,
    networkMemory: networkMemory,
    subscriptionProvider: () => sl<SubscriptionController>().subscription,
  )..syncWithSubscription(subscriptionController.subscription);
  subscriptionController.addListener(
    () => serverListController.syncWithSubscription(
      subscriptionController.subscription,
    ),
  );
  sl.registerLazySingleton<PingService>(() => pingService);
  sl.registerLazySingleton<NetworkProfileMemory>(() => networkMemory);
  sl.registerLazySingleton<SmartNodeScorer>(() => scorer);
  sl.registerLazySingleton<ServerListController>(() => serverListController);

  // 8. Регистрируем контроллер диагностики (ФАЗА 10): зонд без сети.
  sl.registerLazySingleton<DiagnosticsController>(
    () => DiagnosticsController(
      builder: DiagnosticReportBuilder(
        snapshotProvider: () => DiagnosticSnapshot(
          uiMode: sl<SettingsController>().mode,
          tunnelMode: 'mock',
          connectionState: sl<ConnectionController>().state,
          protocol: sl<ConnectionController>().currentNode?.protocol,
          metrics: sl<ConnectionController>().state.isActive
              ? sl<ConnectionController>().metrics
              : null,
          activeSplitRules: sl<SplitTunnelController>().activeRules.length,
          totalSplitRules: sl<SplitTunnelController>().rules.length,
          providerName: sl<SubscriptionController>().subscription?.name,
          subscriptionExpiresAt:
              sl<SubscriptionController>().subscription?.expireAt,
          subscriptionNodeCount:
              sl<SubscriptionController>().subscription?.nodes.length,
          developerMeta:
              sl<SubscriptionController>().subscription?.cabinet?.developerMeta,
        ),
      ),
      probe: RealDelayProbe(
        probeImpl: (_, __) async => const Duration(milliseconds: 42),
      ),
      isTunnelActive: () => sl<ConnectionController>().state.isActive,
    )..refresh(),
  );
}
