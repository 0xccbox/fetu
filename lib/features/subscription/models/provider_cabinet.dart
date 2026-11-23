/// Кабинет провайдера: `account`, `announcements`, `provider_custom_cards`,
/// `node_badges_catalog`, `developer_meta` (контракт v2).
library;

import 'package:meta/meta.dart';

/// Информация о трафике аккаунта.
@immutable
class TrafficInfo {
  /// Создаёт блок трафика.
  const TrafficInfo({
    required this.usedBytes,
    required this.limitBytes,
    this.resetAt,
  });

  /// Использовано байт.
  final int usedBytes;

  /// Лимит байт (0 = безлимит).
  final int limitBytes;

  /// Дата сброса счётчика.
  final DateTime? resetAt;

  /// Доля использованного трафика (0..1); безлимит → 0.
  double get usedFraction =>
      limitBytes <= 0 ? 0 : (usedBytes / limitBytes).clamp(0.0, 1.0);

  /// Восстанавливает блок из JSON.
  factory TrafficInfo.fromJson(Map<String, dynamic> json) => TrafficInfo(
        usedBytes: (json['used_bytes'] as num?)?.toInt() ?? 0,
        limitBytes: (json['limit_bytes'] as num?)?.toInt() ?? 0,
        resetAt: DateTime.tryParse(json['reset_at'] as String? ?? ''),
      );

  Map<String, dynamic> toJson() => {
        'used_bytes': usedBytes,
        'limit_bytes': limitBytes,
        if (resetAt != null) 'reset_at': resetAt!.toIso8601String(),
      };
}

/// Информация об устройствах аккаунта.
@immutable
class DevicesInfo {
  /// Создаёт блок устройств.
  const DevicesInfo({
    required this.currentCount,
    required this.maxLimit,
    this.manageUrl,
  });

  /// Текущее число подключённых устройств.
  final int currentCount;

  /// Максимум устройств.
  final int maxLimit;

  /// URL управления устройствами.
  final String? manageUrl;

  /// Восстанавливает блок из JSON.
  factory DevicesInfo.fromJson(Map<String, dynamic> json) => DevicesInfo(
        currentCount: (json['current_count'] as num?)?.toInt() ?? 0,
        maxLimit: (json['max_limit'] as num?)?.toInt() ?? 0,
        manageUrl: json['manage_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'current_count': currentCount,
        'max_limit': maxLimit,
        if (manageUrl != null) 'manage_url': manageUrl,
      };
}

/// Биллинг аккаунта.
@immutable
class BillingInfo {
  /// Создаёт блок биллинга.
  const BillingInfo({
    this.balanceFormatted,
    this.autoRenew = false,
    this.renewUrl,
    this.promoCodeAvailable = false,
  });

  /// Баланс в форматированном виде («450 ₽»).
  final String? balanceFormatted;

  /// Включено ли автопродление.
  final bool autoRenew;

  /// URL быстрого продления.
  final String? renewUrl;

  /// Доступен ли промокод.
  final bool promoCodeAvailable;

  /// Восстанавливает блок из JSON.
  factory BillingInfo.fromJson(Map<String, dynamic> json) => BillingInfo(
        balanceFormatted: json['balance_formatted'] as String?,
        autoRenew: json['auto_renew'] as bool? ?? false,
        renewUrl: json['renew_url'] as String?,
        promoCodeAvailable: json['promo_code_available'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        if (balanceFormatted != null) 'balance_formatted': balanceFormatted,
        'auto_renew': autoRenew,
        if (renewUrl != null) 'renew_url': renewUrl,
        'promo_code_available': promoCodeAvailable,
      };
}

/// Аккаунт пользователя у провайдера.
@immutable
class AccountInfo {
  /// Создаёт блок аккаунта.
  const AccountInfo({
    required this.planName,
    required this.status,
    this.expireAt,
    this.traffic = const TrafficInfo(usedBytes: 0, limitBytes: 0),
    this.devices = const DevicesInfo(currentCount: 0, maxLimit: 0),
    this.billing = const BillingInfo(),
  });

  /// Название тарифа.
  final String planName;

  /// Статус (`active`, `expired`, `suspended`...).
  final String status;

  /// Дата окончания.
  final DateTime? expireAt;

  /// Трафик.
  final TrafficInfo traffic;

  /// Устройства.
  final DevicesInfo devices;

  /// Биллинг.
  final BillingInfo billing;

  /// Истёк ли аккаунт.
  bool get isExpired =>
      status.toLowerCase() == 'expired' ||
      (expireAt != null && expireAt!.isBefore(DateTime.now()));

