import 'dart:convert';

/// Фикстуры JSON-подписок контракта v2 для тестов ФАЗЫ 9.
///
/// См. `docs/reference/ФОРМАТ_API_ПОДПИСОК.md`.

/// Узел с HY2 + VLESS Reality (есть TCP-канал — правило 9 соблюдено).
Map<String, dynamic> validNode({String id = 'nl-1'}) => {
      'id': id,
      'name': '🇳🇱 Netherlands #1',
      'country': 'NL',
      'city': 'Amsterdam',
      'domains': [
        {
          'address': 'nl1.vpn.com',
          'priority': 1,
          'type': 'domain',
          'status': 'active',
        },
        {
          'address': 'nl1-backup.vpn.net',
          'priority': 2,
          'type': 'domain',
          'status': 'backup',
        },
        {
          'address': '45.67.89.123',
          'priority': 3,
          'type': 'ip',
          'status': 'fallback',
        },
      ],
      'protocols': [
        {
          'type': 'hysteria2',
          'port': 443,
          'password': 'hy2-pass',
          'priority': 1,
          'obfuscation': {
            'type': 'salamander',
            'password': 'obfs-secret',
            'enabled': true,
          },
        },
        {
          'type': 'vless',
          'port': 443,
          'uuid': '550e8400-e29b-41d4-a716-446655440000',
          'flow': 'xtls-rprx-vision',
          'priority': 2,
          'reality': {
            'public_key': 'SgVu5PublicKey',
            'short_id': '6ba85179e30d4fc2',
            'server_name': 'www.microsoft.com',
          },
        },
        {
          'type': 'naive',
          'port': 8443,
          'username': 'user123',
          'password': 'naive-pass',
          'priority': 3,
        },
      ],
      'badges': ['streaming', 'gaming'],
    };

/// Узел ТОЛЬКО с UDP (нет TCP-канала) — для негативного теста правила 9.
Map<String, dynamic> udpOnlyNode({String id = 'udp-only'}) => {
      'id': id,
      'name': 'UDP only',
      'protocols': [
        {'type': 'hysteria2', 'port': 443, 'password': 'pw', 'priority': 1},
      ],
    };

/// Минимальная валидная подписка.
Map<String, dynamic> minimalSubscription({
  int version = 2,
  String expireAt = '2030-01-01T00:00:00Z',
  List<Map<String, dynamic>>? nodes,
}) =>
    {
      'version': version,
      'name': 'Test VPN',
      'description': 'Test subscription',
      'expire_at': expireAt,
      'nodes': nodes ?? [validNode()],
    };

/// Полная подписка со всеми блоками кабинета (по примеру из контракта).
Map<String, dynamic> fullSubscription() => {
      ...minimalSubscription(),
      'update': {
        'url': 'https://api.test-vpn.com/sub/user123',
        'interval': 3600,
        'signature_public_key': 'MCowBQYDK2VwAyEA',
      },
      'features': {
        'split_tunnel': {
          'enabled': true,
          'default_action': 'proxy',
          'rules': [
            {
              'name': 'Российские сайты',
              'type': 'domain_suffix',
              'patterns': ['.ru', '.рф'],
              'action': 'direct',
            },
            {
              'name': 'Локальные IP',
              'type': 'geoip',
              'patterns': ['private'],
              'action': 'direct',
            },
            {
              'name': 'Соцсети',
              'type': 'domain_keyword',
              'patterns': ['twitter', 'facebook'],
              'action': 'proxy',
            },
            {
              'name': 'Банки',
              'type': 'process',
              'patterns': ['com.sberbank.android'],
              'action': 'direct',
            },
          ],
        },
      },
      'branding': {
        'app_name': 'Test VPN Pro',
        'company_name': 'Test VPN Inc.',
        'logo': {
          'url': 'https://cdn.test-vpn.com/logo.png',
          'dark_url': 'https://cdn.test-vpn.com/logo-dark.png',
        },
        'colors': {'primary': '#0F172A', 'accent': '#38BDF8'},
        'links': {
          'telegram': 'https://t.me/test_vpn',
          'website': 'https://test-vpn.com',
          'buy': 'https://test-vpn.com/buy',
        },
        'terms_url': 'https://test-vpn.com/terms',
      },
      'account': {
        'plan_name': 'Pro Unlimited',
        'status': 'active',
        'expire_at': '2030-12-31T23:59:59Z',
        'traffic': {
          'used_bytes': 48318382080,
          'limit_bytes': 1073741824000,
          'reset_at': '2030-12-01T00:00:00Z',
        },
        'devices': {
          'current_count': 2,
          'max_limit': 5,
          'manage_url': 'https://test-vpn.com/devices',
        },
        'billing': {
          'balance_formatted': '450 ₽',
          'auto_renew': true,
          'renew_url': 'https://test-vpn.com/pay',
        },
      },
      'announcements': [
        {
          'id': 'maint-2026-11',
          'type': 'info',
          'title': 'Новые серверы в Финляндии',
          'message': 'Подключитесь к Helsinki-02.',
          'action_label': 'Подробнее',
          'dismissible': true,
        },
        {
          'id': 'expired-old',
          'type': 'info',
          'title': 'Старое объявление',
          'expires_at': '2020-01-01T00:00:00Z',
        },
      ],
      'node_badges_catalog': {
        'streaming': {'label': '4K Видео', 'icon': 'tv'},
        'gaming': {'label': 'Для игр', 'icon': 'gamepad'},
      },
      'provider_custom_cards': [
        {
          'id': 'referral',
          'title': 'Пригласи друга',
          'subtitle': 'Бонусный код: FRIEND123',
          'copy_value': 'FRIEND123',
          'action_url': 'https://t.me/test_bot',
        },
      ],
      'developer_meta': {
        'config_generated_ms': 14,
        'backend_node': 'api-eu-west-2',
        'ab_test_group': 'xhttp_reality_v2',
        'recommended_ui_mode': 'auto',
      },
    };

/// Кодирует фикстуру в JSON-строку.
String asJson(Map<String, dynamic> fixture) => jsonEncode(fixture);
