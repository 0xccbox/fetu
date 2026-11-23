/// Единая точка входа для дизайн-системы Fetu.
///
/// Экспортирует все компоненты, темы, типографику и цвета.
/// Использование:
/// ```dart
/// import 'package:fetu/design_system/design_system.dart';
/// ```
library design_system;

// ============================================================================
// COMPONENTS
// ============================================================================
export 'components/metric_card.dart';
export 'components/primary_button.dart';
export 'components/status_badge.dart';

// ============================================================================
// THEME
// ============================================================================
export 'theme/app_colors.dart';
export 'theme/app_theme.dart';
export 'theme/theme_controller.dart';

// ============================================================================
// TYPOGRAPHY
// ============================================================================
export 'typography/app_typography.dart';
