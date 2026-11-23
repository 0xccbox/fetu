import 'package:fetu/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../design_system/theme/app_colors.dart';
import '../../../design_system/typography/app_typography.dart';
import '../../connection/controllers/connection_controller.dart';
import '../../settings/services/ux_terminology_translator.dart';
import '../../split_tunnel/controllers/split_tunnel_controller.dart';
import '../../split_tunnel/models/split_rule.dart';
import '../controllers/subscription_controller.dart';
import '../models/provider_cabinet.dart';
import '../models/subscription.dart';
import '../models/subscription_error.dart';
import '../models/subscription_node.dart';
import '../widgets/add_subscription_dialog.dart';
import '../widgets/node_list_tile.dart';
import '../widgets/provider_announcement_banner.dart';
import '../widgets/provider_card_tile.dart';
import '../widgets/provider_rules_tile.dart';
import '../widgets/subscription_card.dart';

/// Экран подписки и кабинета провайдера.
///
/// Тонкий оркестратор: брендинг в закреплённой шапке, объявления,
/// аккаунт, карточки провайдера, split-правила и узлы; вся логика —
/// в контроллерах.
class SubscriptionScreen extends StatefulWidget {
  /// Создаёт экран.
  const SubscriptionScreen({super.key});

  /// Открывает форму; [sessionOnly] оставляет подписку только в памяти.
  static Future<void> openAddDialog(
    BuildContext context, {
    bool sessionOnly = false,
  }) async {
    final controller = context.read<SubscriptionController>();
    if (controller.isLoading || (!sessionOnly && controller.restoreFailed)) {
      return;
    }
    final url = await showDialog<String>(
      context: context,
      builder: (_) => const AddSubscriptionDialog(),
    );
    if (url == null || !context.mounted) return;

    // vpn:// и https:// обрабатываются контроллером: ключи
    // vpn:// приходят из настроек (secure-storage, ФАЗА 10).
    if (sessionOnly) {
      await controller.addForSession(url);
    } else {
      await controller.addFromUrl(url);
    }
    if (!context.mounted) return;
    final code = controller.errorCode;
    if (code != null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_errorMessage(l10n, code))));
    }
  }

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final Set<String> _dismissedAnnouncements = <String>{};

  Future<void> _connectNode(
    BuildContext context,
    SubscriptionNode node,
    Subscription subscription,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final connection = context.read<ConnectionController>();
    try {
      await connection.connect(
        node.toServerNode(),
        origin: node,
        fallbackNodes: node.toProtocolCandidates(),
        relayCandidates: subscription.resolveRelayCandidates(node),
      );
      if (context.mounted) {
        _showMessage(context, l10n.subConnectingTo(node.name));
      }
    } on StateError catch (e) {
      // Ошибки конвертации узла не содержат адресов/URL.
      if (context.mounted) _showMessage(context, e.message);
    } catch (_) {
      if (context.mounted) {
        final error = connection.errorCode;
        _showMessage(
          context,
          error == null
              ? l10n.subConnectFailed(node.name)
              : UxTerminologyTranslator.connectionErrorLabel(l10n, error),
        );
      }
    }
  }

  Future<void> _applyProviderRules(
    BuildContext context,
    List<SplitRule> rules,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final split = context.read<SplitTunnelController>();
    await split.applyProviderRules(rules);
    if (context.mounted) {
      final code = split.errorCode;
      _showMessage(
        context,
        code == null
            ? l10n.subProviderRulesApplied(rules.length)
            : UxTerminologyTranslator.splitTunnelErrorLabel(l10n, code),
      );
    }
  }

  void _showErrorIfAny(
    BuildContext context,
    SubscriptionController controller,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final code = controller.errorCode;
    if (code == null) return;
    _showMessage(context, _errorMessage(l10n, code));
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _copyValue(BuildContext context, String value) async {
    final l10n = AppLocalizations.of(context)!;
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) _showMessage(context, l10n.subCopied(value));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = context.watch<SubscriptionController>();
    final subscription = controller.subscription;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final providerName = subscription?.branding?.appName ??
        subscription?.name ??
        l10n.subDefaultTitle;
    final announcements =
        subscription?.cabinet?.activeAnnouncements ?? const <Announcement>[];
    final cards = subscription?.cabinet?.customCards ?? const <ProviderCard>[];
    final badgesMap = {
      for (final badge
          in subscription?.cabinet?.nodeBadges ?? const <NodeBadge>[])
        badge.id: badge,
    };

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: CustomScrollView(
        slivers: [
          // Sticky-шапка брендинга провайдера.
          SliverAppBar(
            pinned: true,
            expandedHeight: 96,
            collapsedHeight: 64,
            backgroundColor:
                isDark ? AppColors.darkSurface : AppColors.lightSurface,
            title: Text(
              providerName,
              style: AppTypography.h3.copyWith(color: textPrimary),
            ),
            actions: [
              if (controller.subscriptionUrl != null)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: l10n.subTooltipRefresh,
                  onPressed: () async {
                    await controller.refresh();
                    if (context.mounted) {
                      _showErrorIfAny(context, controller);
                    }
                  },
                ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: controller.restoreFailed
                    ? l10n.homeUseForSession
                    : l10n.subTooltipAdd,
                onPressed: controller.isLoading
                    ? null
                    : () => SubscriptionScreen.openAddDialog(
                          context,
                          sessionOnly: controller.restoreFailed,
                        ),
              ),
            ],
            bottom: controller.isLoading
                ? const PreferredSize(
                    preferredSize: Size.fromHeight(4),
                    child: LinearProgressIndicator(minHeight: 4),
                  )
                : null,
            flexibleSpace: FlexibleSpaceBar(
              background: _BrandingHeader(
                companyName: subscription?.branding?.companyName,
                websiteUrl: subscription?.branding?.websiteUrl ??
                    subscription?.branding?.telegramUrl,
                textColor: textSecondary,
              ),
            ),
          ),
          if (subscription == null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(
                expired: controller.isExpired,
                restoreFailed: controller.restoreFailed,
                onSessionImport:
                    controller.restoreFailed && !controller.isLoading
                        ? () => SubscriptionScreen.openAddDialog(
                              context,
                              sessionOnly: true,
                            )
                        : null,
                onAction: controller.isLoading
                    ? null
                    : controller.restoreFailed
                        ? controller.initialize
                        : () => SubscriptionScreen.openAddDialog(context),
              ),
            )
          else
            ..._contentSlivers(
              context,
              subscription,
              announcements,
              cards,
              badgesMap,
            ),
        ],
      ),
    );
  }

  /// Сборка контента кабинета (лениво, через SliverChildBuilderDelegate).
  List<Widget> _contentSlivers(
    BuildContext context,
    Subscription subscription,
    List<Announcement> announcements,
    List<ProviderCard> cards,
    Map<String, NodeBadge> badgesMap,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final splitTunnel = subscription.splitTunnel;
    final providerRules =
        splitTunnel?.enabled == true ? splitTunnel!.toSplitRules() : null;
    final nodes = subscription.nodes;

    final headerItems = <Widget>[
      for (final announcement in announcements)
        if (!_dismissedAnnouncements.contains(announcement.id))
          ProviderAnnouncementBanner(
            announcement: announcement,
            onDismiss: () => setState(() {
              _dismissedAnnouncements.add(announcement.id);
            }),
          ),
      if (subscription.cabinet?.account != null)
        SubscriptionCard(account: subscription.cabinet!.account!),
      for (final card in cards)
        ProviderCardTile(
          card: card,
          onCopy: card.copyValue == null
              ? null
              : () => _copyValue(context, card.copyValue!),
        ),
      if (providerRules != null)
        ProviderRulesTile(
          rulesCount: providerRules.length,
          onApply: () => _applyProviderRules(context, providerRules),
        ),
      _SectionLabel(l10n.subSectionServers, textColor: textSecondary),
    ];

    return [
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => headerItems[index],
          childCount: headerItems.length,
        ),
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => NodeListTile(
            node: nodes[index],
            badges: badgesMap,
            onConnect: () => _connectNode(context, nodes[index], subscription),
          ),
          childCount: nodes.length,
        ),
      ),
      const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
    ];
  }
}

