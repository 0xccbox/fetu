/// Конфигурация тем приложения (светлая и тёмная).
///
/// Тёмная тема — основная, светлая — опциональная.
/// Используется Material Design 3 (useMaterial3: true).
library;

import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Основная тема приложения (тёмная).
///
/// Базируется на глубоком slate (#0B0E14) с холодными акцентами.
ThemeData get darkTheme => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // ========================================================================
      // ЦВЕТОВАЯ СХЕМА
      // ========================================================================
      colorScheme: const ColorScheme.dark(
        // Основные цвета
        primary: AppColors.accentCool, // Sky
        onPrimary: AppColors.darkBackground,
        secondary: AppColors.accentWarm, // Orange
        tertiary: AppColors.accentCoolAlt, // Cyan

        // Фоны
        surface: AppColors.darkSurface, // Карточки
        onSurface: AppColors.darkTextPrimary, // Текст на поверхностях
        onSurfaceVariant: AppColors.darkTextSecondary,

        // Ошибки
        error: AppColors.statusError,
        onError: AppColors.darkTextPrimary,

        // Границы и overlay
        outline: AppColors.darkBorder,
        outlineVariant: AppColors.darkSurfaceVariant,
      ),

      // ========================================================================
      // БАЗОВЫЕ ЭЛЕМЕНТЫ
      // ========================================================================
      scaffoldBackgroundColor: AppColors.darkBackground,
      dividerColor: AppColors.darkBorder,

      // ========================================================================
      // КАРТОЧКИ
      // ========================================================================
      cardTheme: CardTheme(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: AppColors.darkBorder,
            width: 1,
          ),
        ),
      ),

      // ========================================================================
      // КНОПКИ
      // ========================================================================
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentCool,
          foregroundColor: AppColors.darkBackground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkTextPrimary,
          side: const BorderSide(color: AppColors.darkBorder),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // ========================================================================
      // APP BAR
      // ========================================================================
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        centerTitle: true,
      ),

      // ========================================================================
      // BOTTOM SHEET
      // ========================================================================
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        modalBackgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),

      // ========================================================================
      // INPUT FIELDS
      // ========================================================================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accentCool, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.statusError),
        ),
        labelStyle: const TextStyle(color: AppColors.darkTextSecondary),
        hintStyle: const TextStyle(color: AppColors.darkTextSecondary),
      ),
    );

/// Светлая тема (опциональная).
///
/// Инверсия тёмной темы для дневного использования.
ThemeData get lightTheme => ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // ========================================================================
      // ЦВЕТОВАЯ СХЕМА
      // ========================================================================
      colorScheme: const ColorScheme.light(
        // Основные цвета
        primary: AppColors.accentCool,
        onPrimary: AppColors.darkBackground,
        secondary: AppColors.accentWarm,
        tertiary: AppColors.accentCoolAlt,

        // Фоны
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightTextPrimary,
        onSurfaceVariant: AppColors.lightTextSecondary,

        // Ошибки
        error: AppColors.lightErrorText,
        onError: Colors.white,

        // Границы
        outline: AppColors.lightBorder,
        outlineVariant: AppColors.lightSurfaceVariant,
      ),

      // ========================================================================
      // БАЗОВЫЕ ЭЛЕМЕНТЫ
      // ========================================================================
      scaffoldBackgroundColor: AppColors.lightBackground,
      dividerColor: AppColors.lightBorder,

      // ========================================================================
      // КАРТОЧКИ
      // ========================================================================
      cardTheme: CardTheme(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),

      // ========================================================================
      // КНОПКИ
      // ========================================================================
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentCool,
          foregroundColor: AppColors.darkBackground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightTextPrimary,
          side: const BorderSide(color: AppColors.lightBorder),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // ========================================================================
      // APP BAR
      // ========================================================================
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        centerTitle: true,
      ),

      // ========================================================================
      // BOTTOM SHEET
      // ========================================================================
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface,
        modalBackgroundColor: AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),

      // ========================================================================
      // INPUT FIELDS
      // ========================================================================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accentCool, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.statusError),
        ),
        labelStyle: const TextStyle(color: AppColors.lightTextSecondary),
        hintStyle: const TextStyle(color: AppColors.lightTextSecondary),
      ),
    );
