/// Парсер JSON-подписок с валидацией и фоновым исполнением в Isolate.
///
/// Изоляция защищает UI-тред от тяжёлого jsonDecode больших подписок
/// (AGENTS.md, правило 23).
library;

import 'dart:convert';
import 'dart:isolate';

import '../../../core/constants/subscription_constants.dart';
import '../models/subscription.dart';
import 'subscription_signature.dart';
import 'uri_subscription_parser.dart';
import 'vpn_subscription_url.dart';

/// Классификация ошибки парсинга (для маппинга в UI-код).
enum SubscriptionParseErrorKind {
  /// Структурно некорректные данные.
  invalid,

  /// Устаревшая версия формата.
  outdatedVersion,

  /// Подписка истекла.
  expired,

  /// Нет доступных серверов.
  noNodes,

  /// У узла нет TCP-канала (правило 9).
  noTcpChannel,

  /// Подпись подписки невалидна.
  signature,

  /// Проблема с ключами (не заданы/некорректны).
  key,

  /// Некорректный vpn:// URL.
  url,
}

/// Исключение парсинга/валидации подписки.
class SubscriptionParseException implements Exception {
  /// Причина отказа (debug-текст, не для UI).
  final String message;

  /// Классификация для локализуемых сообщений UI.
  final SubscriptionParseErrorKind kind;

  const SubscriptionParseException(
    this.message, [
    this.kind = SubscriptionParseErrorKind.invalid,
  ]);

  @override
  String toString() => 'SubscriptionParseException: $message';
}

/// Парсер подписок контракта v2.
class SubscriptionParser {
  const SubscriptionParser();

  /// Парсит и валидирует JSON-подписку в фоновом Isolate.
  ///
  /// Returns: готовая [Subscription].
  /// Throws: [SubscriptionParseException] при некорректных данных.
  static Future<Subscription> parse(String rawJson) {
    return Isolate.run(() => _parseSync(rawJson));
  }

