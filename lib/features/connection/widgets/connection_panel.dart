import 'package:fetu/design_system/design_system.dart';
import 'package:fetu/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../subscription/widgets/server_location.dart';
import 'connection_button.dart';
import 'connection_status_widget.dart';

/// Полная панель V4: выбранная локация, большая кнопка и состояние сессии.
class ConnectionPanel extends StatelessWidget {
  /// Создаёт панель из состояния экрана, без доступа к сетевым операциям.
  const ConnectionPanel({
    super.key,
    required this.nodeName,
    required this.country,
    required this.city,
    required this.hasServers,
    required this.expired,
    required this.restoreFailed,
    this.alignTop = false,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
    this.onShowServers,
    this.onManageSubscription,
  });

  /// Имя выбранного или активного узла.
  final String? nodeName;

  /// Код страны узла.
  final String? country;

  /// Город узла, если указан провайдером.
  final String? city;

  /// Доступен хотя бы один сервер из подписки.
  final bool hasServers;

  /// Сохранённая подписка истекла.
  final bool expired;

  /// Чтение сохранённой записи не удалось, и его можно повторить.
  final bool restoreFailed;

  /// Размещать содержимое сверху, если полноразмерная панель выше окна.
  final bool alignTop;

  /// Локализованное действие основной кнопки.
  final String actionLabel;

  /// Иконка основного действия.
  final IconData actionIcon;

  /// Добавить подписку, выбрать узел или переключить VPN.
  final VoidCallback? onAction;

  /// Перейти к списку с полноразмерной панели на телефоне.
  final VoidCallback? onShowServers;

  /// Открыть экран подписки при её отсутствии или истечении.
  final VoidCallback? onManageSubscription;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isIssue = expired || restoreFailed;
    final badgeAccent =
        isIssue && !hasServers ? theme.colorScheme.error : AppColors.accentCool;
    final title = nodeName ??
        (switch ((hasServers, expired, restoreFailed)) {
          (true, _, _) => l10n.homeNoServerSelected,
          (_, true, _) => l10n.subErrorExpired,
          (_, _, true) => l10n.homeRestoreFailed,
          _ => l10n.homeStartTitle,
        });
    return Align(
      alignment: alignTop ? Alignment.topCenter : Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: alignTop
              ? const EdgeInsets.fromLTRB(20, 10, 20, 10)
              : const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (nodeName != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: ServerLocation(country: country, city: city),
                )
              else
                Container(
                  width: alignTop ? 40 : 52,
                  height: alignTop ? 40 : 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: badgeAccent.withOpacity(0.12),
                    border: Border.all(color: badgeAccent.withOpacity(0.35)),
                  ),
                  child: Icon(
                    isIssue && !hasServers
                        ? Icons.error_outline_rounded
                        : Icons.shield_outlined,
                    size: alignTop ? 20 : 26,
                    color: badgeAccent,
                  ),
                ),
              SizedBox(height: alignTop ? 6 : 10),
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.h2,
                ),
              ),
              if (nodeName == null) ...[
                const SizedBox(height: 4),
                Text(
                  hasServers
                      ? l10n.homeChooseServerHint
                      : restoreFailed
                          ? l10n.homeRestoreHint
                          : expired
                              ? l10n.homeRenewHint
                              : l10n.homeStartHint,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall
                      .copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
              SizedBox(height: alignTop ? 12 : 18),
              ConnectionButton(
                label: actionLabel,
                icon: actionIcon,
                onPressed: onAction,
              ),
              const SizedBox(height: 16),
              const ConnectionStatusWidget(),
              if (onManageSubscription != null &&
                  !hasServers &&
                  (expired || restoreFailed)) ...[
                const SizedBox(height: 12),
                Tooltip(
                  message: l10n.homeTooltipSubscription,
                  excludeFromSemantics: true,
                  child: OutlinedButton.icon(
                    onPressed: onManageSubscription,
                    icon: const Icon(Icons.card_membership_outlined, size: 18),
                    label: Text(l10n.homeTooltipSubscription),
                  ),
                ),
              ],
              if (onShowServers != null) ...[
                const SizedBox(height: 8),
                Tooltip(
                  message: l10n.subSectionServers,
                  excludeFromSemantics: true,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurfaceVariant,
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    onPressed: onShowServers,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    label: Text(
                      l10n.subSectionServers,
                      style: AppTypography.labelSmall,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
