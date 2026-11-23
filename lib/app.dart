import 'dart:async';

import 'package:fetu/core/di/service_locator.dart';
import 'package:fetu/design_system/design_system.dart';
import 'package:fetu/features/connection/controllers/connection_controller.dart';
import 'package:fetu/features/connection/screens/home_screen.dart';
import 'package:fetu/features/diagnostics/controllers/diagnostics_controller.dart';
import 'package:fetu/features/failover/models/failover_event.dart';
import 'package:fetu/features/failover/services/failover_orchestrator.dart';
import 'package:fetu/features/failover/widgets/failover_notification.dart';
import 'package:fetu/features/onboarding/screens/mode_selection_screen.dart';
import 'package:fetu/features/servers/controllers/server_list_controller.dart';
import 'package:fetu/features/settings/controllers/settings_controller.dart';
import 'package:fetu/features/split_tunnel/controllers/split_tunnel_controller.dart';
import 'package:fetu/features/subscription/controllers/subscription_controller.dart';
import 'package:fetu/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Корневой виджет приложения Fetu.
class FetuApp extends StatelessWidget {
  /// Создаёт корневой экземпляр [FetuApp].
  const FetuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ThemeController для переключения темы
        ChangeNotifierProvider<ThemeController>.value(
          value: sl<ThemeController>(),
        ),
        // SettingsController: режим интерфейса + ключи подписки (ФАЗА 10)
        ChangeNotifierProvider<SettingsController>.value(
          value: sl<SettingsController>(),
        ),
        // ConnectionController для управления VPN
        ChangeNotifierProvider<ConnectionController>.value(
          value: sl<ConnectionController>(),
        ),
        // SplitTunnelController для правил раздельного туннелирования
        ChangeNotifierProvider<SplitTunnelController>.value(
          value: sl<SplitTunnelController>(),
        ),
        // SubscriptionController для подписки и кабинета провайдера
        ChangeNotifierProvider<SubscriptionController>.value(
          value: sl<SubscriptionController>(),
        ),
        // ServerListController для измерения пинга (кэш 5 мин) и умного выбора
        ChangeNotifierProvider<ServerListController>.value(
          value: sl<ServerListController>(),
        ),
        // DiagnosticsController для экрана диагностики (ФАЗА 10)
        ChangeNotifierProvider<DiagnosticsController>.value(
          value: sl<DiagnosticsController>(),
        ),
      ],
      child: Builder(
        builder: (context) {
          final themeController = context.watch<ThemeController>();
          final settingsController = context.watch<SettingsController>();

          return MaterialApp(
            title: 'Fetu',
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeController.flutterThemeMode,
            // Локализация RU/EN (AGENTS.md, правило 14): язык системы;
            // неподдерживаемая локаль откатывается к шаблону (ru).
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) {
              if (child == null) return const SizedBox.shrink();
              if (!sl.isRegistered<FailoverOrchestrator>()) return child;
              return _FailoverOverlay(
                orchestrator: sl<FailoverOrchestrator>(),
                child: child,
              );
            },
            // Первый запуск: экран выбора режима (правило 33).
            home: settingsController.isModeSelected
                ? const HomeScreen()
                : const ModeSelectionScreen(),
          );
        },
      ),
    );
  }
}

class _FailoverOverlay extends StatefulWidget {
  const _FailoverOverlay({
    required this.orchestrator,
    required this.child,
  });

  final FailoverOrchestrator orchestrator;
  final Widget child;

  @override
  State<_FailoverOverlay> createState() => _FailoverOverlayState();
}

class _FailoverOverlayState extends State<_FailoverOverlay> {
  StreamSubscription<FailoverEvent>? _subscription;
  FailoverEvent? _latestEvent;
  Timer? _clearTimer;

  @override
  void initState() {
    super.initState();
    _subscription = widget.orchestrator.failoverEvents.listen((event) {
      if (!mounted) return;
      _clearTimer?.cancel();
      setState(() => _latestEvent = event);
      _clearTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _latestEvent = null);
      });
    });
  }

  @override
  void dispose() {
    _clearTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final event = _latestEvent;
    return Stack(
      children: [
        widget.child,
        if (event != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: FailoverNotification(
                key: ValueKey(event.timestamp),
                event: event,
              ),
            ),
          ),
      ],
    );
  }
}
