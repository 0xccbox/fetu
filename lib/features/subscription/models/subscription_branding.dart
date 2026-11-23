/// White-label брендинг провайдера (`branding` контракта v2).
library;

import 'package:meta/meta.dart';

/// Кастомная ссылка провайдера.
@immutable
class BrandLink {
  /// Создаёт ссылку.
  const BrandLink({required this.icon, required this.label, required this.url});

  /// Имя иконки (контрактное: `discord`, `telegram`...).
  final String icon;

  /// Отображаемая метка.
  final String label;

  /// URL.
  final String url;

  /// Восстанавливает ссылку из JSON.
  factory BrandLink.fromJson(Map<String, dynamic> json) => BrandLink(
        icon: json['icon'] as String? ?? 'link',
        label: json['label'] as String? ?? '',
        url: json['url'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'icon': icon,
        'label': label,
        'url': url,
      };
}

/// Брендинг провайдера: имя, лого, ссылки, юридические URL.
@immutable
class SubscriptionBranding {
  /// Создаёт блок брендинга.
  const SubscriptionBranding({
    this.appName,
    this.companyName,
    this.logoUrl,
    this.logoDarkUrl,
    this.colors = const <String, String>{},
    this.telegramUrl,
    this.websiteUrl,
    this.supportUrl,
    this.buyUrl,
    this.customLinks = const <BrandLink>[],
    this.termsUrl,
    this.privacyUrl,
    this.smartSelectionEnabled,
    this.smartSelectionUrl,
  });

  /// Название приложения провайдера.
  final String? appName;

  /// Название компании.
  final String? companyName;

  /// Лого (светлое).
  final String? logoUrl;

  /// Лого (тёмное).
  final String? logoDarkUrl;

  /// Брендовые цвета (ключ → hex).
  final Map<String, String> colors;

  /// Ссылка Telegram.
  final String? telegramUrl;

  /// Сайт.
  final String? websiteUrl;

  /// Поддержка.
  final String? supportUrl;

  /// Покупка/продление.
  final String? buyUrl;

  /// Кастомные ссылки.
  final List<BrandLink> customLinks;

  /// Условия использования.
  final String? termsUrl;

  /// Политика конфиденциальности.
  final String? privacyUrl;

  /// Включена ли кнопка умного выбора сервера (`branding.features.smart_selection`).
  final bool? smartSelectionEnabled;

  /// Опциональный endpoint умного выбора от провайдера.
  final String? smartSelectionUrl;

  /// Восстанавливает брендинг из JSON.
  factory SubscriptionBranding.fromJson(Map<String, dynamic> json) {
    final logo = json['logo'] is Map<String, dynamic>
        ? json['logo'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final links = json['links'] is Map<String, dynamic>
        ? json['links'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final rawColors = json['colors'];
    final support = json['support'] is Map<String, dynamic>
        ? json['support'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final features = json['features'] is Map<String, dynamic>
        ? json['features'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return SubscriptionBranding(
      appName: json['app_name'] as String?,
      companyName: json['company_name'] as String?,
      logoUrl: logo['url'] as String?,
      logoDarkUrl: logo['dark_url'] as String?,
      colors: _safeColors(rawColors),
      telegramUrl:
          links['telegram'] as String? ?? support['telegram'] as String?,
      websiteUrl: links['website'] as String?,
      supportUrl: links['support'] as String? ?? support['url'] as String?,
      buyUrl: links['buy'] as String?,
      customLinks: List.unmodifiable([
        for (final entry in (links['custom'] as List? ?? const []))
          if (entry is Map<String, dynamic>) BrandLink.fromJson(entry),
      ]),
      termsUrl: json['terms_url'] as String?,
      privacyUrl: json['privacy_url'] as String?,
      smartSelectionEnabled: features['smart_selection'] as bool?,
      smartSelectionUrl: features['smart_selection_url'] as String?,
    );
  }

  /// Типобезопасно извлекает цвета брендинга (битые значения пропускаются).
  static Map<String, String> _safeColors(Object? raw) {
    if (raw is! Map) return const <String, String>{};
    return Map.unmodifiable({
      for (final entry in raw.entries)
        if (entry.key is String && entry.value is String)
          entry.key as String: entry.value as String,
    });
  }

  /// Первая непустая ссылка для шапки.
  String? get primaryLinkUrl =>
      telegramUrl ?? websiteUrl ?? supportUrl ?? buyUrl;

  Map<String, dynamic> toJson() => {
        if (appName != null) 'app_name': appName,
        if (companyName != null) 'company_name': companyName,
        'logo': {
          if (logoUrl != null) 'url': logoUrl,
          if (logoDarkUrl != null) 'dark_url': logoDarkUrl,
        },
        'colors': colors,
        'links': {
          if (telegramUrl != null) 'telegram': telegramUrl,
          if (websiteUrl != null) 'website': websiteUrl,
          if (supportUrl != null) 'support': supportUrl,
          if (buyUrl != null) 'buy': buyUrl,
          'custom': [for (final link in customLinks) link.toJson()],
        },
        if (termsUrl != null) 'terms_url': termsUrl,
        if (privacyUrl != null) 'privacy_url': privacyUrl,
        if (smartSelectionEnabled != null || smartSelectionUrl != null)
          'features': {
            if (smartSelectionEnabled != null)
              'smart_selection': smartSelectionEnabled,
            if (smartSelectionUrl != null)
              'smart_selection_url': smartSelectionUrl,
          },
      };
}
