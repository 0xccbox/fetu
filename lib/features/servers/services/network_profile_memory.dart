/// Память лучших протоколов и каскадов для разных сетевых профилей
/// (Wi-Fi BSSID / мобильный оператор MCC-MNC).
///
/// Предотвращает повторный перебор заведомо заблокированных в данной сети
/// протоколов при смене Wi-Fi ↔ LTE.
library;

import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';

import '../../../core/constants/server_constants.dart';
import '../../../core/storage/key_value_storage.dart';
import '../../connection/models/server_node.dart';

/// Инъектируемый провайдер отпечатка текущей сети (для тестов).
typedef NetworkFingerprintProvider = Future<String> Function();

/// Сохранённый профиль предпочтительного протокола для конкретной сети.
@immutable
class NetworkProfilePreference {
  /// Создаёт запись предпочтения.
  const NetworkProfilePreference({
    required this.fingerprint,
    required this.protocol,
    this.relayId,
    required this.updatedAt,
  });

  /// Хешированный отпечаток сети (`wifi:<sha256>` / `cell:<mcc_mnc>` / `default`).
  final String fingerprint;

  /// Протокол, стабильно работавший в этой сети.
  final ProtocolType protocol;

  /// Входной каскадный релей (если использовался).
  final String? relayId;

  /// Время последнего подтверждения.
  final DateTime updatedAt;

  /// Восстанавливает запись из JSON.
  factory NetworkProfilePreference.fromJson(Map<String, dynamic> json) =>
      NetworkProfilePreference(
        fingerprint: json['fingerprint'] as String? ?? 'default',
        protocol: ProtocolType.values.firstWhere(
          (p) => p.name == json['protocol'],
          orElse: () => ProtocolType.vlessReality,
        ),
        relayId: json['relay_id'] as String?,
        updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );

  /// Сериализует запись в JSON.
  Map<String, dynamic> toJson() => {
        'fingerprint': fingerprint,
        'protocol': protocol.name,
        if (relayId != null) 'relay_id': relayId,
        'updated_at': updatedAt.toIso8601String(),
      };
}

/// Сервис памяти сетевых профилей.
class NetworkProfileMemory {
  /// Создаёт сервис памяти сети.
  NetworkProfileMemory({
    KeyValueStorage? storage,
    NetworkFingerprintProvider? fingerprintProvider,
  })  : _storage = storage,
        _fingerprintProvider =
            fingerprintProvider ?? _defaultFingerprintProvider;

  final KeyValueStorage? _storage;
  final NetworkFingerprintProvider _fingerprintProvider;

  final Map<String, NetworkProfilePreference> _cache =
      <String, NetworkProfilePreference>{};
  bool _loaded = false;

  /// Загружает сохранённые профили из хранилища.
  Future<void> initialize() async {
    if (_loaded) return;
    _loaded = true;
    final storage = _storage;
    if (storage == null) return;
    try {
      final raw = await storage.read(
        key: ServerConstants.networkMemoryStorageKey,
      );
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      for (final entry in decoded.entries) {
        if (entry.value is Map<String, dynamic>) {
          _cache[entry.key] = NetworkProfilePreference.fromJson(
            entry.value as Map<String, dynamic>,
          );
        }
      }
    } catch (_) {
      // Повреждённый кэш не блокирует работу.
    }
  }

  /// Возвращает обезличенный отпечаток текущей сети (`wifi:<sha256>` / `cell` / `default`).
  Future<String> currentFingerprint() async {
    try {
      return await _fingerprintProvider();
    } catch (_) {
      return 'default';
    }
  }

  /// Возвращает запомненный лучший протокол для текущей сети (или для [fingerprint]).
  Future<NetworkProfilePreference?> getPreferred({String? fingerprint}) async {
    await initialize();
    final fp = fingerprint ?? await currentFingerprint();
    return _cache[fp];
  }

  /// Фиксирует успешную работу [protocol] (и опционально [relayId]) в текущей сети.
  Future<void> recordSuccess({
    required ProtocolType protocol,
    String? relayId,
    String? fingerprint,
  }) async {
    await initialize();
    final fp = fingerprint ?? await currentFingerprint();
    _cache[fp] = NetworkProfilePreference(
      fingerprint: fp,
      protocol: protocol,
      relayId: relayId,
      updatedAt: DateTime.now(),
    );
    await _persist();
  }

  Future<void> _persist() async {
    final storage = _storage;
    if (storage == null) return;
    try {
      final encoded = jsonEncode({
        for (final entry in _cache.entries) entry.key: entry.value.toJson(),
      });
      await storage.write(
        key: ServerConstants.networkMemoryStorageKey,
        value: encoded,
      );
    } catch (_) {}
  }

  static Future<String> _defaultFingerprintProvider() async {
    try {
      final results = await Connectivity().checkConnectivity();
      if (results.contains(ConnectivityResult.wifi)) {
        final bssid = await NetworkInfo().getWifiBSSID();
        if (bssid != null && bssid.isNotEmpty) {
          final hash = sha256.convert(utf8.encode(bssid)).toString();
          return 'wifi:${hash.substring(0, 16)}';
        }
        return 'wifi:generic';
      }
      if (results.contains(ConnectivityResult.mobile)) {
        return 'cell:mobile';
      }
      if (results.contains(ConnectivityResult.ethernet)) {
        return 'eth:wired';
      }
    } catch (_) {}
    return 'default';
  }
}
