import 'package:fetu/design_system/design_system.dart';
import 'package:fetu/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../settings/screens/settings_screen.dart';
import '../../split_tunnel/screens/split_tunnel_screen.dart';
import '../../subscription/screens/subscription_screen.dart';

/// Первый слой V4: меню, заголовок и быстрый доступ к настройкам.
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Создаёт панель с опциональным названием провайдера.
  const HomeAppBar({super.key, this.title});

  /// Название приложения, указанное провайдером.
  final String? title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final providerTitle = title?.trim();

    void open(Widget page) => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => page),
        );

    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      scrolledUnderElevation: 0,
      leading: PopupMenuButton<_HomeMenu>(
        icon: const Icon(Icons.menu_rounded),
        tooltip: l10n.homeMenu,
        onSelected: (choice) {
          switch (choice) {
            case _HomeMenu.subscription:
              open(const SubscriptionScreen());
            case _HomeMenu.splitTunnel:
              open(const SplitTunnelScreen());
            case _HomeMenu.theme:
              context.read<ThemeController>().toggleTheme();
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: _HomeMenu.subscription,
            child: ListTile(
              leading: const Icon(Icons.card_membership_outlined),
              title: Text(l10n.homeTooltipSubscription),
            ),
          ),
          PopupMenuItem(
            value: _HomeMenu.splitTunnel,
            child: ListTile(
              leading: const Icon(Icons.alt_route_rounded),
              title: Text(l10n.homeTooltipSplitTunnel),
            ),
          ),
          PopupMenuItem(
            value: _HomeMenu.theme,
            child: ListTile(
              leading: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              ),
              title: Text(l10n.homeTooltipToggleTheme),
            ),
          ),
        ],
      ),
      title: Text(
        providerTitle != null && providerTitle.isNotEmpty
            ? providerTitle
            : l10n.homeAppName,
        style: AppTypography.h3.copyWith(fontWeight: FontWeight.w700),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: l10n.homeTooltipSettings,
          onPressed: () => open(const SettingsScreen()),
        ),
      ],
    );
  }
}

enum _HomeMenu { subscription, splitTunnel, theme }
