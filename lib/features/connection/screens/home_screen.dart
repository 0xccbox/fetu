import 'dart:async';

import 'package:fetu/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../servers/controllers/server_list_controller.dart';
import '../../subscription/controllers/subscription_controller.dart';
import '../../subscription/models/subscription.dart';
import '../../subscription/models/subscription_node.dart';
import '../../subscription/screens/subscription_screen.dart';
import '../../subscription/widgets/home_server_list.dart';
import '../../subscription/widgets/server_location.dart';
import '../controllers/connection_controller.dart';
import '../models/connection_state.dart' as vpn;
import '../widgets/compact_connect_button.dart';
import '../widgets/connection_panel.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_connection_header.dart';
import '../widgets/provider_links_bar.dart';
import '../widgets/smart_selection_button.dart';

/// Главный экран: единый скролл V4 на телефоне, две колонки на широком экране.
class HomeScreen extends StatefulWidget {
  /// Создаёт главный экран приложения.
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _wideBreakpoint = 600.0;
  static const _contentWidth = 1120.0;
  static const _scrollDuration = Duration(milliseconds: 300);

  final _mobileScroll = ScrollController();
  final _wideScroll = ScrollController();
  final _firstServer = FocusNode();
  final _serversAnchor = GlobalKey();
  ({Subscription source, SubscriptionNode node})? _selection;

  @override
  void dispose() {
    _mobileScroll.dispose();
    _wideScroll.dispose();
    _firstServer.dispose();
    super.dispose();
  }

