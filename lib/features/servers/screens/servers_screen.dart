import 'package:fetu/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../subscription/models/subscription_node.dart';
import '../controllers/server_list_controller.dart';
import '../services/server_list_service.dart';
import '../widgets/server_filter_chip.dart';
import '../widgets/server_list_item.dart';

/// Экран списка серверов с фильтрацией и замером задержки (правило 22).
class ServersScreen extends StatefulWidget {
  /// Создаёт экран серверов.
  const ServersScreen({
    super.key,
    this.selectedNodeId,
    this.onNodeSelected,
  });

  /// Идентификатор выбранного сейчас узла.
  final String? selectedNodeId;

  /// Колбэк выбора сервера.
  final ValueChanged<SubscriptionNode>? onNodeSelected;

  @override
  State<ServersScreen> createState() => _ServersScreenState();
}

class _ServersScreenState extends State<ServersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = context.read<ServerListController>();
      controller.syncWithSubscription();
      controller.refreshLatencies();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = context.watch<ServerListController>();
    final servers = controller.filteredServers;
    final countries = controller.availableCountries;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.subSectionServers),
        actions: [
          IconButton(
            tooltip: l10n.actionRefresh,
            onPressed: controller.isMeasuring
                ? null
                : () => controller.refreshLatencies(forceRefresh: true),
            icon: const Icon(Icons.speed_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          if (controller.isMeasuring)
            const LinearProgressIndicator(minHeight: 2),
          if (countries.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  ServerFilterChip(
                    label: l10n.metricPing,
                    selected:
                        controller.sortOrder == ServerSortOrder.lowestLatency,
                    onTap: () => controller.setSortOrder(
                      controller.sortOrder == ServerSortOrder.lowestLatency
                          ? ServerSortOrder.providerDefault
                          : ServerSortOrder.lowestLatency,
                    ),
                  ),
                  const SizedBox(width: 8),
                  for (final code in countries) ...[
                    ServerFilterChip(
                      label: code,
                      selected: controller.countryFilter == code,
                      onTap: () => controller.setCountryFilter(code),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          Expanded(
            child: servers.isEmpty
                ? Center(child: Text(l10n.subErrorNoNodes))
                : ListView.builder(
                    itemCount: servers.length,
                    itemBuilder: (context, index) {
                      final info = servers[index];
                      return ServerListItem(
                        info: info,
                        selected: info.id == widget.selectedNodeId,
                        onTap: () {
                          widget.onNodeSelected?.call(info.node);
                          Navigator.of(context).maybePop(info.node);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
