/// Протокол узла подписки (элемент `nodes[].protocols[]`).
library;

import 'package:meta/meta.dart';

import '../../connection/models/server_node.dart';

/// Иммутабельный протокол узла из подписки.
///
/// Credentials хранятся как отображение, чтобы поддерживать новые
/// поля контракта без ломки парсера (обратная совместимость, AGENTS.md
/// правило 30: новые поля добавляются, старые не удаляются).
@immutable
class NodeProtocol {
  /// Создаёт протокол узла.
  const NodeProtocol({
    required this.type,
    required this.port,
    this.priority = 999,
    this.credentials = const <String, dynamic>{},
    this.obfuscation = const <String, dynamic>{},
    this.reality = const <String, dynamic>{},
  });

  /// Сырой тип протокола из контракта (`hysteria2`, `vless`, `naive`...).
  final String type;

  /// Порт сервера.
  final int port;

  /// Приоритет протокола (меньше = выше, failover-порядок).
  final int priority;

  /// Credentials: password / uuid / username / flow / transport / method.
  final Map<String, dynamic> credentials;

  /// Блок обфускации (`salamander`, `http2_padding`, `ja3_presets`...).
  final Map<String, dynamic> obfuscation;

  /// Блок Reality для VLESS (`public_key`, `short_id`, `server_name`).
  final Map<String, dynamic> reality;

  /// Восстанавливает протокол из JSON.
  factory NodeProtocol.fromJson(Map<String, dynamic> json) => NodeProtocol(
        type: (json['type'] as String? ?? '').trim().toLowerCase(),
        port: (json['port'] as num?)?.toInt() ?? 0,
        priority: (json['priority'] as num?)?.toInt() ?? 999,
        credentials: _asMap(json['credentials']) ??
            _extractCredentials(json) ??
            const <String, dynamic>{},
        obfuscation: _asMap(json['obfuscation']) ?? const <String, dynamic>{},
        reality: _asMap(json['reality']) ?? const <String, dynamic>{},
      );

  /// Достаёт известные credential-поля из корня протокола
  /// (в контракте они лежат рядом с `type`/`port`).
  static Map<String, dynamic>? _extractCredentials(
    Map<String, dynamic> json,
  ) {
    const known = {
      'password',
      'uuid',
      'username',
      'flow',
      'transport',
      'method',
      'plugin',
      'plugin_opts',
      'up_mbps',
      'down_mbps',
      'tls_sni',
      'sni',
      'server_name',
      'tls_insecure',
      'insecure',
      'path',
      'host',
      'service_name',
      'private_key',
      'client_private_key',
      'peer_public_key',
      'server_public_key',
      'pre_shared_key',
      'local_address',
      'local_addresses',
      'mtu',
      'reserved',
      'jc',
      'jmin',
      'jmax',
      's1',
      's2',
      'h1',
      'h2',
      'h3',
      'h4',
      'i1',
      'i2',
      'i3',
      'i4',
      'i5',
    };
    final extracted = <String, dynamic>{
      for (final key in known)
        if (json.containsKey(key)) key: json[key],
    };
    return extracted.isEmpty ? null : Map.unmodifiable(extracted);
  }

  static Map<String, dynamic>? _asMap(Object? value) {
    if (value is! Map) return null;
    try {
      return Map.unmodifiable(Map<String, dynamic>.from(value));
    } catch (_) {
      // Нестроковые ключи — битый блок, пропускаем.
      return null;
    }
  }

  /// Сериализует протокол в JSON.
  Map<String, dynamic> toJson() => {
        'type': type,
        'port': port,
        'priority': priority,
        ...credentials,
        if (obfuscation.isNotEmpty) 'obfuscation': obfuscation,
        if (reality.isNotEmpty) 'reality': reality,
      };

  /// Есть ли у протокола блок Reality.
  bool get hasReality => reality.isNotEmpty;

  /// Является ли протокол TCP-стелс каналом (Reality/Naive/Mieru).
  ///
  /// AGENTS.md правило 9: у каждого узла должен быть живой TCP-канал.
  bool get isTcpFallback =>
      type == 'vless' || type == 'naive' || type == 'mieru';

  /// Маппинг на [ProtocolType] приложения.
  ///
  /// `null` — тип пока не поддерживается клиентом.
  ProtocolType? get protocolType {
    if (type == 'vless') {
      return hasReality ? ProtocolType.vlessReality : ProtocolType.vless;
    }
    return switch (type) {
      'hysteria2' => ProtocolType.hysteria2,
      'amneziawg' || 'amnezia-wg' => ProtocolType.amneziaWg,
      'naive' => ProtocolType.naive,
      'mieru' => ProtocolType.mieru,
      'shadowsocks' => ProtocolType.shadowsocks,
      'wireguard' => ProtocolType.wireguard,
      _ => null,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is NodeProtocol &&
      other.type == type &&
      other.port == port &&
      other.priority == priority;

  @override
  int get hashCode => Object.hash(type, port, priority);

  @override
  String toString() => 'NodeProtocol($type:$port, p$priority)';
}
