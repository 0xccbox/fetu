import 'package:fetu/design_system/design_system.dart';
import 'package:fetu/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../settings/services/ux_terminology_translator.dart';
import '../controllers/connection_controller.dart';
import '../models/connection_metrics.dart';

/// Компактное действие подключения с таймером и трафиком активной сессии.
class CompactConnectButton extends StatelessWidget {
  /// Создаёт компактное действие с тем же назначением, что и большая кнопка.
  const CompactConnectButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  /// Локализованное название действия.
  final String label;

  /// Иконка текущего действия.
  final IconData icon;

  /// Действие по нажатию; null, если выполняется операция.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final (state, error, duration, traffic) = context.select(
      (ConnectionController c) => (
        c.state,
        c.errorCode,
        c.metrics.connectionDuration,
        c.metrics.totalDownloaded + c.metrics.totalUploaded,
      ),
    );
    final active = state.isActive;
    final isSelect = icon == Icons.dns_outlined;
    final useSelectSurface = isSelect && !active && !state.isTransitioning;
    final accent = active ? AppColors.statusConnected : AppColors.accentCool;
    final gradient = state.isTransitioning
        ? null
        : active
            ? AppColors.connectedGradient
            : useSelectSurface
                ? (isDark
                    ? AppColors.selectButtonDarkGradient
                    : AppColors.selectButtonLightGradient)
                : AppColors.connectButtonGradient;
    final foreground = state.isTransitioning || useSelectSurface
        ? theme.colorScheme.onSurface
        : AppColors.onConnectGradient;
    final meta = error != null
        ? UxTerminologyTranslator.connectionErrorLabel(l10n, error)
        : active
            ? '${ConnectionMetrics.formatDuration(duration, alwaysShowHours: true)}'
                '  ·  ${ConnectionMetrics.formatBytes(traffic)}'
            : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: theme.colorScheme.surface,
              gradient: gradient,
              border: Border.all(
                color: accent.withOpacity(useSelectSurface ? 0.7 : 0.9),
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(useSelectSurface ? 0.16 : 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.transparent,
                disabledBackgroundColor: AppColors.transparent,
                foregroundColor: foreground,
                disabledForegroundColor: foreground,
                minimumSize: const Size(156, 48),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: onPressed,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(active ? Icons.lock_outline_rounded : icon, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (meta != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Semantics(
                liveRegion: error != null,
                child: Text(
                  meta,
                  textAlign: TextAlign.center,
                  maxLines: error == null ? 1 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.monoSmall.copyWith(
                    color: error == null
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.error,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
