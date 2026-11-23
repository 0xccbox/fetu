import 'package:fetu/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Чип фильтра серверов (страна / протокол / сортировка).
class ServerFilterChip extends StatelessWidget {
  /// Создаёт чип фильтра.
  const ServerFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  /// Подпись чипа.
  final String label;

  /// Активен ли фильтр.
  final bool selected;

  /// Обработчик нажатия.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilterChip(
      label: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: selected
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurface,
        ),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.accentCool,
      checkmarkColor: theme.colorScheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
