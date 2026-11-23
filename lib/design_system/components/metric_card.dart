/// Карточка метрики (скорость, трафик, пинг).
///
/// Компактная карточка с иконкой, заголовком и значением метрики.
/// Используется на главном экране для отображения статистики подключения.
library;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../typography/app_typography.dart';

/// Компактная карточка метрики с иконкой и значением.
///
/// Пример:
/// ```dart
/// MetricCard(
///   icon: Icons.arrow_downward,
///   label: 'Скорость загрузки',
///   value: '12.5 MB/s',
/// )
/// ```
class MetricCard extends StatelessWidget {
  /// Иконка метрики
  final IconData icon;

  /// Заголовок метрики
  final String label;

  /// Значение метрики (форматированное)
  final String value;

  /// Цвет акцента (опционально, по умолчанию accentCool)
  final Color? accentColor;

  /// Плотная компоновка (для списка метрик)
  final bool compact;

  const MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    this.accentColor,
    this.compact = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAccentColor = accentColor ?? AppColors.accentCool;

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.darkBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Иконка в круглом контейнере
          Container(
            width: compact ? 36 : 40,
            height: compact ? 36 : 40,
            decoration: BoxDecoration(
              color: effectiveAccentColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: effectiveAccentColor,
              size: compact ? 18 : 20,
            ),
          ),

          SizedBox(width: compact ? 12 : 16),

          // Текст
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок
                Text(
                  label,
                  style: compact
                      ? AppTypography.labelSmall
                      : AppTypography.labelMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 2),

                // Значение (моношрифт для цифр)
                Text(
                  value,
                  style: compact
                      ? AppTypography.mono
                      : AppTypography.monoLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Карточка с большой метрикой (для главного экрана).
///
/// Отображает одну крупную метрику с описанием и дополнительной информацией.
class LargeMetricCard extends StatelessWidget {
  /// Иконка метрики
  final IconData icon;

  /// Заголовок
  final String label;

  /// Основное значение (крупное)
  final String value;

  /// Дополнительная информация (опционально)
  final String? subtitle;

  /// Цвет акцента
  final Color? accentColor;

  const LargeMetricCard({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    this.accentColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAccentColor = accentColor ?? AppColors.accentCool;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.darkBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок с иконкой
          Row(
            children: [
              Icon(
                icon,
                color: effectiveAccentColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.darkTextSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Крупное значение
          Text(
            value,
            style: AppTypography.h2.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [
                FontFeature.tabularFigures(),
              ],
            ),
          ),

          // Подзаголовок (если есть)
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.darkTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
