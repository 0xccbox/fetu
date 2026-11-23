import 'package:fetu/design_system/design_system.dart';
import 'package:fetu/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../subscription/models/subscription_branding.dart';

/// Третий слой V4: ссылки из подписки, с меню для дополнительных ссылок.
class ProviderLinksBar extends StatelessWidget {
  /// Создаёт полосу проверенных ссылок.
  const ProviderLinksBar({super.key, required this.links});

  /// Доступные ссылки на страницы провайдера.
  final List<ProviderLink> links;

  /// Извлекает ссылки из брендинга; пустые и не-HTTP(S) ссылки не показываются.
  static List<ProviderLink> forBranding(SubscriptionBranding? branding) => [
        if (branding != null) ...[
          if (_webUri(branding.telegramUrl) case final uri?)
            ProviderLink._(uri, Icons.send_rounded, _LinkKind.telegram),
          if (_webUri(branding.websiteUrl) case final uri?)
            ProviderLink._(uri, Icons.language_rounded, _LinkKind.website),
          if (_webUri(branding.supportUrl) case final uri?)
            ProviderLink._(uri, Icons.headset_mic_outlined, _LinkKind.support),
          for (final custom in branding.customLinks)
            if (_webUri(custom.url) case final uri?)
              ProviderLink._(
                uri,
                Icons.link,
                _LinkKind.custom,
                custom.label.trim(),
              ),
        ],
      ];

  static Uri? _webUri(String? raw) {
    final uri = Uri.tryParse(raw?.trim() ?? '');
    return uri != null &&
            (uri.isScheme('https') || uri.isScheme('http')) &&
            uri.host.isNotEmpty &&
            uri.userInfo.isEmpty
        ? uri
        : null;
  }

  Future<void> _open(BuildContext context, Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } on Exception catch (_) {
      // Не выводим URL или детали исключения плагина в лог.
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.homeLinkFailed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    const visibleCount = 3;
    final showLabels = MediaQuery.textScalerOf(context).scale(12) <= 15;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Material(
            color: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: AppColors.accentCool.withOpacity(0.28)),
            ),
            child: Row(
              children: [
                for (final link in links.take(visibleCount))
                  Expanded(
                    child: Tooltip(
                      message: link.label(l10n),
                      excludeFromSemantics: showLabels,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurface,
                          minimumSize: const Size(48, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        onPressed: () => _open(context, link.uri),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              link.icon,
                              size: 18,
                              color: AppColors.accentCool,
                            ),
                            if (showLabels) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  link.label(l10n),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.labelSmall,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                if (links.length > visibleCount)
                  PopupMenuButton<ProviderLink>(
                    tooltip: l10n.homeMoreLinks,
                    onSelected: (link) => _open(context, link.uri),
                    itemBuilder: (_) => [
                      for (final link in links.skip(visibleCount))
                        PopupMenuItem(
                          value: link,
                          child: Text(
                            link.label(l10n),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _LinkKind { telegram, website, support, custom }

/// Публичная ссылка, доступная в навигации провайдера.
@immutable
class ProviderLink {
  const ProviderLink._(this.uri, this.icon, this._kind, [this._customLabel]);

  /// Адрес публичной страницы.
  final Uri uri;

  /// Иконка действия.
  final IconData icon;
  final _LinkKind _kind;
  final String? _customLabel;

  /// Локализованная подпись, если провайдер не указал свою.
  String label(AppLocalizations l10n) => switch (_kind) {
        _LinkKind.telegram => l10n.homeProviderTelegram,
        _LinkKind.website => l10n.homeProviderWebsite,
        _LinkKind.support => l10n.homeProviderSupport,
        _LinkKind.custom =>
          _customLabel!.isEmpty ? l10n.homeProviderLink : _customLabel,
      };
}
