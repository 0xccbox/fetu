/// Сопоставление доменов для правил раздельного туннелирования.
///
/// Семантика совместима с sing-box:
/// - exact — полное совпадение;
/// - suffix — домен и все его поддомены (включая wildcard `*.`);
/// - keyword — подстрока в домене;
/// - regex — регулярное выражение на весь домен.
library;

import '../models/rule_type.dart';

/// Утилитарный матчер доменов (только статические методы).
class DomainMatcher {
  const DomainMatcher._();

  /// Приводит домен к каноническому виду:
  /// нижний регистр, без пробелов и точек по краям.
  static String normalize(String domain) {
    final trimmed = domain.trim().toLowerCase();
    return trimmed.replaceAll(RegExp(r'^\.+|\.+$'), '');
  }

  /// Точное совпадение домена с паттерном.
  static bool matchesExact(String domain, String pattern) {
    final d = normalize(domain);
    final p = normalize(pattern);
    return p.isNotEmpty && d == p;
  }

  /// Домен совпадает с паттерном или является его поддоменом.
  ///
  /// `vk.com` покрывает `vk.com` и `m.vk.com`.
  /// Паттерн вида `*.example.com` покрывает только поддомены.
  static bool matchesSuffix(String domain, String pattern) {
    final p = normalize(pattern);
    if (p.startsWith('*.')) return matchesWildcard(domain, p);
    final d = normalize(domain);
    return p.isNotEmpty && (d == p || d.endsWith('.$p'));
  }

  /// Wildcard-паттерн `*.example.com`: совпадает с поддоменами,
  /// но не с самим `example.com` (семантика sing-box).
  static bool matchesWildcard(String domain, String pattern) {
    final d = normalize(domain);
    final p = normalize(pattern);
    if (!p.startsWith('*.')) return matchesSuffix(d, p);
    final base = p.substring(2);
    return base.isNotEmpty && d != base && d.endsWith('.$base');
  }

  /// Подстрока в домене (без учёта регистра).
  static bool matchesKeyword(String domain, String keyword) {
    final d = normalize(domain);
    final k = normalize(keyword);
    return k.isNotEmpty && d.contains(k);
  }

  /// Регулярное выражение на весь домен.
  ///
  /// Регистрозависимо — как Go regexp в sing-box (домен при этом
  /// нормализован в нижний регистр, как приходит из DNS).
  /// Некорректный regex безопасно возвращает `false`.
  static bool matchesRegex(String domain, String pattern) {
    final d = normalize(domain);
    try {
      return RegExp(pattern).hasMatch(d);
    } on FormatException {
      return false;
    }
  }

  /// Подходит ли домен под правило указанного типа.
  ///
  /// Типы [RuleType.ipCidr], [RuleType.geoip] и [RuleType.app]
  /// всегда возвращают `false`: их runtime-матчинг выполняет
  /// сам sing-box, локальных данных для этого нет.
  static bool matches(String domain, RuleType type, String pattern) =>
      switch (type) {
        RuleType.domain => matchesExact(domain, pattern),
        RuleType.domainSuffix => matchesSuffix(domain, pattern),
        RuleType.domainKeyword => matchesKeyword(domain, pattern),
        RuleType.domainRegex => matchesRegex(domain, pattern),
        _ => false,
      };
}