  /// Восстанавливает аккаунт из JSON.
  factory AccountInfo.fromJson(Map<String, dynamic> json) => AccountInfo(
        planName: json['plan_name'] as String? ?? '',
        status: json['status'] as String? ?? 'active',
        expireAt: DateTime.tryParse(json['expire_at'] as String? ?? ''),
        traffic: json['traffic'] is Map<String, dynamic>
            ? TrafficInfo.fromJson(json['traffic'] as Map<String, dynamic>)
            : const TrafficInfo(usedBytes: 0, limitBytes: 0),
        devices: json['devices'] is Map<String, dynamic>
            ? DevicesInfo.fromJson(json['devices'] as Map<String, dynamic>)
            : const DevicesInfo(currentCount: 0, maxLimit: 0),
        billing: json['billing'] is Map<String, dynamic>
            ? BillingInfo.fromJson(json['billing'] as Map<String, dynamic>)
            : const BillingInfo(),
      );

  Map<String, dynamic> toJson() => {
        'plan_name': planName,
        'status': status,
        if (expireAt != null) 'expire_at': expireAt!.toIso8601String(),
        'traffic': traffic.toJson(),
        'devices': devices.toJson(),
        'billing': billing.toJson(),
      };
}

/// Объявление провайдера (`announcements[]`).
@immutable
class Announcement {
  /// Создаёт объявление.
  const Announcement({
    required this.id,
    required this.title,
    this.type = 'info',
    this.message,
    this.actionLabel,
    this.actionUrl,
    this.dismissible = true,
    this.expiresAt,
  });

  /// Идентификатор (для dismiss; персистентность скрытия — backlog).
  final String id;

  /// Тип (`info`, `warning`, `critical`).
  final String type;

  /// Заголовок.
  final String title;

  /// Текст.
  final String? message;

  /// Кнопка действия.
  final String? actionLabel;

  /// URL действия.
  final String? actionUrl;

  /// Можно ли скрыть.
  final bool dismissible;

  /// Дата актуальности.
  final DateTime? expiresAt;

  /// Истекло ли объявление.
  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  /// Восстанавливает объявление из JSON.
  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: json['id'] as String? ?? '',
        type: json['type'] as String? ?? 'info',
        title: json['title'] as String? ?? '',
        message: json['message'] as String?,
        actionLabel: json['action_label'] as String?,
        actionUrl: json['action_url'] as String?,
        dismissible: json['dismissible'] as bool? ?? true,
        expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? ''),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        if (message != null) 'message': message,
        if (actionLabel != null) 'action_label': actionLabel,
        if (actionUrl != null) 'action_url': actionUrl,
        'dismissible': dismissible,
        if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
      };
}

/// Карточка провайдера (`provider_custom_cards[]`).
@immutable
class ProviderCard {
  /// Создаёт карточку.
  const ProviderCard({
    required this.id,
    required this.title,
    this.subtitle,
    this.copyValue,
    this.actionUrl,
  });

  /// Идентификатор карточки.
  final String id;

  /// Заголовок.
  final String title;

  /// Подзаголовок.
  final String? subtitle;

  /// Значение для копирования (реферальный код и т.п.).
  final String? copyValue;

  /// URL действия.
  final String? actionUrl;

  /// Восстанавливает карточку из JSON.
  factory ProviderCard.fromJson(Map<String, dynamic> json) => ProviderCard(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String?,
        copyValue: json['copy_value'] as String?,
        actionUrl: json['action_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (subtitle != null) 'subtitle': subtitle,
        if (copyValue != null) 'copy_value': copyValue,
        if (actionUrl != null) 'action_url': actionUrl,
      };
}

/// Бейдж узла из `node_badges_catalog`.
@immutable
class NodeBadge {
  /// Создаёт бейдж.
  const NodeBadge({required this.id, required this.label, this.icon});

  /// Идентификатор (`gaming`, `streaming`...).
  final String id;

  /// Отображаемая метка.
  final String label;

  /// Имя иконки (контрактная).
  final String? icon;

  /// Восстанавливает бейдж из JSON.
  factory NodeBadge.fromJson(String id, Map<String, dynamic> json) => NodeBadge(
        id: id,
        label: json['label'] as String? ?? id,
        icon: json['icon'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        if (icon != null) 'icon': icon,
      };
}

/// Диагностические данные для расширенного режима (`developer_meta`).
@immutable
class DeveloperMeta {
  /// Создаёт блок метаданных.
  const DeveloperMeta({
    this.configGeneratedMs,
    this.backendNode,
    this.abTestGroup,
    this.recommendedUiMode,
    this.diagnosticWebhook,
  });

