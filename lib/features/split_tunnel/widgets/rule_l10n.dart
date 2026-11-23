/// Локализованные названия типов и действий правил Split Tunneling.
///
/// UI-маппинг enum → строка из [AppLocalizations]
/// (AGENTS.md, правило 14: модели не хранят строки UI).
library;

import 'package:fetu/l10n/app_localizations.dart';

import '../models/rule_action.dart';
import '../models/rule_type.dart';

extension RuleTypeL10n on RuleType {
  /// Отображаемое название типа правила.
  String label(AppLocalizations l10n) => switch (this) {
        RuleType.domain => l10n.ruleTypeDomain,
        RuleType.domainSuffix => l10n.ruleTypeDomainSuffix,
        RuleType.domainKeyword => l10n.ruleTypeKeyword,
        RuleType.domainRegex => l10n.ruleTypeRegex,
        RuleType.ipCidr => l10n.ruleTypeCidr,
        RuleType.geoip => l10n.ruleTypeGeoip,
        RuleType.app => l10n.ruleTypeApp,
      };

  /// Подсказка-пример паттерна для поля ввода.
  String hint(AppLocalizations l10n) => switch (this) {
        RuleType.domain => l10n.ruleTypeDomainHint,
        RuleType.domainSuffix => l10n.ruleTypeDomainSuffixHint,
        RuleType.domainKeyword => l10n.ruleTypeKeywordHint,
        RuleType.domainRegex => l10n.ruleTypeRegexHint,
        RuleType.ipCidr => l10n.ruleTypeCidrHint,
        RuleType.geoip => l10n.ruleTypeGeoipHint,
        RuleType.app => l10n.ruleTypeAppHint,
      };
}

extension RuleActionL10n on RuleAction {
  /// Отображаемое название действия.
  String label(AppLocalizations l10n) => switch (this) {
        RuleAction.proxy => l10n.ruleActionProxy,
        RuleAction.direct => l10n.ruleActionDirect,
        RuleAction.block => l10n.ruleActionBlock,
      };
}

/// Локализованные названия/описания пресетов по их стабильному id.
extension PresetL10n on String {
  /// Название пресета.
  String presetTitle(AppLocalizations l10n) => switch (this) {
        'ru_direct' => l10n.presetRuDirectTitle,
        'blocked_proxy' => l10n.presetBlockedProxyTitle,
        'ads_block' => l10n.presetAdsBlockTitle,
        'social_proxy' => l10n.presetSocialProxyTitle,
        _ => this,
      };

  /// Описание пресета.
  String presetDescription(AppLocalizations l10n) => switch (this) {
        'ru_direct' => l10n.presetRuDirectDescription,
        'blocked_proxy' => l10n.presetBlockedProxyDescription,
        'ads_block' => l10n.presetAdsBlockDescription,
        'social_proxy' => l10n.presetSocialProxyDescription,
        _ => '',
      };
}
