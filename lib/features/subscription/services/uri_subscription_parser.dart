/// Парсер стандартных подписок (Base64 / построчный список URI).
///
/// Поддерживает ссылки `hysteria2://` (`hy2://`), `vless://`, `ss://`,
/// преобразуя их в модель [Subscription] контракта приложения.
library;

import 'dart:convert';

import '../../../core/constants/subscription_constants.dart';
import '../models/node_domain_entry.dart';
import '../models/node_protocol.dart';
import '../models/subscription.dart';
import '../models/subscription_node.dart';
import 'vpn_subscription_url.dart';

/// Разбирает стандартные URI-подписки (plain text или Base64).
class UriSubscriptionParser {
  const UriSubscriptionParser._();

  static const Set<String> _supportedSchemes = {
    'hysteria2',
    'hy2',
    'vless',
    'ss',
  };

  /// Пробует распарсить [raw] как список VPN-ссылок (или Base64 от него).
  ///
  /// Returns: [Subscription] если найден хотя бы один валидный узел;
  /// `null` если строка не является URI-подпиской.
  static Subscription? tryParse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final decodedText = _containsUriScheme(trimmed)
        ? trimmed
        : (_tryDecodeBase64Text(trimmed) ?? trimmed);
    if (!_containsUriScheme(decodedText)) return null;

    final lines = decodedText
        .split(RegExp(r'\r?\n'))
        .map(VpnSubscriptionUrl.sanitizeUrl)
        .where((line) => line.isNotEmpty && !line.startsWith('#'));

    final nodes = <SubscriptionNode>[];
    var index = 1;
    for (final line in lines) {
      if (nodes.length >= SubscriptionConstants.maxNodesPerSubscription) {
        break;
      }
      final node = _parseLine(line, index);
      if (node != null) {
        nodes.add(node);
        index++;
      }
    }
    if (nodes.isEmpty) return null;

