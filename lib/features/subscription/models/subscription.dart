/// Подписка v2: агрегат всех блоков JSON-контракта.
///
/// См. `docs/reference/ФОРМАТ_API_ПОДПИСОК.md`.
library;

import 'package:meta/meta.dart';

import '../../connection/models/server_node.dart';
import 'provider_cabinet.dart';
import 'subscription_branding.dart';
import 'subscription_cascade.dart';
import 'subscription_node.dart';
import 'subscription_split_tunnel.dart';

/// Настройки обновления подписки (`update`).
@immutable
class SubscriptionUpdate {
  /// Создаёт блок обновления.
  const SubscriptionUpdate({
    required this.url,
    this.intervalSeconds = 3600,
    this.signaturePublicKey,
  });

  /// URL автообновления.
  final String url;

  /// Интервал обновления (секунды).
  final int intervalSeconds;

  /// Публичный ключ Ed25519 (base64) для проверки следующих обновлений.
  final String? signaturePublicKey;

  /// Восстанавливает блок из JSON.
  factory SubscriptionUpdate.fromJson(Map<String, dynamic> json) =>
      SubscriptionUpdate(
        url: json['url'] as String? ?? '',
        intervalSeconds: (json['interval'] as num?)?.toInt() ?? 3600,
        signaturePublicKey: json['signature_public_key'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'url': url,
        'interval': intervalSeconds,
        if (signaturePublicKey != null)
          'signature_public_key': signaturePublicKey,
      };
}

/// Иммутабельная подписка провайдера.
@immutable
class Subscription {
  /// Создаёт подписку.
  const Subscription({
    required this.version,
    required this.name,
    required this.nodes,
    this.description,
    this.expireAt,
    this.createdAt,
    this.update,
    this.splitTunnel,
    this.cascade,
    this.branding,
    this.cabinet,
  });

  /// Версия формата контракта.
  final int version;

  /// Название сервиса.
  final String name;

  /// Описание.
  final String? description;

  /// Дата окончания подписки.
  final DateTime? expireAt;

  /// Дата генерации конфига.
  final DateTime? createdAt;

  /// Настройки автообновления.
  final SubscriptionUpdate? update;

  /// Узлы подписки.
  final List<SubscriptionNode> nodes;

  /// Split Tunneling-правила провайдера.
  final SubscriptionSplitTunnel? splitTunnel;

  /// Конфигурация мульти-каскадов (`features.cascade`).
  final SubscriptionCascade? cascade;

  /// White-label брендинг.
  final SubscriptionBranding? branding;

  /// Кабинет провайдера.
  final ProviderCabinet? cabinet;

  /// Истекла ли подписка.
  bool get isExpired => expireAt != null && expireAt!.isBefore(DateTime.now());

  /// Включён ли умный выбор сервера для этой подписки (`branding.features.smart_selection`).
  bool get isSmartSelectionEnabled =>
      nodes.isNotEmpty && (branding?.smartSelectionEnabled ?? false);

  /// Восстанавливает подписку из JSON контракта.
  ///
  /// Повреждённые блоки пропускаются; критичные поля валидируются
  /// отдельно в парсере (`SubscriptionParser`).
  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
        version: (json['version'] as num?)?.toInt() ?? 0,
        name: (json['name'] as String? ?? '').trim(),
        description: json['description'] as String?,
        expireAt: DateTime.tryParse(json['expire_at'] as String? ?? ''),
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
        update: json['update'] is Map<String, dynamic>
            ? SubscriptionUpdate.fromJson(
                json['update'] as Map<String, dynamic>,
              )
            : null,
        nodes: List.unmodifiable([
          for (final entry in (json['nodes'] as List? ?? const []))
            if (entry is Map<String, dynamic>) SubscriptionNode.fromJson(entry),
        ]),
        splitTunnel: _splitTunnelFrom(json),
        cascade: _cascadeFrom(json),
        branding: json['branding'] is Map<String, dynamic>
            ? SubscriptionBranding.fromJson(
                json['branding'] as Map<String, dynamic>,
              )
            : null,
        cabinet: ProviderCabinet.fromJson(json),
      );

  static SubscriptionSplitTunnel? _splitTunnelFrom(
    Map<String, dynamic> json,
  ) {
    final features = json['features'];
    if (features is! Map<String, dynamic>) return null;
    final split = features['split_tunnel'];
    if (split is! Map<String, dynamic>) return null;
    return SubscriptionSplitTunnel.fromJson(split);
  }

  static SubscriptionCascade? _cascadeFrom(
    Map<String, dynamic> json,
  ) {
    final features = json['features'];
    if (features is! Map<String, dynamic>) return null;
    final cascade = features['cascade'];
    if (cascade is! Map<String, dynamic>) return null;
    return SubscriptionCascade.fromJson(cascade);
  }

  /// Возвращает список входных каскадных узлов для выходного узла [node].
  List<ServerNode> resolveRelayCandidates(SubscriptionNode node) =>
      cascade?.resolveRelayServerNodes(node.id) ?? const <ServerNode>[];

  /// Сериализует подписку в JSON (диагностика/восстановление).
  Map<String, dynamic> toJson() => {
        'version': version,
        'name': name,
        if (description != null) 'description': description,
        if (expireAt != null) 'expire_at': expireAt!.toIso8601String(),
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (update != null) 'update': update!.toJson(),
        'nodes': [for (final node in nodes) node.toJson()],
        'features': {
          if (splitTunnel != null) 'split_tunnel': splitTunnel!.toJson(),
          if (cascade != null) 'cascade': cascade!.toJson(),
        },
        if (branding != null) 'branding': branding!.toJson(),
        if (cabinet != null) ...cabinet!.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      other is Subscription &&
      other.version == version &&
      other.name == name &&
      other.expireAt == expireAt;

  @override
  int get hashCode => Object.hash(version, name, expireAt);

  @override
  String toString() => 'Subscription(v$version, $name, ${nodes.length} nodes, '
      'expired: $isExpired)';
}
