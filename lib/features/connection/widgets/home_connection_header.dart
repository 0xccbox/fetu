import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Размеры мобильной шапки без системного inset и отдельной строки навигации.
class HomeHeaderGeometry {
  HomeHeaderGeometry._({required this.expanded, required this.compact});

  /// Подбирает высоту с учётом короткого окна и масштаба текста.
  factory HomeHeaderGeometry.of(
    BuildContext context, {
    required double viewportHeight,
    required bool hasLinks,
    required bool showsMetrics,
    required bool showsError,
    required bool hasServerSummary,
    required bool showsServerShortcut,
  }) {
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    // Мини-панель резервирует место только под отображаемые строки.
    final compactButtonHeight = math.max(48.0, 26.0 + 22.0 * scale);
    final compactMetaHeight = showsError
        ? (8.0 + 54.0 * scale)
        : (showsMetrics ? (6.0 + 20.0 * scale) : 0.0);
    final compact = 14.0 +
        compactButtonHeight +
        compactMetaHeight +
        (hasLinks ? 58.0 : 0.0) +
        2.0;
    // Заголовок и подсказка могут занимать несколько строк при 200%.
    final extraTextHeight =
        math.max(0.0, scale - 1) * (hasServerSummary ? 200 : 250);
    final contentHeight = (hasServerSummary ? 410.0 : 440.0) +
        extraTextHeight +
        (showsMetrics ? 92 * scale + 36 : 0) +
        (showsError ? 48 * scale : 0) +
        (showsServerShortcut ? 58 : 0);
    final targetHero = viewportHeight >= 600
        ? (viewportHeight * 0.84).clamp(440.0, 660.0)
        : (viewportHeight * 0.78).clamp(360.0, 480.0);
    final expanded = math.max(targetHero, contentHeight);
    return HomeHeaderGeometry._(expanded: expanded, compact: compact);
  }

  /// Высота полноразмерной панели.
  final double expanded;

  /// Высота закреплённой панели с доступными слоями.
  final double compact;

  /// Расстояние прокрутки до первой строки секции серверов.
  double get collapseExtent => expanded - compact;
}

/// Второй и третий слой V4: сжимающееся действие и закреплённые ссылки.
class HomeConnectionHeader extends StatelessWidget {
  /// Создаёт шапку; оба варианта действия используют одну команду.
  const HomeConnectionHeader({
    super.key,
    required this.geometry,
    required this.expanded,
    required this.compact,
    this.links,
  });

  /// Геометрия всех состояний.
  final HomeHeaderGeometry geometry;

  /// Большая панель подключения.
  final Widget expanded;

  /// Компактная кнопка и данные текущей сессии.
  final Widget compact;

  /// Полоса ссылок, если они есть у активного провайдера.
  final Widget? links;

  @override
  Widget build(BuildContext context) => SliverPersistentHeader(
        pinned: true,
        delegate: _HeaderDelegate(
          geometry: geometry,
          expanded: expanded,
          compact: compact,
          links: links,
        ),
      );
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  _HeaderDelegate({
    required this.geometry,
    required this.expanded,
    required this.compact,
    required this.links,
  });

  final HomeHeaderGeometry geometry;
  final Widget expanded;
  final Widget compact;
  final Widget? links;

  @override
  double get minExtent => geometry.compact;

  @override
  double get maxExtent => geometry.expanded;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final extent = geometry.collapseExtent;
    final t = extent <= 0 ? 1.0 : (shrinkOffset / extent).clamp(0.0, 1.0);
    final expandedOpacity =
        1.0 - const Interval(0.15, 0.52, curve: Curves.easeOut).transform(t);
    final compactOpacity =
        const Interval(0.50, 0.85, curve: Curves.easeInOut).transform(t);
    final linkOpacity =
        const Interval(0.20, 0.85, curve: Curves.easeOut).transform(t);
    final showCompact = t >= 0.50;
    final theme = Theme.of(context);

    return Material(
      color: theme.scaffoldBackgroundColor,
      clipBehavior: Clip.hardEdge,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          if (expandedOpacity > 0)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: maxExtent,
              child: _layer(
                opacity: expandedOpacity,
                interactive: !showCompact,
                child: Transform.translate(
                  offset: Offset(0, -18 * t),
                  child: Transform.scale(
                    scale: lerpDouble(1, 0.88, t)!,
                    alignment: Alignment.topCenter,
                    child: expanded,
                  ),
                ),
              ),
            ),
          if (compactOpacity > 0 || (links != null && linkOpacity > 0))
            Positioned(
              left: 0,
              right: 0,
              top: lerpDouble(12, 0, compactOpacity),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _layer(
                    opacity: compactOpacity,
                    interactive: showCompact,
                    child: compact,
                  ),
                  if (links != null)
                    _layer(
                      opacity: linkOpacity,
                      interactive: linkOpacity >= 0.5,
                      child: links!,
                    ),
                ],
              ),
            ),
          if (overlapsContent || t == 1)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Divider(height: 1),
            ),
        ],
      ),
    );
  }

  Widget _layer({
    required double opacity,
    required bool interactive,
    required Widget child,
  }) =>
      ExcludeFocus(
        excluding: !interactive,
        child: ExcludeSemantics(
          excluding: !interactive,
          child: IgnorePointer(
            ignoring: !interactive,
            child: Opacity(opacity: opacity, child: child),
          ),
        ),
      );

  @override
  bool shouldRebuild(covariant _HeaderDelegate oldDelegate) =>
      maxExtent != oldDelegate.maxExtent ||
      minExtent != oldDelegate.minExtent ||
      expanded != oldDelegate.expanded ||
      compact != oldDelegate.compact ||
      links != oldDelegate.links;
}
