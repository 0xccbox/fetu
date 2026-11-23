/// Модель диагностического отчёта (immutable, AGENTS.md правило 10).
///
/// Содержит снимок состояния приложения для разработчиков:
/// версию, режим UI, состояние туннеля, протокол, метрики,
/// Real-Delay, split-правила и данные подписки.
///
/// Правило 16: отчёт НЕ содержит адресов серверов, URL и
/// credentials; `diagnosticWebhook` провайдера передаётся только
/// фактом наличия, без значения.
library;

import 'package:flutter/foundation.dart';

import '../../connection/models/connection_metrics.dart';
import '../../connection/models/connection_state.dart';
import '../../connection/models/server_node.dart';
import '../../settings/models/ui_experience_mode.dart';
import '../../subscription/models/provider_cabinet.dart';

/// Снимок состояния для отчёта (собирается в DI-корне).
@immutable
class DiagnosticSnapshot {
  /// Создаёт снимок.
  const DiagnosticSnapshot({
    required this.uiMode,
    required this.tunnelMode,
    required this.connectionState,
    required this.activeSplitRules,
    required this.totalSplitRules,
    this.protocol,
    this.metrics,
    this.providerName,
    this.subscriptionExpiresAt,
    this.subscriptionNodeCount,
    this.developerMeta,
  });

  /// Текущий режим интерфейса.
  final UiExperienceMode uiMode;

  /// Режим VPN-ядра: 'real' (sing-box) или 'mock' (разработка).
  final String tunnelMode;

  /// Состояние подключения.
  final ConnectionState connectionState;

  /// Протокол текущего узла (null — узел не выбран).
  final ProtocolType? protocol;

  /// Метрики подключения (null — туннель не активен).
  final ConnectionMetrics? metrics;

  /// Число активных правил маршрутизации.
  final int activeSplitRules;

  /// Общее число правил маршрутизации.
  final int totalSplitRules;

  /// Название провайдера подписки (null — подписки нет).
  final String? providerName;

  /// Срок действия подписки.
  final DateTime? subscriptionExpiresAt;

  /// Число узлов подписки.
  final int? subscriptionNodeCount;

  /// Метаданные провайдера для расширенного режима.
  final DeveloperMeta? developerMeta;
}

/// Готовый диагностический отчёт.
@immutable
class DiagnosticReport {
  /// Создаёт отчёт.
  const DiagnosticReport({
    required this.snapshot,
    required this.generatedAt,
    required this.appVersion,
    this.realDelayMs,
  });

  /// Снимок состояния.
  final DiagnosticSnapshot snapshot;

  /// Момент генерации отчёта.
  final DateTime generatedAt;

  /// Версия приложения.
  final String appVersion;

  /// Последний результат зонда Real-Delay (null — не измерялся).
  final int? realDelayMs;

  /// Есть ли метрики активного туннеля.
  bool get hasMetrics => snapshot.metrics != null;
}
