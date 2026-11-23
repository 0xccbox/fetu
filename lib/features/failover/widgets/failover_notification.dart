import 'package:fetu/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design_system/theme/app_colors.dart';
import '../../settings/controllers/settings_controller.dart';
import '../../settings/services/ux_terminology_translator.dart';
import '../models/failover_event.dart';

/// Уведомление о переключении протокола (failover).
///
/// Тексты зависят от режима интерфейса (правило 33): в простом —
/// человеческое описание, в расширенном — техническая причина.
class FailoverNotification extends StatefulWidget {
  const FailoverNotification({
    required this.event,
    super.key,
  });

  final FailoverEvent event;

  @override
  State<FailoverNotification> createState() => _FailoverNotificationState();
}

class _FailoverNotificationState extends State<FailoverNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    // Автоматически скрыть через 3 секунды
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsController>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowSoft,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildIcon(context),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.failoverTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      UxTerminologyTranslator.failoverSwitchMessage(
                        l10n,
                        settings.mode,
                        widget.event,
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      UxTerminologyTranslator.failoverReasonLabel(
                        l10n,
                        settings.mode,
                        widget.event,
                      ),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    final (color, icon) = _getIconData(context);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }

  (Color, IconData) _getIconData(BuildContext context) {
    final theme = Theme.of(context);

    switch (widget.event.reason) {
      case FailoverReason.timeout:
        return (AppColors.statusWarning, Icons.access_time);
      case FailoverReason.packetLoss:
        return (AppColors.statusWarning, Icons.signal_wifi_bad);
      case FailoverReason.blocked:
        return (AppColors.statusError, Icons.block);
      case FailoverReason.handshakeFailed:
        return (AppColors.statusError, Icons.error_outline);
      case FailoverReason.manual:
        return (theme.colorScheme.primary, Icons.swap_horiz);
    }
  }
}
