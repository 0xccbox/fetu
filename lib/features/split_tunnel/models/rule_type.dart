/// Тип правила раздельного туннелирования.
///
/// Каждый тип соответствует ключу route rule в конфигурации
/// sing-box, что позволяет транслировать правила в JSON 1:1.
library;

/// Тип сопоставления трафика правилом.
enum RuleType {
  /// Точное совпадение домена (`vk.com`).
  domain('domain'),

  /// Домен и все его поддомены (`vk.com` покрывает `m.vk.com`).
  domainSuffix('domain_suffix'),

  /// Подстрока в домене (`goo` покрывает `google.com`).
  domainKeyword('domain_keyword'),

  /// Регулярное выражение для домена (`^ads\d*\.`).
  domainRegex('domain_regex'),

  /// IP-адрес или CIDR; допускается список через запятую.
  ipCidr('ip_cidr', isMultiValue: true),

  /// Геолокация IP (`ru`, `cn`); допускается список через запятую.
  geoip('geoip', isMultiValue: true),

  /// Android-пакет приложения (`com.example.app`); список через запятую.
  app('package_name', isMultiValue: true);

  const RuleType(this.singBoxKey, {this.isMultiValue = false});

  /// Ключ правила в JSON route.rules конфигурации sing-box.
  final String singBoxKey;

  /// Допускает ли тип несколько значений в одном паттерне (через запятую).
  final bool isMultiValue;

  /// Сопоставляется ли тип по домену (для локального матчинга в Dart).
  bool get isDomainBased =>
      this == RuleType.domain ||
      this == RuleType.domainSuffix ||
      this == RuleType.domainKeyword ||
      this == RuleType.domainRegex;

  /// Разбирает тип из JSON-значения хранилища.
  ///
  /// Неизвестное значение трактуется как [RuleType.domainSuffix]
  /// (наиболее безопасный вариант по умолчанию).
  static RuleType fromName(String? name) => switch (name) {
        'domain' => RuleType.domain,
        'domain_suffix' => RuleType.domainSuffix,
        'domain_keyword' => RuleType.domainKeyword,
        'domain_regex' => RuleType.domainRegex,
        'ip_cidr' => RuleType.ipCidr,
        'geoip' => RuleType.geoip,
        'package_name' => RuleType.app,
        _ => RuleType.domainSuffix,
      };
}
