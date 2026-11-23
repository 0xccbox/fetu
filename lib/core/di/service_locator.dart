import 'dart:async';

import 'package:fetu/core/network/http_connection_pool.dart';
import 'package:fetu/core/storage/hive_storage.dart';
import 'package:fetu/core/storage/key_value_storage.dart';
import 'package:fetu/core/storage/secure_subscription_storage.dart';
import 'package:fetu/core/storage/serialized_secure_storage.dart';
import 'package:fetu/design_system/theme/theme_controller.dart';
import 'package:fetu/features/connection/controllers/connection_controller.dart';
import 'package:fetu/features/connection/models/connection_state.dart';
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
import 'package:fetu/features/settings/services/settings_service.dart';
import 'package:fetu/features/settings/services/subscription_key_store.dart';
import 'package:fetu/features/split_tunnel/controllers/split_tunnel_controller.dart';
import 'package:fetu/features/subscription/controllers/subscription_controller.dart';
import 'package:fetu/features/subscription/services/ruleset_cache_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

/// Глобальный экземпляр Service Locator для инъекции зависимостей.
final GetIt sl = GetIt.instance;

/// Инициализирует базовые зависимости приложения.
///
/// Вызывается один раз при запуске в [main()].
/// Регистрирует все синглтоны и сервисы Core-слоя.
Future<void> setupDependencies() async {
  // 1. Инициализируем и регистрируем локальное хранилище.
  final hiveStorage = HiveStorage();
  await hiveStorage.init();
  sl.registerLazySingleton<KeyValueStorage>(() => hiveStorage);

  // 2. Регистрируем HTTP Connection Pool (синглтон уже создан внутри).
  sl.registerLazySingleton<HttpConnectionPool>(
    () => HttpConnectionPool.instance,
  );

  // 3. Регистрируем контроллер темы
  final themeController = ThemeController(sl<KeyValueStorage>());
  try {
    await themeController.initialize();
  } catch (_) {}
  sl.registerLazySingleton<ThemeController>(() => themeController);

  // Одинаковые Android-настройки для подписки и её ключей: плагин
  // мигрирует уже записанные значения при переходе на EncryptedSharedPreferences.
  final secureStorage = SerializedSecureStorage(
    const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );
  final settingsController = SettingsController(
    service: SettingsService(storage: sl<KeyValueStorage>()),
    keyStore: SubscriptionKeyStore(serialized: secureStorage),
  );
  try {
    await settingsController.initialize();
  } catch (_) {}
  sl.registerLazySingleton<SettingsController>(() => settingsController);

  // 5. Регистрируем менеджер .srs кэша (правило 32), failover и VPN service.
  sl.registerLazySingleton<RuleSetCacheManager>(
    () => RuleSetCacheManager(storage: sl<KeyValueStorage>()),
  );
  sl.registerLazySingleton<ProtocolHealthMonitor>(ProtocolHealthMonitor.new);
  sl.registerLazySingleton<FailoverOrchestrator>(
    () => FailoverOrchestrator(healthMonitor: sl<ProtocolHealthMonitor>()),
  );

  sl.registerLazySingleton<VpnConnectionService>(() {
    final service = VpnConnectionService(
      splitRulesProvider: () => sl<SplitTunnelController>().activeRules,
      ruleSetsProvider: () => sl<SubscriptionController>().activeRuleSets,
    );
    final failover = sl<FailoverOrchestrator>();
    failover.bindSwitchHandler(service.switchProtocol);
    failover.bindRelaySwitchHandler(service.switchToBackupRelay);

    service.stateStream.listen((state) {
      final node = service.currentNode;
      if (state == ConnectionState.connected && node != null) {
        unawaited(
          failover.start(
            node,
            node.protocol,
            availableProtocols: service.availableProtocols,
            canaryTcpPort: service.canaryTcpPort,
          ),
        );
        if (sl.isRegistered<ServerListController>()) {
          unawaited(
            sl<ServerListController>().recordConnectionSuccess(
              protocol: node.protocol,
              relayId: service.currentRelayNode?.id,
            ),
          );
        }
      } else if (state == ConnectionState.disconnected) {
        unawaited(failover.stop());
      }
    });
    service.coreErrorStream.listen(failover.reportCoreError);
    return service;
  });
  sl.registerLazySingleton<ConnectionController>(
    () => ConnectionController(sl<VpnConnectionService>()),
  );

  // 6. Регистрируем контроллер Split Tunneling.
  //    После каждого изменения правил конфигурация активного туннеля
  //    перезагружается без разрыва (Zero-Drop Live Reload, правило 8).
  final splitTunnelController = SplitTunnelController(
    storage: sl<KeyValueStorage>(),
    onRulesChanged: () => sl<VpnConnectionService>().applySplitRules(),
  );
  try {
    await splitTunnelController.initialize();
  } catch (_) {}
  sl.registerLazySingleton<SplitTunnelController>(() => splitTunnelController);

  // 7. Регистрируем контроллер подписок (ФАЗА 9) и автообновление.
  //    Загрузчик по умолчанию — общий HTTP-пул (правило 3);
  //    ключи vpn:// приходят из настроек (secure-storage).
  final subscriptionController = SubscriptionController(
    storage: SecureSubscriptionStorage(
      secure: secureStorage,
      legacy: hiveStorage,
      compactLegacy: hiveStorage.compact,
    ),
    keysProvider: () => sl<SettingsController>().loadKeys(),
    ruleSetCacheManager: sl<RuleSetCacheManager>(),
    onRuleSetsUpdated: () =>
        unawaited(sl<VpnConnectionService>().applySplitRules()),
    enableAutoUpdate: true,
  );
  await subscriptionController.initialize();
  sl.registerLazySingleton<SubscriptionController>(
    () => subscriptionController,
  );

  // 7.5. Регистрируем фичу серверов: PingService (кэш 5 мин),
  //      NetworkProfileMemory, SmartNodeScorer и ServerListController.
  final networkMemory = NetworkProfileMemory(storage: sl<KeyValueStorage>());
  try {
    await networkMemory.initialize();
  } catch (_) {}
  sl.registerLazySingleton<NetworkProfileMemory>(() => networkMemory);
  sl.registerLazySingleton<PingService>(PingService.new);
  sl.registerLazySingleton<SmartNodeScorer>(
    () => SmartNodeScorer(
      pingService: sl<PingService>(),
      networkMemory: sl<NetworkProfileMemory>(),
    ),
  );
  final serverListController = ServerListController(
    pingService: sl<PingService>(),
    scorer: sl<SmartNodeScorer>(),
    networkMemory: sl<NetworkProfileMemory>(),
    subscriptionProvider: () => sl<SubscriptionController>().subscription,
  )..syncWithSubscription(subscriptionController.subscription);
  subscriptionController.addListener(
    () => serverListController.syncWithSubscription(
      subscriptionController.subscription,
    ),
  );
  sl.registerLazySingleton<ServerListController>(() => serverListController);

  // 8. Регистрируем контроллер диагностики (ФАЗА 10): снимок
  //    состояния собирается здесь, в композиционном корне, — фичи
  //    не импортируют чужие контроллеры (правило зависимостей).
  sl.registerLazySingleton<DiagnosticsController>(
    () {
      final controller = DiagnosticsController(
        builder: DiagnosticReportBuilder(
          snapshotProvider: _buildDiagnosticSnapshot,
        ),
        probe: RealDelayProbe(),
        isTunnelActive: () => sl<ConnectionController>().state.isActive,
      )..refresh();
      return controller;
    },
  );
}

/// Собирает снимок состояния приложения для диагностического отчёта.
///
/// Композиционный корень — единственное место, где контроллеры
/// разных фич читаются вместе (правило зависимостей CODEBASE_MAP).
DiagnosticSnapshot _buildDiagnosticSnapshot() {
  final connection = sl<ConnectionController>();
  final splitTunnel = sl<SplitTunnelController>();
  final subscription = sl<SubscriptionController>().subscription;

  return DiagnosticSnapshot(
    uiMode: sl<SettingsController>().mode,
    tunnelMode: sl<VpnConnectionService>().mode.name,
    connectionState: connection.state,
    protocol: connection.currentNode?.protocol,
    metrics: connection.state.isActive ? connection.metrics : null,
    activeSplitRules: splitTunnel.activeRules.length,
    totalSplitRules: splitTunnel.rules.length,
    providerName: subscription?.branding?.appName ?? subscription?.name,
    subscriptionExpiresAt: subscription?.expireAt,
    subscriptionNodeCount: subscription?.nodes.length,
    developerMeta: subscription?.cabinet?.developerMeta,
  );
}