/// Мапит код ошибки подписки в локализованное сообщение.
String _errorMessage(AppLocalizations l10n, SubscriptionError code) =>
    switch (code) {
      SubscriptionError.enterUrl => l10n.subErrorEnterUrl,
      SubscriptionError.noUpdateUrl => l10n.subErrorNoUpdateUrl,
      SubscriptionError.network => l10n.subErrorNetwork,
      SubscriptionError.loadFailed => l10n.subErrorLoadFailed,
      SubscriptionError.broken => l10n.subErrorBroken,
      SubscriptionError.saveFailed => l10n.subErrorSaveFailed,
      SubscriptionError.noKeys => l10n.subErrorNoKeys,
      SubscriptionError.invalidKey => l10n.subErrorInvalidKey,
      SubscriptionError.expired => l10n.subErrorExpired,
      SubscriptionError.outdatedVersion => l10n.subErrorOutdatedVersion,
      SubscriptionError.noNodes => l10n.subErrorNoNodes,
      SubscriptionError.noTcpChannel => l10n.subErrorNoTcpChannel,
      SubscriptionError.signature => l10n.subErrorSignature,
      SubscriptionError.invalid => l10n.subErrorInvalid,
    };

/// Шапка брендинга (фон pinned app bar).
class _BrandingHeader extends StatelessWidget {
  const _BrandingHeader({
    required this.companyName,
    required this.websiteUrl,
    required this.textColor,
  });

  final String? companyName;
  final String? websiteUrl;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    if (companyName == null && websiteUrl == null) {
      return const SizedBox.shrink();
    }
    return Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(72, 0, 16, 26),
        child: Text(
          [companyName, websiteUrl].whereType<String>().join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.caption.copyWith(color: textColor),
        ),
      ),
    );
  }
}

/// Метка секции.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title, {required this.textColor});

  final String title;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.overline.copyWith(color: textColor),
      ),
    );
  }
}

/// Пустое состояние (подписка не добавлена).
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.expired,
    required this.restoreFailed,
    required this.onAction,
    this.onSessionImport,
  });

  final bool expired;
  final bool restoreFailed;
  final VoidCallback? onAction;
  final VoidCallback? onSessionImport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 64,
            color: (isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary)
                .withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            restoreFailed
                ? l10n.homeRestoreFailed
                : expired
                    ? l10n.subErrorExpired
                    : l10n.subEmptyTitle,
            textAlign: TextAlign.center,
            style: AppTypography.h4.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            restoreFailed
                ? l10n.homeRestoreHint
                : expired
                    ? l10n.homeRenewHint
                    : l10n.subEmptyHint,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAction,
            icon: Icon(restoreFailed ? Icons.refresh : Icons.add_link),
            label: Text(restoreFailed ? l10n.homeRetry : l10n.subAddButton),
          ),
          if (onSessionImport != null)
            TextButton(
              onPressed: onSessionImport,
              child: Text(l10n.homeUseForSession),
            ),
        ],
      ),
    );
  }
}
