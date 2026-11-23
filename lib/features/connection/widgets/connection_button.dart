import 'package:fetu/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/connection_controller.dart';

/// Круглая кнопка подключения V4 с различимым состоянием и клавиатурным фокусом.
class ConnectionButton extends StatelessWidget {
  /// Создаёт основную кнопку с действием текущего экрана.
  const ConnectionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  /// Текст и доступное название действия.
  final String label;

  /// Иконка действия; состояние подключения уточняется по контроллеру.
  final IconData icon;

  /// Действие по нажатию; null, если выполняется операция.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final state = context.select((ConnectionController c) => c.state);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAdd = icon == Icons.add_link_rounded;
    final isSelect = icon == Icons.dns_outlined;
    final isConnect = !isAdd && !isSelect && !state.isActive;
    final accent =
        state.isActive ? AppColors.statusConnected : AppColors.accentCool;
    final useSelectSurface =
        isSelect && !state.isActive && !state.isTransitioning;
    final gradient = state.isTransitioning
        ? null
        : state.isActive
            ? AppColors.connectedGradient
            : useSelectSurface
                ? (isDark
                    ? AppColors.selectButtonDarkGradient
                    : AppColors.selectButtonLightGradient)
                : AppColors.connectButtonGradient;
    final foreground = state.isTransitioning || useSelectSurface
        ? theme.colorScheme.onSurface
        : AppColors.onConnectGradient;
    final enabled = onPressed != null && !state.isTransitioning;
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final diameter = (isAdd ? 176.0 : 184.0) + (scale - 1) * 32;
    final ringOpacity = state.isTransitioning
        ? 0.14
        : (isConnect || state.isActive || isAdd ? 0.18 : 0.10);

    return SizedBox.square(
      dimension: diameter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accent.withOpacity(ringOpacity * 0.45),
          border: Border.all(
            color: accent.withOpacity(ringOpacity),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surface,
              gradient: gradient,
              border: Border.all(
                color: accent.withOpacity(
                  state.isTransitioning
                      ? 0.55
                      : (useSelectSurface ? 0.75 : 0.9),
                ),
                width: useSelectSurface ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(
                    state.isTransitioning
                        ? 0.15
                        : (useSelectSurface ? 0.20 : 0.34),
                  ),
                  blurRadius: 28,
                  spreadRadius: state.isActive || isConnect || isAdd ? 2 : 0,
                ),
              ],
            ),
            child: FilledButton(
              style: FilledButton.styleFrom(
                shape: const CircleBorder(),
                backgroundColor: AppColors.transparent,
                disabledBackgroundColor: AppColors.transparent,
                foregroundColor: foreground,
                disabledForegroundColor: foreground,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 16,
                ),
              ),
              onPressed: enabled ? onPressed : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.isTransitioning)
                    SizedBox.square(
                      dimension: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: foreground,
                      ),
                    )
                  else
                    Icon(
                      state.isActive ? Icons.lock_outline_rounded : icon,
                      size: 38,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelMedium
                        .copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