  /// Время генерации конфига на сервере (мс).
  final int? configGeneratedMs;

  /// Бэкенд-зеркало, отдалшее подписку.
  final String? backendNode;

  /// Ветка A/B-теста.
  final String? abTestGroup;

  /// Рекомендованный режим UI (`simple` / `advanced` / `auto`).
  final String? recommendedUiMode;

  /// Webhook для диагностических отчётов.
  final String? diagnosticWebhook;

  /// Восстанавливает метаданные из JSON.
  factory DeveloperMeta.fromJson(Map<String, dynamic> json) => DeveloperMeta(
        configGeneratedMs: (json['config_generated_ms'] as num?)?.toInt(),
        backendNode: json['backend_node'] as String?,
        abTestGroup: json['ab_test_group'] as String?,
        recommendedUiMode: json['recommended_ui_mode'] as String?,
        diagnosticWebhook: json['diagnostic_webhook'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (configGeneratedMs != null) 'config_generated_ms': configGeneratedMs,
        if (backendNode != null) 'backend_node': backendNode,
        if (abTestGroup != null) 'ab_test_group': abTestGroup,
        if (recommendedUiMode != null) 'recommended_ui_mode': recommendedUiMode,
        if (diagnosticWebhook != null) 'diagnostic_webhook': diagnosticWebhook,
      };
}

/// Агрегат кабинета провайдера.
@immutable
class ProviderCabinet {
  /// Создаёт кабинет.
  const ProviderCabinet({
    this.account,
    this.announcements = const <Announcement>[],
    this.customCards = const <ProviderCard>[],
    this.nodeBadges = const <NodeBadge>[],
    this.developerMeta,
  });

  /// Аккаунт (тариф, трафик, устройства, биллинг).
  final AccountInfo? account;

  /// Объявления провайдера.
  final List<Announcement> announcements;

  /// Кастомные карточки (реферальные программы и т.п.).
  final List<ProviderCard> customCards;

  /// Каталог бейджей узлов.
  final List<NodeBadge> nodeBadges;

  /// Метаданные для разработчиков.
  final DeveloperMeta? developerMeta;

  /// Бейдж по идентификатору.
  NodeBadge? badgeById(String id) {
    for (final badge in nodeBadges) {
      if (badge.id == id) return badge;
    }
    return null;
  }

  /// Актуальные (не истекшие) объявления.
  List<Announcement> get activeAnnouncements =>
      announcements.where((a) => !a.isExpired).toList();

  /// Собирает кабинет из корневых блоков контракта.
  static ProviderCabinet? fromJson(Map<String, dynamic> json) {
    final hasAny = json['account'] != null ||
        json['announcements'] != null ||
        json['provider_custom_cards'] != null ||
        json['node_badges_catalog'] != null ||
        json['developer_meta'] != null;
    if (!hasAny) return null;

    return ProviderCabinet(
      account: json['account'] is Map<String, dynamic>
          ? AccountInfo.fromJson(json['account'] as Map<String, dynamic>)
          : null,
      announcements: List.unmodifiable([
        for (final entry in (json['announcements'] as List? ?? const []))
          if (entry is Map<String, dynamic>) Announcement.fromJson(entry),
      ]),
      customCards: List.unmodifiable([
        for (final entry
            in (json['provider_custom_cards'] as List? ?? const []))
          if (entry is Map<String, dynamic>) ProviderCard.fromJson(entry),
      ]),
      nodeBadges: _parseBadges(json['node_badges_catalog']),
      developerMeta: json['developer_meta'] is Map<String, dynamic>
          ? DeveloperMeta.fromJson(
              json['developer_meta'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  static List<NodeBadge> _parseBadges(Object? raw) {
    if (raw is! Map<String, dynamic>) return const <NodeBadge>[];
    return List.unmodifiable([
      for (final entry in raw.entries)
        if (entry.value is Map<String, dynamic>)
          NodeBadge.fromJson(entry.key, entry.value as Map<String, dynamic>),
    ]);
  }

  Map<String, dynamic> toJson() => {
        if (account != null) 'account': account!.toJson(),
        'announcements': [for (final a in announcements) a.toJson()],
        'provider_custom_cards': [
          for (final c in customCards) c.toJson(),
        ],
        'node_badges_catalog': {
          for (final badge in nodeBadges) badge.id: badge.toJson(),
        },
        if (developerMeta != null) 'developer_meta': developerMeta!.toJson(),
      };
}
