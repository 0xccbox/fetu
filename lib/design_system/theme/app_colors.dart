/// Цветовая палитра приложения в стиле production slate.
///
/// Базируется на глубоком navy/slate с холодными акцентами (sky/cyan)
/// и тёплым action-цветом (orange). Никаких пастелей или дефолтного purple.
library;

import 'package:flutter/material.dart';

/// Цветовая схема с поддержкой светлой и тёмной темы.
class AppColors {
  const AppColors._();

  // ============================================================================
  // БАЗОВЫЕ ЦВЕТА (DARK THEME — ОСНОВНАЯ)
  // ============================================================================

  /// Фон экрана (глубокий slate)
  static const Color darkBackground = Color(0xFF0B0E14);

  /// Поверхности (карточки, модальные окна)
  static const Color darkSurface = Color(0xFF1E293B);

  /// Вторичная поверхность (более светлая)
  static const Color darkSurfaceVariant = Color(0xFF334155);

  /// Основной текст (хрустящий off-white)
  static const Color darkTextPrimary = Color(0xFFF8FAFC);

  /// Вторичный текст (приглушённый)
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  /// Границы (hairline slate)
  static const Color darkBorder = Color(0xFF334155);

  // ============================================================================
  // БАЗОВЫЕ ЦВЕТА (LIGHT THEME — ОПЦИОНАЛЬНАЯ)
  // ============================================================================

  /// Фон экрана (светлый)
  static const Color lightBackground = Color(0xFFF8FAFC);

  /// Поверхности (карточки)
  static const Color lightSurface = Color(0xFFFFFFFF);

  /// Вторичная поверхность
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9);

  /// Основной текст (тёмный)
  static const Color lightTextPrimary = Color(0xFF0F172A);

  /// Вторичный текст
  static const Color lightTextSecondary = Color(0xFF475569);

  /// Границы
  static const Color lightBorder = Color(0xFFE2E8F0);

  // ============================================================================
  // АКЦЕНТНЫЕ ЦВЕТА (УНИВЕРСАЛЬНЫЕ)
  // ============================================================================

  /// Холодный электрический акцент (sky)
  static const Color accentCool = Color(0xFF38BDF8);

  /// Альтернативный холодный акцент (cyan)
  static const Color accentCoolAlt = Color(0xFF22D3EE);

  /// Тёплый action-акцент (orange)
  static const Color accentWarm = Color(0xFFF97316);

  /// Альтернативный тёплый акцент (brass)
  static const Color accentWarmAlt = Color(0xFFF59E0B);

  // ============================================================================
  // СЕМАНТИЧЕСКИЕ ЦВЕТА (СТАТУСЫ)
  // ============================================================================

  /// VPN отключён (нейтральный серый)
  static const Color statusDisconnected = Color(0xFF64748B);

  /// VPN подключается (жёлтый/оранжевый)
  static const Color statusConnecting = Color(0xFFF59E0B);

  /// VPN подключён (зелёный)
  static const Color statusConnected = Color(0xFF10B981);

  /// Ошибка (красный)
  static const Color statusError = Color(0xFFEF4444);

  /// Контрастный цвет текста ошибки на светлой поверхности.
  static const Color lightErrorText = Color(0xFFB91C1C);

  /// Предупреждение (янтарный)
  static const Color statusWarning = Color(0xFFF59E0B);

  // ============================================================================
  // ПРОТОКОЛЬНЫЕ ИНДИКАТОРЫ
  // ============================================================================

  /// Hysteria2 (UDP, быстрый) — cyan
  static const Color protocolHysteria = Color(0xFF22D3EE);

  /// AmneziaWG (UDP, стелс) — teal
  static const Color protocolAmneziaWG = Color(0xFF14B8A6);

  /// VLESS Reality (TCP, надёжный) — sky
  static const Color protocolReality = Color(0xFF38BDF8);

  /// NaiveProxy (TCP, универсальный) — orange
  static const Color protocolNaive = Color(0xFFF97316);

  /// Mieru (TCP, резервный) — amber
  static const Color protocolMieru = Color(0xFFF59E0B);

  // ============================================================================
  // ГРАДИЕНТЫ
  // ============================================================================

  /// Прозрачный фон для кнопок поверх градиентных контейнеров.
  static const Color transparent = Colors.transparent;

  /// Градиент для кнопки подключения (cyan → sky)
  static const Gradient connectButtonGradient = LinearGradient(
    colors: [accentCoolAlt, accentCool],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Контрастный текст и иконки на голубой/зелёной кнопке подключения.
  static const Color onConnectGradient = darkBackground;

  /// Градиент кнопки «Выбрать сервер» (тёмная тема).
  static const Gradient selectButtonDarkGradient = LinearGradient(
    colors: [Color(0xFF102A43), Color(0xFF183B59)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Градиент кнопки «Выбрать сервер» (светлая тема).
  static const Gradient selectButtonLightGradient = LinearGradient(
    colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Градиент для статуса "подключено" (emerald → green)
  static const Gradient connectedGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============================================================================
  // OVERLAY & EFFECTS
  // ============================================================================

  /// Затемнение для модальных окон (50% прозрачности)
  static const Color overlay = Color(0x80000000);

  /// Лёгкое затемнение (для карточек на hover)
  static const Color hoverOverlay = Color(0x0AFFFFFF);

  /// Мягкая тень для карточек и уведомлений (10% чёрного)
  static const Color shadowSoft = Color(0x1A000000);

  /// Градиент карточки «Умный выбор» (тёмная тема)
  static const Gradient smartSelectionDarkGradient = LinearGradient(
    colors: [Color(0xFF0F172A), darkSurface],
  );

  /// Градиент карточки «Умный выбор» (светлая тема)
  static const Gradient smartSelectionLightGradient = LinearGradient(
    colors: [lightSurfaceVariant, lightBorder],
  );

  /// Шторка снизу (градиент для shadow)
  static const Gradient bottomSheetGradient = LinearGradient(
    colors: [Color(0x00000000), Color(0x80000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
