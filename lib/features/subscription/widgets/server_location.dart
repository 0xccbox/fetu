import 'package:fetu/design_system/design_system.dart';
import 'package:fetu/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../models/subscription_node.dart';

/// Название узла с безопасным fallback на его идентификатор.
String serverDisplayName(SubscriptionNode node) =>
    node.name.isEmpty ? node.id : node.name;

/// Проверяет и нормализует двухбуквенный код страны.
String? normalizeCountryCode(String? country) {
  final code = country?.trim().toUpperCase();
  if (code == null || !RegExp(r'^[A-Z]{2}$').hasMatch(code)) return null;
  return code;
}

/// Квадратный бейдж с флагом страны или иконкой глобуса для карточки сервера.
class ServerFlagBadge extends StatelessWidget {
  /// Создаёт бейдж страны.
  const ServerFlagBadge({
    super.key,
    required this.country,
    this.highlighted = false,
  });

  /// Двухбуквенный код страны.
  final String? country;

  /// Выделять ли фон акцентом.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final code = normalizeCountryCode(country);
    final isWindows = theme.platform == TargetPlatform.windows;
    return ExcludeSemantics(
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: highlighted
              ? theme.colorScheme.primary.withOpacity(0.16)
              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.45),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: highlighted
                ? theme.colorScheme.primary.withOpacity(0.45)
                : theme.dividerColor,
          ),
        ),
        child: code == null || isWindows
            ? Icon(
                Icons.public_rounded,
                size: 20,
                color: highlighted
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  String.fromCharCodes(
                    code.codeUnits.map((unit) => 0x1F1E6 + unit - 65),
                  ),
                  maxLines: 1,
                  softWrap: false,
                  style: const TextStyle(fontSize: 20, height: 1),
                ),
              ),
      ),
    );
  }
}

/// Флаг и локация из подписки; неизвестные данные не подменяются.
class ServerLocation extends StatelessWidget {
  /// Создаёт строку локации, пригодную для узких карточек и крупного текста.
  const ServerLocation({
    super.key,
    this.country,
    this.city,
    this.showLeading = true,
  });

  /// Двухбуквенный код страны, если его передал провайдер.
  final String? country;

  /// Название города от провайдера.
  final String? city;

  /// Показывать ли флаг/иконку перед текстом локации.
  final bool showLeading;

  String? get _code => normalizeCountryCode(country);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final code = _code;
    final isWindows = theme.platform == TargetPlatform.windows;
    final location = switch (code) {
      'DE' => l10n.serverCountryGermany,
      'NL' => l10n.serverCountryNetherlands,
      'JP' => l10n.serverCountryJapan,
      'US' => l10n.serverCountryUS,
      'RU' => l10n.serverCountryRussia,
      'FR' => l10n.serverCountryFrance,
      'FI' => l10n.serverCountryFinland,
      'GB' => l10n.serverCountryUK,
      'KZ' => l10n.serverCountryKazakhstan,
      'SG' => l10n.serverCountrySingapore,
      _ => code,
    };
    final parts = [
      if (location != null) location,
      if (city?.trim().isNotEmpty ?? false) city!.trim(),
    ];
    final label = parts.isEmpty ? l10n.homeUnknownLocation : parts.join(' · ');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLeading) ...[
          ExcludeSemantics(
            child: code == null || isWindows
                ? Icon(
                    Icons.public_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  )
                : Text(
                    String.fromCharCodes(
                      code.codeUnits.map((unit) => 0x1F1E6 + unit - 65),
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelSmall
                .copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
