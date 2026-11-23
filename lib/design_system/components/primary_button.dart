/// Главная кнопка подключения VPN.
///
/// Крупная кнопка с градиентом, используется как основной CTA на главном экране.
/// Поддерживает состояния: idle/loading/connected.
library;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../typography/app_typography.dart';

/// Состояние кнопки подключения.
enum ConnectionButtonState {
  /// Готова к подключению
  idle,

  /// Идёт подключение (показываем loader)
  loading,

  /// Подключено (можно отключить)
  connected,
}

/// Главная кнопка подключения/отключения VPN.
///
/// Пример:
/// ```dart
/// PrimaryButton(
///   state: ConnectionButtonState.idle,
///   onPressed: () => _connectToVpn(),
/// )
/// ```
class PrimaryButton extends StatelessWidget {
  /// Текущее состояние кнопки
  final ConnectionButtonState state;

  /// Callback при нажатии
  final VoidCallback? onPressed;

  /// Текст кнопки (из AppLocalizations; обязателен — правило 14)
  final String label;

  /// Размер кнопки (large = 60px height, normal = 48px)
  final bool large;

  const PrimaryButton({
    required this.state,
    required this.label,
    this.onPressed,
    this.large = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final buttonHeight = large ? 60.0 : 48.0;
    final isLoading = state == ConnectionButtonState.loading;
    final isConnected = state == ConnectionButtonState.connected;

    // Градиент зависит от состояния
    final gradient = isConnected
        ? AppColors.connectedGradient
        : AppColors.connectButtonGradient;

    return Container(
      height: buttonHeight,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(large ? 16 : 12),
        boxShadow: [
          BoxShadow(
            color:
                (isConnected ? AppColors.statusConnected : AppColors.accentCool)
                    .withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(large ? 16 : 12),
          child: Center(
            child: isLoading
                ? _buildLoadingIndicator()
                : _buildButtonContent(isConnected),
          ),
        ),
      ),
    );
  }

  /// Индикатор загрузки (белый circular progress)
  Widget _buildLoadingIndicator() {
    return const SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }

  /// Контент кнопки (текст + иконка)
  Widget _buildButtonContent(bool isConnected) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Иконка
        Icon(
          isConnected ? Icons.power_off : Icons.power_settings_new,
          color: Colors.white,
          size: large ? 24 : 20,
        ),

        const SizedBox(width: 12),

        // Текст
        Text(
          label,
          style: (large ? AppTypography.h4 : AppTypography.labelLarge).copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Компактная кнопка (для secondary actions).
///
/// Пример: кнопки "Выбрать сервер", "Настройки" и т.д.
class SecondaryButton extends StatelessWidget {
  /// Текст кнопки
  final String label;

  /// Callback при нажатии
  final VoidCallback? onPressed;

  /// Иконка (опционально)
  final IconData? icon;

  /// Цвет акцента
  final Color? accentColor;

  const SecondaryButton({
    required this.label,
    this.onPressed,
    this.icon,
    this.accentColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAccentColor = accentColor ?? AppColors.accentCool;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: effectiveAccentColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: effectiveAccentColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    color: effectiveAccentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