  Future<void> _showServers({
    required bool wide,
    required double? offset,
  }) async {
    final scroll = wide ? _wideScroll : _mobileScroll;
    if (!scroll.hasClients || !scroll.position.hasContentDimensions) return;
    final position = scroll.position;
    final anchor = _serversAnchor.currentContext;
    if (offset == null && anchor != null) {
      await Scrollable.ensureVisible(
        anchor,
        duration: _scrollDuration,
        curve: Curves.easeOutCubic,
      );
    } else if (offset != null && (wide || position.pixels < offset)) {
      final target = offset.clamp(0.0, position.maxScrollExtent);
      if (position.pixels != target) {
        await scroll.animateTo(
          target,
          duration: _scrollDuration,
          curve: Curves.easeOutCubic,
        );
      }
    }
    if (mounted && _firstServer.context != null) _firstServer.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final subscriptions = context.watch<SubscriptionController>();
    final servers = context.watch<ServerListController>();
    final connection = context.read<ConnectionController>();
    // Смена метрик не перестраивает каркас экрана или список серверов.
    final subscription = subscriptions.subscription;
    final expired = subscriptions.isExpired;
    final nodes = expired ? const <SubscriptionNode>[] : subscriptions.nodes;
    final (state, currentNode, hasError, activeIndex) = context.select(
      (ConnectionController c) {
        final origin = c.currentNodeOrigin;
        return (
          c.state,
          c.currentNode,
          c.errorCode != null,
          origin == null
              ? -1
              : nodes.indexWhere((node) => identical(node, origin)),
        );
      },
    );
    final hasServers = nodes.isNotEmpty;
    final pending =
        state.isTransitioning || (subscriptions.isLoading && !state.isActive);
    final selection = _selection;
    final selected = !expired &&
            selection != null &&
            identical(subscription, selection.source)
        ? selection.node
        : null;
    final showCurrent =
        state.isActive || state == vpn.ConnectionState.disconnecting;
    // Отмечаем ровно исходную карточку. Одинаковый ID/адрес у другой
    // подписки не означает, что туннель подключён к ней.
    final current = showCurrent && activeIndex >= 0 ? nodes[activeIndex] : null;
    final nodeName = showCurrent
        ? (currentNode == null
            ? null
            : currentNode.name.isEmpty
                ? currentNode.id
                : currentNode.name)
        : selected == null
            ? null
            : serverDisplayName(selected);
    final label = switch (state) {
      vpn.ConnectionState.connecting => l10n.statusConnecting,
      vpn.ConnectionState.disconnecting => l10n.statusDisconnecting,
      vpn.ConnectionState.connected => l10n.homeDisconnect,
      _ when subscriptions.restoreFailed && !hasServers => l10n.homeRetry,
      _ when !hasServers => l10n.subAddButton,
      _ when selected == null => l10n.homeSelectServer,
      _ => l10n.nodeConnect,
    };
    final branding = subscription?.branding;
    final links = ProviderLinksBar.forBranding(branding);

    void select(SubscriptionNode node) {
      if (subscription == null) return;
      setState(() {
        _selection = (source: subscription, node: node);
      });
    }

    Future<void> addSubscription() => SubscriptionScreen.openAddDialog(context);

    return Scaffold(
      appBar: HomeAppBar(title: branding?.appName),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > _wideBreakpoint;
            final header = HomeHeaderGeometry.of(
              context,
              viewportHeight: constraints.maxHeight,
              hasLinks: links.isNotEmpty,
              showsMetrics: showCurrent,
              showsError: hasError,
              hasServerSummary: nodeName != null,
              showsServerShortcut:
                  hasServers && (selected != null || showCurrent),
            );
            final hasSessionPanel = hasServers || showCurrent;
            // Не переключаем тип списка при смене состояния VPN и не
            // сбрасываем позицию скролла при показе метрик или ошибки.
            final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
            final shortViewport = constraints.maxHeight < 232 + 125 * textScale;
            final pinned = !wide && hasSessionPanel && !shortViewport;
            final actionIcon = showCurrent || selected != null
                ? Icons.power_settings_new
                : subscriptions.restoreFailed && !hasServers
                    ? Icons.refresh_rounded
                    : (hasServers
                        ? Icons.dns_outlined
                        : Icons.add_link_rounded);
            final offset = wide ? 0.0 : (pinned ? header.collapseExtent : null);

            Future<void> primaryAction() async {
              if (connection.state.isTransitioning ||
                  (subscriptions.isLoading && !connection.state.isActive)) {
                return;
              }
              if (!connection.state.isActive) {
                if (subscriptions.restoreFailed && !hasServers) {
                  return subscriptions.initialize();
                }
                if (!hasServers ||
                    subscriptions.subscription?.isExpired == true) {
                  return addSubscription();
                }
                if (selected == null) {
                  return _showServers(wide: wide, offset: offset);
                }
              }
              await connection.toggle(
                resolveNode: selected?.toServerNode,
                resolveCandidates: selected?.toProtocolCandidates,
                resolveRelays: selected != null && subscription != null
                    ? () => subscription.resolveRelayCandidates(selected)
                    : null,
                origin: selected,
              );
            }

            void manageSubscription() => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SubscriptionScreen(),
                  ),
                );