  /// Синхронный парсинг (выполняется внутри Isolate).
  static Subscription _parseSync(String rawJson) {
    final raw = rawJson.trim();
    if (raw.isEmpty) {
      throw const SubscriptionParseException('Пустая подписка');
    }

    if (!raw.startsWith('{') && !raw.startsWith('[')) {
      final uriSubscription = UriSubscriptionParser.tryParse(raw);
      if (uriSubscription != null) {
        return uriSubscription;
      }
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (e) {
      throw SubscriptionParseException('Некорректный JSON: ${e.message}');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const SubscriptionParseException('Ожидался JSON-объект');
    }

    final subscription = Subscription.fromJson(decoded);
    _validate(subscription);
    return subscription;
  }

  /// Валидация бизнес-инвариантов подписки.
  ///
  /// Правило 9 (AGENTS.md): у КАЖДОГО узла обязан быть TCP-канал
  /// (Reality/Naive/Mieru) — подписка только с UDP-рельсом отклоняется.
  static void _validate(Subscription subscription) {
    if (subscription.version < SubscriptionConstants.minFormatVersion) {
      throw SubscriptionParseException(
        'Устаревшая версия подписки '
        '(v${subscription.version} < v${SubscriptionConstants.minFormatVersion})',
        SubscriptionParseErrorKind.outdatedVersion,
      );
    }
    if (subscription.name.isEmpty) {
      throw const SubscriptionParseException('Подписка без названия');
    }
    if (subscription.isExpired) {
      throw const SubscriptionParseException(
        'Подписка истекла',
        SubscriptionParseErrorKind.expired,
      );
    }
    if (subscription.nodes.isEmpty) {
      throw const SubscriptionParseException(
        'Нет доступных серверов',
        SubscriptionParseErrorKind.noNodes,
      );
    }
    if (subscription.nodes.length >
        SubscriptionConstants.maxNodesPerSubscription) {
      throw SubscriptionParseException(
        'Слишком много узлов (${subscription.nodes.length} > '
        '${SubscriptionConstants.maxNodesPerSubscription})',
      );
    }

    for (final node in subscription.nodes) {
      if (node.protocols.isEmpty) {
        throw SubscriptionParseException(
          'Узел «${node.name}» не имеет протоколов',
        );
      }
      if (node.protocols.length > SubscriptionConstants.maxProtocolsPerNode) {
        throw SubscriptionParseException(
          'Слишком много протоколов у узла «${node.name}»',
        );
      }
      if (!node.hasTcpFallback) {
        throw SubscriptionParseException(
          'Узел «${node.name}» не имеет TCP-канала '
          '(Reality/Naive/Mieru) — правило 9',
          SubscriptionParseErrorKind.noTcpChannel,
        );
      }
    }

    final cascade = subscription.cascade;
    if (cascade != null && cascade.enabled) {
      if (cascade.relays.isEmpty) {
        throw const SubscriptionParseException(
          'Каскад включён, но список relays пуст',
        );
      }
      final seenRelayIds = <String>{};
      for (final relay in cascade.relays) {
        if (relay.id.isEmpty) {
          throw const SubscriptionParseException(
            'Каскадный relay без идентификатора',
          );
        }
        if (!seenRelayIds.add(relay.id)) {
          throw SubscriptionParseException(
            'Дублирующийся идентификатор каскада «${relay.id}»',
          );
        }
        if (relay.domains.isEmpty) {
          throw SubscriptionParseException(
            'Каскадный relay «${relay.id}» не имеет адресов',
          );
        }
        if (relay.protocols.isEmpty) {
          throw SubscriptionParseException(
            'Каскадный relay «${relay.id}» не имеет протоколов',
          );
        }
        if (!relay.protocols.any((p) => p.isTcpFallback)) {
          throw SubscriptionParseException(
            'Каскадный relay «${relay.id}» не имеет TCP-канала '
            '(Reality/Naive/Mieru) — правило 9',
            SubscriptionParseErrorKind.noTcpChannel,
          );
        }
      }
    }
  }

  /// Проверяет подпись и расшифровывает vpn://-подписку, затем парсит.
  ///
  /// [ed25519PublicKey] — 32 байта публичного ключа (приоритетно);
  /// [hmacKey] — симметричный HMAC-ключ; [aesKey] — 32 байта shared secret.
  ///
  /// Семантика подписей (по контракту ФОРМАТ_API_ПОДПИСОК.md):
  /// - Ed25519 подписывает **сырой ciphertext** (`data` без Base64);
  /// - HMAC-SHA256 подписывает base64-строку `data`.
  ///
  /// Throws: [SubscriptionParseException] при провале подписи,
  /// расшифровки или валидации.
  static Future<Subscription> parseVpnUrl(
    String vpnUrl, {
    List<int>? ed25519PublicKey,
    List<int>? hmacKey,
    List<int>? aesKey,
  }) async {
    final payload = VpnSubscriptionUrl.parse(vpnUrl);
    if (payload == null) {
      throw const SubscriptionParseException(
        'Некорректный vpn:// URL подписки',
        SubscriptionParseErrorKind.url,
      );
    }

    try {
      // Подпись проверяется ДО расшифровки (fail fast, защита от подмены).
      final signature = VpnSubscriptionUrl.decodeBase64(payload.sig);
      var signatureValid = false;

      if (ed25519PublicKey != null) {
        signatureValid = await SubscriptionSignatureVerifier.verifyEd25519(
          message: VpnSubscriptionUrl.decodeBase64(payload.data),
          signature: signature,
          publicKey: ed25519PublicKey,
        );
      } else if (hmacKey != null) {
        signatureValid = SubscriptionSignatureVerifier.verifyHmac(
          message: utf8.encode(payload.data),
          signature: signature,
          key: hmacKey,
        );
      } else {
        throw const SubscriptionParseException(
          'Не задан ключ проверки подписи',
          SubscriptionParseErrorKind.key,
        );
      }
      if (!signatureValid) {
        throw const SubscriptionParseException(
          'Подпись подписки невалидна',
          SubscriptionParseErrorKind.signature,
        );
      }

      if (aesKey == null) {
        throw const SubscriptionParseException(
          'Не задан ключ расшифровки',
          SubscriptionParseErrorKind.key,
        );
      }

      final rawJson = await VpnSubscriptionUrl.decryptData(
        dataBase64: payload.data,
        key: aesKey,
      );
      return parse(rawJson);
    } on SubscriptionParseException {
      rethrow;
    } on VpnSubscriptionUrlException catch (e) {
      // Ошибки Base64/расшифровки связаны с ключами, а не с данными.
      throw SubscriptionParseException(
        e.message,
        SubscriptionParseErrorKind.key,
      );
    }
  }
}
