import 'package:fetu/design_system/design_system.dart';
import 'package:fetu/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../models/subscription.dart';
import '../models/subscription_node.dart';
import 'server_selection_tile.dart';

/// Секция серверов главного экрана; строит карточки по мере скролла.
class HomeServerList extends StatelessWidget {
  /// Создаёт список текущей подписки и его пустое состояние.
  const HomeServerList({
    super.key,
    required this.subscription,
    required this.activeNode,
    required this.selectedNode,
    required this.selectionRequiresDisconnect,
    required this.firstServerFocus,
    required this.sectionAnchor,
    required this.loading,
    required this.expired,
    required this.restoreFailed,
    required this.sessionOnly,
    required this.onSelected,
    required this.onManageSubscription,
    this.smartSelectionWidget,
    this.latencyForNode,
  });

  /// Подписка, из которой берутся узлы, или null до импорта.
  final Subscription? subscription;

  /// Узел, через который работает туннель.
  final SubscriptionNode? activeNode;

  /// Узел, выбранный для следующего подключения.
  final SubscriptionNode? selectedNode;

  /// Выбор другого сервера заблокирован до отключения VPN.
  final bool selectionRequiresDisconnect;

  /// Фокус первой строки для клавиатурной навигации с панели подключения.
  final FocusNode firstServerFocus;

  /// Якорь начала списка для коротких окон без закреплённой панели.
  final Key sectionAnchor;

  /// Идёт импорт или обновление подписки.
  final bool loading;

  /// Сохранённая подписка истекла и не имеет доступных узлов.
  final bool expired;

  /// Чтение сохранённой записи временно не удалось.
  final bool restoreFailed;

  /// Импорт не сохраняется после закрытия приложения.
  final bool sessionOnly;

  /// Выбор сервера; не меняет состояние VPN.
  final ValueChanged<SubscriptionNode>? onSelected;

  /// Переход в кабинет провайдера.
  final VoidCallback onManageSubscription;

  /// Опциональная кнопка «Умный выбор сервера» над списком.
  final Widget? smartSelectionWidget;

  /// Опциональный провайдер кэшированной задержки для узла.
  final int? Function(String nodeId)? latencyForNode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final nodes = expired
        ? const <SubscriptionNode>[]
        : (subscription?.nodes ?? const <SubscriptionNode>[]);
    final provider = subscription?.name;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              key: sectionAnchor,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(
                              l10n.subSectionServers,
                              style: AppTypography.h2,
                            ),
                          ),
                          if (provider != null && provider.isNotEmpty)
                            Text(
                              provider,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySmall.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (subscription != null || expired || restoreFailed)
                      IconButton(
                        onPressed: onManageSubscription,
                        tooltip: l10n.homeTooltipSubscription,
                        icon: const Icon(Icons.card_membership_outlined),
                      ),
                  ],
                ),
                if (smartSelectionWidget != null) ...[
                  const SizedBox(height: 8),
                  smartSelectionWidget!,
                ],
                if (sessionOnly)
                  Text(
                    l10n.homeSessionOnly,
                    style: AppTypography.bodySmall
                        .copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                if (loading) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    semanticsLabel: l10n.homeLoadingSubscription,
                  ),
                ],
                if (selectionRequiresDisconnect && nodes.isNotEmpty)
                  Text(
                    l10n.homeDisconnectToChooseServer,
                    style: AppTypography.bodySmall
                        .copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          if (nodes.isEmpty)
            SliverToBoxAdapter(
              child: Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.dns_outlined),
                  title: Text(
                    loading
                        ? l10n.homeLoadingSubscription
                        : restoreFailed
                            ? l10n.homeRestoreFailed
                            : l10n.subErrorNoNodes,
                  ),
                  subtitle: Text(
                    restoreFailed
                        ? l10n.homeRestoreHint
                        : expired
                            ? l10n.homeRenewHint
                            : l10n.homeServersAfterImport,
                  ),
                ),
              ),
            )
          else
            SliverList.builder(
              itemCount: nodes.length,
              itemBuilder: (context, index) {
                final node = nodes[index];
                final pick = onSelected;
                return ServerSelectionTile(
                  node: node,
                  focusNode: index == 0 ? firstServerFocus : null,
                  active: identical(activeNode, node),
                  selected: identical(selectedNode, node),
                  latencyMs: latencyForNode?.call(node.id),
                  onTap: pick == null ? null : () => pick(node),
                );
              },
            ),
          if (nodes.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: onManageSubscription,
                  icon: const Icon(Icons.card_membership_outlined, size: 18),
                  label: Text(l10n.homeTooltipSubscription),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
