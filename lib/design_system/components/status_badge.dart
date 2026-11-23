/// Бейдж статуса VPN-подключения.
///
/// Отображает текущее состояние (disconnected/connecting/connected/error)
/// с соответствующим цветом и анимацией.
library;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../typography/app_typography.dart';

/// Статус VPN-подключения для визуального отображения.
enum ConnectionStatus {
  /// Отключено
  disconnected,

  /// Подключается
  connecting,

  /// Подключено
  connected,

  /// Ошибка
  error,
}

/// Компактный бейдж со статусом подключения.
///
/// Использует семантические цвета из [AppColors] и анимацию пульсации
/// для состояния "подключается". Текст статуса передаётся вызывающей
/// стороной из локализации (AGENTS.md, правило 14: без хардкод-строк).
class StatusBadge extends StatefulWidget {
  /// Текущий статус подключения
  final ConnectionStatus status;

  /// Текст бейджа (из AppLocalizations)
  final String label;

  /// Размер (compact = 8px dot, normal = 12px dot)
  final bool compact;

  const StatusBadge({
    required this.status,
    required this.label,
    this.compact = false,
    super.key,
  });

  @override
  State<StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<StatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Пульсация только для состояния "подключается"
    if (widget.status == ConnectionStatus.connecting) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(StatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Обновить анимацию при смене статуса
    if (widget.status == ConnectionStatus.connecting) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final statusLabel = widget.label;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? 8 : 12,
        vertical: widget.compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Индикаторная точка с пульсацией
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: widget.compact ? 8 : 10,
                height: widget.compact ? 8 : 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  boxShadow: widget.status == ConnectionStatus.connecting
                      ? [
                          BoxShadow(
                            color: statusColor
                                .withOpacity(0.5 * _pulseController.value),
                            blurRadius: 8 * _pulseController.value,
                            spreadRadius: 2 * _pulseController.value,
                          ),
                        ]
                      : null,
                ),
              );
            },
          ),

          if (!widget.compact) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                statusLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelSmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Получить цвет статуса из дизайн-системы
  Color _getStatusColor() {
    switch (widget.status) {
      case ConnectionStatus.disconnected:
        return AppColors.statusDisconnected;
      case ConnectionStatus.connecting:
        return AppColors.statusConnecting;
      case ConnectionStatus.connected:
        return AppColors.statusConnected;
      case ConnectionStatus.error:
        return AppColors.statusError;
    }
  }
}
