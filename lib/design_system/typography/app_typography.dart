/// Типографическая система приложения.
///
/// Базируется на contemporary product sans (Inter, Sora, IBM Plex Sans).
/// Tight confident headings + mono для технических меток.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Типографические стили приложения.
class AppTypography {
  const AppTypography._();

  /// Использует системные шрифты в виджет-тестах без доступа к сети.
  @visibleForTesting
  static bool useSystemFonts = false;

  static TextStyle _inter(TextStyle style) =>
      useSystemFonts ? style : GoogleFonts.inter(textStyle: style);

  static TextStyle _mono(TextStyle style) => useSystemFonts
      ? style.copyWith(fontFamily: 'monospace')
      : GoogleFonts.jetBrainsMono(textStyle: style);

  // ============================================================================
  // БАЗОВЫЙ ШРИФТ (INTER)
  // ============================================================================

  /// Базовое семейство шрифтов (Inter — геометрический sans-serif)
  static TextStyle get _baseTextStyle => _inter(
        const TextStyle(
          letterSpacing: -0.01, // Tight spacing для современного вида
        ),
      );

  // ============================================================================
  // ЗАГОЛОВКИ (HEADINGS)
  // ============================================================================

  /// H1 — главный заголовок экрана (32px, bold)
  static TextStyle get h1 => _baseTextStyle.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.02,
      );

  /// H2 — крупный заголовок секции (24px, semibold)
  static TextStyle get h2 => _baseTextStyle.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.015,
      );

  /// H3 — средний заголовок (20px, semibold)
  static TextStyle get h3 => _baseTextStyle.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  /// H4 — малый заголовок (18px, medium)
  static TextStyle get h4 => _baseTextStyle.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 1.4,
      );

  // ============================================================================
  // ТЕКСТ ТЕЛА (BODY)
  // ============================================================================

  /// Body Large — основной текст (16px, regular)
  static TextStyle get bodyLarge => _baseTextStyle.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  /// Body Medium — стандартный текст (14px, regular)
  static TextStyle get bodyMedium => _baseTextStyle.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  /// Body Small — мелкий текст (12px, regular)
  static TextStyle get bodySmall => _baseTextStyle.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );

  // ============================================================================
  // ЛЕЙБЛЫ И КНОПКИ
  // ============================================================================

  /// Label Large — крупный лейбл/кнопка (16px, medium)
  static TextStyle get labelLarge => _baseTextStyle.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.2,
      );

  /// Label Medium — стандартный лейбл (14px, medium)
  static TextStyle get labelMedium => _baseTextStyle.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.2,
      );

  /// Label Small — мелкий лейбл (12px, medium)
  static TextStyle get labelSmall => _baseTextStyle.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.2,
      );

  // ============================================================================
  // МОНОПРОСТРАНСТВЕННЫЕ (ДЛЯ МЕТРИК И ТЕХНИЧЕСКИХ ДАННЫХ)
  // ============================================================================

  /// Моношрифт для метрик, timestamps, SKU, команд (JetBrains Mono)
  static TextStyle get mono => _mono(
        const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.4,
          letterSpacing: 0,
        ),
      );

  /// Крупный моношрифт для больших метрик (20px, medium)
  static TextStyle get monoLarge => _mono(
        const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          height: 1.3,
          letterSpacing: 0,
        ),
      );

  /// Мелкий моношрифт для timestamps (12px, regular)
  static TextStyle get monoSmall => _mono(
        const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.4,
          letterSpacing: 0,
        ),
      );

  // ============================================================================
  // ЦИФРЫ С ТАБЛИЧНЫМ ВЫРАВНИВАНИЕМ (ДЛЯ МЕТРИК)
  // ============================================================================

  /// Табличные цифры для метрик (скорость, трафик)
  static TextStyle get tabularNums => _baseTextStyle.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        fontFeatures: const [
          FontFeature.tabularFigures(), // Выравнивание цифр по ширине
        ],
        height: 1.2,
      );

  // ============================================================================
  // СПЕЦИАЛЬНЫЕ СТИЛИ
  // ============================================================================

  /// Стиль для статусных бейджей (12px, bold, uppercase)
  static TextStyle get badge => _baseTextStyle.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: 0.5,
      );

  /// Стиль для подписей (caption) — 11px, regular
  static TextStyle get caption => _baseTextStyle.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        height: 1.3,
      );

  /// Стиль для overline (мелкий uppercase текст) — 10px, medium
  static TextStyle get overline => _baseTextStyle.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        height: 1.2,
        letterSpacing: 0.5,
      );
}

/// Расширение для удобного применения типографики к Text виджетам.
extension TextStyleExtension on Text {
  /// Применить стиль H1
  Text h1() => Text(data ?? '', style: AppTypography.h1.merge(style));

  /// Применить стиль H2
  Text h2() => Text(data ?? '', style: AppTypography.h2.merge(style));

  /// Применить стиль H3
  Text h3() => Text(data ?? '', style: AppTypography.h3.merge(style));

  /// Применить стиль Body Large
  Text bodyLarge() =>
      Text(data ?? '', style: AppTypography.bodyLarge.merge(style));

  /// Применить стиль Body Medium
  Text bodyMedium() =>
      Text(data ?? '', style: AppTypography.bodyMedium.merge(style));

  /// Применить моношрифт
  Text mono() => Text(data ?? '', style: AppTypography.mono.merge(style));
}