    return Subscription(
      version: 2,
      name: 'Fetu Subscription',
      nodes: List.unmodifiable(nodes),
    );
  }

  static bool _containsUriScheme(String value) {
    final lower = value.toLowerCase();
    return _supportedSchemes.any((scheme) => lower.contains('$scheme://'));
  }

  static String? _tryDecodeBase64Text(String value) {
    final compact = value.replaceAll(RegExp(r'\s+'), '');
    if (compact.length < 8) return null;
    try {
      final bytes = VpnSubscriptionUrl.decodeBase64(compact);
      return utf8.decode(bytes, allowMalformed: false);
    } catch (_) {
      return null;
    }
  }

  static SubscriptionNode? _parseLine(String line, int index) {
    final lower = line.toLowerCase();
    if (lower.startsWith('hysteria2://') || lower.startsWith('hy2://')) {
      return _parseHysteria2(line, index);
    }
    if (lower.startsWith('vless://')) {
      return _parseVless(line, index);
    }
    if (lower.startsWith('ss://')) {
      return _parseShadowsocks(line, index);
    }
    return null;
  }

  static SubscriptionNode? _parseHysteria2(String line, int index) {
    final uri = Uri.tryParse(line);
    if (uri == null || uri.host.isEmpty) return null;

    final params = uri.queryParameters;
    final port = uri.hasPort && uri.port > 0 ? uri.port : 443;
    final password = _safeDecode(uri.userInfo);
    if (password.isEmpty) return null;
    final host = _normalizeHost(uri.host);
    if (host.isEmpty) return null;

    final sni = params['sni'] ?? params['peer'];
    final insecure = params['insecure'] == '1' ||
        params['insecure']?.toLowerCase() == 'true';
    final obfsType = params['obfs']?.trim().toLowerCase();
    final obfsPassword = params['obfs-password'] ?? '';
    final upMbps = int.tryParse(params['upmbps'] ?? params['up'] ?? '');
    final downMbps = int.tryParse(params['downmbps'] ?? params['down'] ?? '');

    final name = _extractName(uri, fallback: '$host:$port');
    return SubscriptionNode(
      id: 'hy2-$index',
      name: name,
      country: _extractCountryCode(name),
      domains: [
        NodeDomainEntry(
          address: host,
          priority: 1,
          type: _domainEntryType(host),
        ),
      ],
      protocols: [
        NodeProtocol(
          type: 'hysteria2',
          port: port,
          priority: 1,
          credentials: {
            'password': password,
            if (sni != null && sni.isNotEmpty) 'tls_sni': sni,
            if (insecure) 'tls_insecure': true,
            if (upMbps != null) 'up_mbps': upMbps,
            if (downMbps != null) 'down_mbps': downMbps,
          },
          obfuscation: obfsType == 'salamander'
              ? {'type': 'salamander', 'password': obfsPassword}
              : const <String, dynamic>{},
        ),
      ],
    );
  }

  static SubscriptionNode? _parseVless(String line, int index) {
    final uri = Uri.tryParse(line);
    if (uri == null || uri.host.isEmpty) return null;

    final params = uri.queryParameters;
    final port = uri.hasPort && uri.port > 0 ? uri.port : 443;
    final uuid = _safeDecode(uri.userInfo);
    if (uuid.isEmpty) return null;
    final host = _normalizeHost(uri.host);
    if (host.isEmpty) return null;

    final security = (params['security'] ?? '').trim().toLowerCase();
    final sni = params['sni'];
    final pbk = params['pbk'];
    final sid = params['sid'];
    final fp = params['fp'];
    final flow = params['flow'];
    final transport = params['type'];
    final path = params['path'];
    final hostHeader = params['host'];
    final serviceName = params['serviceName'];
    final insecure = params['insecure'] == '1' ||
        params['insecure']?.toLowerCase() == 'true' ||
        params['allowInsecure'] == '1';

    final name = _extractName(uri, fallback: '$host:$port');
    return SubscriptionNode(
      id: 'vless-$index',
      name: name,
      country: _extractCountryCode(name),
      domains: [
        NodeDomainEntry(
          address: host,
          priority: 1,
          type: _domainEntryType(host),
        ),
      ],
      protocols: [
        NodeProtocol(
          type: 'vless',
          port: port,
          priority: 1,
          credentials: {
            'uuid': uuid,
            if (flow != null && flow.isNotEmpty) 'flow': flow,
            if (transport != null && transport.isNotEmpty)
              'transport': transport,
            if (path != null && path.isNotEmpty) 'path': path,
            if (hostHeader != null && hostHeader.isNotEmpty) 'host': hostHeader,
            if (serviceName != null && serviceName.isNotEmpty)
              'service_name': serviceName,
            if (sni != null && sni.isNotEmpty) 'tls_sni': sni,
            if (insecure) 'tls_insecure': true,
          },
          reality: security == 'reality' && pbk != null && pbk.isNotEmpty
              ? {
                  'public_key': pbk,
                  if (sid != null && sid.isNotEmpty) 'short_id': sid,
                  if (sni != null && sni.isNotEmpty) 'server_name': sni,
                }
              : const <String, dynamic>{},
          obfuscation: fp != null && fp.isNotEmpty
              ? const {'randomize_tls_fingerprint': true}
              : const <String, dynamic>{},
        ),
      ],
    );
  }

  static SubscriptionNode? _parseShadowsocks(String line, int index) {
    final hashIdx = line.indexOf('#');
    final rawFragment = hashIdx >= 0 ? line.substring(hashIdx + 1) : '';
    final withoutFragment = hashIdx >= 0 ? line.substring(0, hashIdx) : line;
    final body = withoutFragment.substring('ss://'.length);
    final queryIdx = body.indexOf('?');
    final mainPart = queryIdx >= 0 ? body.substring(0, queryIdx) : body;

    String? method;
    String? password;
    String? host;
    int? port;

    if (mainPart.contains('@')) {
      final atIdx = mainPart.lastIndexOf('@');
      final userPart = mainPart.substring(0, atIdx);
      final hostPort = mainPart.substring(atIdx + 1);
      final parsedHostPort = _splitHostPort(hostPort);
      if (parsedHostPort == null) return null;
      host = parsedHostPort.$1;
      port = parsedHostPort.$2;

      final decodedUser = userPart.contains(':')
          ? _safeDecode(userPart)
          : _tryDecodeBase64Text(userPart);
      if (decodedUser == null || !decodedUser.contains(':')) return null;
      final colonIdx = decodedUser.indexOf(':');
      method = decodedUser.substring(0, colonIdx);
      password = decodedUser.substring(colonIdx + 1);
    } else {
      final decoded = _tryDecodeBase64Text(mainPart);
      if (decoded == null || !decoded.contains('@')) return null;
      final atIdx = decoded.lastIndexOf('@');
      final userPart = decoded.substring(0, atIdx);
      final hostPort = decoded.substring(atIdx + 1);
      final parsedHostPort = _splitHostPort(hostPort);
      if (parsedHostPort == null || !userPart.contains(':')) return null;
      host = parsedHostPort.$1;
      port = parsedHostPort.$2;
      final colonIdx = userPart.indexOf(':');
      method = userPart.substring(0, colonIdx);
      password = userPart.substring(colonIdx + 1);
    }

    if (method.isEmpty || password.isEmpty || host.isEmpty || port <= 0) {
      return null;
    }

    final name = rawFragment.isNotEmpty
        ? _safeDecode(rawFragment).trim()
        : '$host:$port';
    return SubscriptionNode(
      id: 'ss-$index',
      name: name.isEmpty ? '$host:$port' : name,
      country: _extractCountryCode(name),
      domains: [
        NodeDomainEntry(
          address: host,
          priority: 1,
          type: _domainEntryType(host),
        ),
      ],
      protocols: [
        NodeProtocol(
          type: 'shadowsocks',
          port: port,
          priority: 1,
          credentials: {
            'method': method,
            'password': password,
          },
        ),
      ],
    );
  }

  static (String, int)? _splitHostPort(String value) {
    final uri = Uri.tryParse('ss://$value');
    if (uri == null || uri.host.isEmpty || !uri.hasPort || uri.port <= 0) {
      return null;
    }
    final host = _normalizeHost(uri.host);
    if (host.isEmpty) return null;
    return (host, uri.port);
  }

  static String _normalizeHost(String host) {
    final trimmed = host.trim();
    if (trimmed.startsWith('[') &&
        trimmed.endsWith(']') &&
        trimmed.length > 2) {
      return trimmed.substring(1, trimmed.length - 1);
    }
    return trimmed;
  }

  static String _safeDecode(String value) {
    try {
      return Uri.decodeComponent(value);
    } catch (_) {
      return value;
    }
  }

  static String _extractName(Uri uri, {required String fallback}) {
    if (!uri.hasFragment || uri.fragment.isEmpty) return fallback;
    try {
      final decoded = Uri.decodeComponent(uri.fragment).trim();
      return decoded.isEmpty ? fallback : decoded;
    } catch (_) {
      return uri.fragment.trim().isEmpty ? fallback : uri.fragment.trim();
    }
  }

  static String? _extractCountryCode(String name) {
    final runes = name.runes.toList();
    for (var i = 0; i + 1 < runes.length; i++) {
      final first = runes[i];
      final second = runes[i + 1];
      if (_isRegionalIndicator(first) && _isRegionalIndicator(second)) {
        final a = String.fromCharCode(0x41 + (first - 0x1F1E6));
        final b = String.fromCharCode(0x41 + (second - 0x1F1E6));
        return '$a$b';
      }
    }
    return null;
  }

  static bool _isRegionalIndicator(int rune) =>
      rune >= 0x1F1E6 && rune <= 0x1F1FF;

  static NodeDomainType _domainEntryType(String host) {
    final isIpv4 = RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(host);
    final isIpv6 = host.contains(':');
    return (isIpv4 || isIpv6) ? NodeDomainType.ip : NodeDomainType.domain;
  }
}