            final panel = ConnectionPanel(
              nodeName: nodeName,
              country:
                  showCurrent ? currentNode?.countryCode : selected?.country,
              city: showCurrent ? current?.city : selected?.city,
              hasServers: hasServers,
              expired: expired,
              restoreFailed: subscriptions.restoreFailed,
              alignTop: !wide && header.expanded > constraints.maxHeight,
              actionLabel: label,
              actionIcon: actionIcon,
              onAction: pending ? null : primaryAction,
              onShowServers:
                  pinned && hasServers && (selected != null || showCurrent)
                      ? () => _showServers(wide: wide, offset: offset)
                      : null,
              onManageSubscription: manageSubscription,
            );
            final compact = CompactConnectButton(
              label: label,
              icon: actionIcon,
              onPressed: pending ? null : primaryAction,
            );
            final providerBar =
                links.isEmpty ? null : ProviderLinksBar(links: links);
            final smartSelectedId = servers.lastSmartResult?.server.id;
            final showSmartButton = !expired &&
                subscription != null &&
                subscription.isSmartSelectionEnabled;
            final smartButton = !showSmartButton
                ? null
                : SmartSelectionButton(
                    isSelected: selected != null &&
                        smartSelectedId != null &&
                        selected.id == smartSelectedId,
                    isLoading: servers.isMeasuring,
                    onTap: state.isActive || pending
                        ? null
                        : () async {
                            final best =
                                await servers.selectSmartServer(subscription);
                            if (!mounted || best == null) return;
                            select(best);
                            if (!wide &&
                                shortViewport &&
                                _mobileScroll.hasClients) {
                              unawaited(
                                _mobileScroll.animateTo(
                                  0,
                                  duration: _scrollDuration,
                                  curve: Curves.easeOutCubic,
                                ),
                              );
                            }
                          },
                  );
            final list = HomeServerList(
              subscription: subscription,
              activeNode: current,
              selectedNode: showCurrent ? null : selected,
              selectionRequiresDisconnect: state.isActive,
              firstServerFocus: _firstServer,
              sectionAnchor: _serversAnchor,
              loading: subscriptions.isLoading,
              expired: expired,
              restoreFailed: subscriptions.restoreFailed,
              sessionOnly: subscriptions.sessionOnly,
              smartSelectionWidget: smartButton,
              latencyForNode: servers.latencyForNode,
              onSelected: state.isActive || pending
                  ? null
                  : (node) {
                      select(node);
                      if (!wide && shortViewport && _mobileScroll.hasClients) {
                        _mobileScroll.animateTo(
                          0,
                          duration: _scrollDuration,
                          curve: Curves.easeOutCubic,
                        );
                      }
                    },
              onManageSubscription: manageSubscription,
            );

            if (wide) {
              if (!hasSessionPanel &&
                  !expired &&
                  !subscriptions.restoreFailed) {
                return Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (subscriptions.isLoading)
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: LinearProgressIndicator(
                              semanticsLabel: l10n.homeLoadingSubscription,
                            ),
                          ),
                        panel,
                      ],
                    ),
                  ),
                );
              }
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _contentWidth),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomScrollView(
                          key: const PageStorageKey('wide-servers'),
                          controller: _wideScroll,
                          slivers: [list],
                        ),
                      ),
                      VerticalDivider(
                        width: 1,
                        color: Theme.of(context).dividerColor,
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          primary: false,
                          child: Column(
                            children: [
                              if (shortViewport) compact else panel,
                              if (providerBar != null) providerBar,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (!hasSessionPanel && !shortViewport) {
              return CustomScrollView(
                key: const PageStorageKey('mobile-home'),
                controller: _mobileScroll,
                slivers: [
                  if (subscriptions.isLoading)
                    SliverToBoxAdapter(
                      child: LinearProgressIndicator(
                        semanticsLabel: l10n.homeLoadingSubscription,
                      ),
                    ),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: panel,
                  ),
                ],
              );
            }

            return CustomScrollView(
              key: const PageStorageKey('mobile-home'),
              controller: _mobileScroll,
              slivers: [
                if (pinned)
                  HomeConnectionHeader(
                    geometry: header,
                    expanded: panel,
                    compact: compact,
                    links: providerBar,
                  )
                else if (shortViewport)
                  SliverToBoxAdapter(
                    child: Column(
                      children: [compact, if (providerBar != null) providerBar],
                    ),
                  )
                else
                  SliverToBoxAdapter(child: panel),
                if (hasSessionPanel || expired || subscriptions.restoreFailed)
                  list,
                // Даже единственный сервер должен докручиваться до шапки.
                if (pinned)
                  SliverLayoutBuilder(
                    builder: (context, constraints) => SliverToBoxAdapter(
                      child: SizedBox(
                        height: (constraints.viewportMainAxisExtent +
                                header.collapseExtent -
                                constraints.precedingScrollExtent)
                            .clamp(0.0, constraints.viewportMainAxisExtent),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
