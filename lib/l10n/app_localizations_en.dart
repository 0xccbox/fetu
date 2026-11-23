import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get statusDisconnected => 'Disconnected';

  @override
  String get statusConnecting => 'Connecting';

  @override
  String get statusConnected => 'Connected';

  @override
  String get statusDisconnecting => 'Disconnecting';

  @override
  String get statusError => 'Error';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSave => 'Save';

  @override
  String get actionApply => 'Apply';

  @override
  String get actionRefresh => 'Refresh';

  @override
  String get homeTooltipSubscription => 'Subscription';

  @override
  String get homeTooltipSplitTunnel => 'Split tunneling';

  @override
  String get homeTooltipSettings => 'Settings';

  @override
  String get homeTooltipToggleTheme => 'Toggle theme';

  @override
  String get homeAppName => 'Fetu';

  @override
  String get homeMenu => 'Menu';

  @override
  String get homeStartTitle => 'Set up connection';

  @override
  String get homeStartHint =>
      'Add a link from your provider to get your server list.';

  @override
  String get homeNoServerSelected => 'No server selected';

  @override
  String get homeUnknownLocation => 'Location not provided';

  @override
  String get homeLoadingSubscription => 'Loading subscription…';

  @override
  String get homeServersAfterImport =>
      'Servers will appear after you add a subscription.';

  @override
  String get homeRenewHint =>
      'Renew your subscription with your provider or add a new one.';

  @override
  String get homeRestoreFailed => 'Could not read the saved subscription';

  @override
  String get homeRestoreHint =>
      'Secure storage is unavailable. Try loading it again.';

  @override
  String get homeRetry => 'Retry';

  @override
  String get homeUseForSession => 'Add for this session';

  @override
  String get homeSessionOnly =>
      'This subscription won\'t be saved after restart.';

  @override
  String get homeDisconnectToChooseServer =>
      'Disconnect to choose another server.';

  @override
  String get homeProviderTelegram => 'Telegram';

  @override
  String get homeProviderWebsite => 'Website';

  @override
  String get homeProviderSupport => 'Support';

  @override
  String get homeProviderLink => 'Link';

  @override
  String get homeMoreLinks => 'More links';

  @override
  String get homeLinkFailed => 'Could not open the link';

  @override
  String get homeDownload => 'Download';

  @override
  String get serverCountryGermany => 'Germany';

  @override
  String get serverCountryNetherlands => 'Netherlands';

  @override
  String get serverCountryJapan => 'Japan';

  @override
  String get serverCountryUS => 'United States';

  @override
  String get serverCountryRussia => 'Russia';

  @override
  String get serverCountryFrance => 'France';

  @override
  String get serverCountryFinland => 'Finland';

  @override
  String get serverCountryUK => 'United Kingdom';

  @override
  String get serverCountryKazakhstan => 'Kazakhstan';

  @override
  String get serverCountrySingapore => 'Singapore';

  @override
  String homeProtectionMode(String mode) {
    return 'Protection mode: $mode';
  }

  @override
  String get modeSelectionTitle => 'Choose a mode';

  @override
  String get modeSelectionSubtitle => 'How do you prefer to use the app?';

  @override
  String get modeSimpleTitle => 'Simple mode';

  @override
  String get modeSimpleDescription =>
      'Smart access, maximum stealth and dual route protection are enabled automatically. Network terms are translated into plain language.';

  @override
  String get modeAdvancedTitle => 'Advanced mode';

  @override
  String get modeAdvancedDescription =>
      'Full telemetry: protocols, Real-Delay 204, .srs rule-set statuses and provider developer_meta.';

  @override
  String get modeSelectionHint =>
      'You can change the mode in Settings at any time.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionInterface => 'Interface';

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get themeModeSystem => 'System';

  @override
  String get settingsSectionSubscriptionKeys => 'Subscription keys (vpn://)';

  @override
  String get settingsKeysHint =>
      'Base64 keys from your provider: the Ed25519 public key and the AES-256 key. If your provider uses HMAC, prefix the verification secret with hmac:.';

  @override
  String get settingsKeyVerifyLabel => 'Signature verification key';

  @override
  String get settingsKeyDecryptLabel => 'Decryption key';

  @override
  String get settingsKeysSave => 'Save keys';

  @override
  String get settingsKeysClear => 'Clear keys';

  @override
  String get settingsKeysSaved => 'Keys saved';

  @override
  String get settingsKeysCleared => 'Keys removed';

  @override
  String get settingsKeysInvalid =>
      'Check the keys: valid Base64 strings are expected (32 bytes)';

  @override
  String get settingsSectionAdvanced => 'For pros';

  @override
  String get settingsDiagnosticsTitle => 'Diagnostics';

  @override
  String get settingsDiagnosticsSubtitle =>
      'Real-Delay, tunnel telemetry, diagnostic report';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get uxTermSmartAccess => 'Smart access';

  @override
  String get uxTermMaxStealth => 'Maximum stealth';

  @override
  String get uxTermClassicProtection => 'Classic protection';

  @override
  String get uxTermCascade => 'Dual route protection';

  @override
  String get uiModeSimpleLabel => 'simple';

  @override
  String get uiModeAdvancedLabel => 'advanced';

  @override
  String get failoverTitle => 'Protocol switch';

  @override
  String get failoverReasonTimeoutSimple =>
      'The channel stopped responding — switched to a backup';

  @override
  String failoverReasonTimeoutAdvanced(String protocol) {
    return '$protocol connection timeout';
  }

  @override
  String get failoverReasonPacketLossSimple =>
      'The connection became unstable — switched to a backup channel';

  @override
  String failoverReasonPacketLossAdvanced(String protocol) {
    return 'Packet loss on $protocol';
  }

  @override
  String get failoverReasonBlockedSimple =>
      'The channel was blocked — switched to stealth';

  @override
  String failoverReasonBlockedAdvanced(String protocol) {
    return '$protocol is blocked';
  }

  @override
  String get failoverReasonHandshakeSimple =>
      'The channel could not be established — trying another';

  @override
  String failoverReasonHandshakeAdvanced(String protocol) {
    return '$protocol handshake failed';
  }

  @override
  String get failoverReasonManual => 'Manual switch';

  @override
  String failoverSwitchedTo(String protocol) {
    return 'Switching to $protocol…';
  }

  @override
  String get connectionErrorNodeMissing => 'No server selected for connection';

  @override
  String get connectionErrorConnectFailed => 'Could not connect';

  @override
  String get connectionErrorCoreUnavailable =>
      'This build does not include the network engine';

  @override
  String get homeDisconnect => 'Disconnect';

  @override
  String get homeSelectServer => 'Select a server';

  @override
  String get homeChooseServerHint => 'Choose a server from the list below';

  @override
  String get homeSelectedServer => 'Selected';

  @override
  String get smartSelectionTitle => 'SMART SERVER SELECTION';

  @override
  String get smartSelectionSubtitle => 'Automatically pick the best server';

  @override
  String get connectionErrorDisconnectFailed => 'Could not disconnect';

  @override
  String get metricTime => 'Time';

  @override
  String get metricPing => 'Ping';

  @override
  String get metricTraffic => 'Traffic';

  @override
  String serverHealthScoreValue(int score) {
    return 'Score $score';
  }

  @override
  String get splitTitle => 'Split tunneling';

  @override
  String get splitTooltipAddRule => 'Add rule';

  @override
  String get splitSectionPresets => 'Preset sets';

  @override
  String get splitSectionMyRules => 'My rules';

  @override
  String get splitEmptyRules =>
      'No rules yet.\nApply a preset set or add a rule with the «+» button.';

  @override
  String get splitNewRule => 'New rule';

  @override
  String get splitEditRule => 'Edit rule';

  @override
  String get splitFieldPattern => 'Pattern';

  @override
  String get splitFieldType => 'Rule type';

  @override
  String get splitFieldAction => 'Action';

  @override
  String get splitPatternRequired => 'Enter a pattern';

  @override
  String get ruleTypeDomain => 'Exact domain';

  @override
  String get ruleTypeDomainSuffix => 'Domain and subdomains';

  @override
  String get ruleTypeKeyword => 'Keyword';

  @override
  String get ruleTypeRegex => 'Regex';

  @override
  String get ruleTypeCidr => 'IP / CIDR';

  @override
  String get ruleTypeGeoip => 'Country (GeoIP)';

  @override
  String get ruleTypeApp => 'App (Android)';

  @override
  String get ruleTypeDomainHint => 'e.g. vk.com';

  @override
  String get ruleTypeDomainSuffixHint => 'e.g. google.com';

  @override
  String get ruleTypeKeywordHint => 'e.g. youtube';

  @override
  String get ruleTypeRegexHint => 'e.g. ^ads\\d*\\.';

  @override
  String get ruleTypeCidrHint => 'e.g. 192.168.1.0/24';

  @override
  String get ruleTypeGeoipHint => 'e.g. ru, cn';

  @override
  String get ruleTypeAppHint => 'e.g. com.example.app';

  @override
  String get ruleActionProxy => 'Via tunnel';

  @override
  String get ruleActionDirect => 'Direct';

  @override
  String get ruleActionBlock => 'Block';

  @override
  String get ruleSourcePreset => 'preset';

  @override
  String ruleEnabledSemantic(Object pattern) {
    return 'Rule $pattern is active';
  }

  @override
  String ruleDisabledSemantic(Object pattern) {
    return 'Rule $pattern is disabled';
  }

  @override
  String get splitTooltipDeleteRule => 'Delete rule';

  @override
  String get splitTooltipApplyPreset => 'Apply set';

  @override
  String get splitTooltipRemovePreset => 'Remove set';

  @override
  String presetDomainsSuffix(int count) {
    return '$count domains';
  }

  @override
  String get presetRuDirectTitle => 'Russian websites';

  @override
  String get presetRuDirectDescription =>
      'RU resources go direct, bypassing the tunnel';

  @override
  String get presetBlockedProxyTitle => 'Blocked resources';

  @override
  String get presetBlockedProxyDescription =>
      'Always via tunnel, regardless of country';

  @override
  String get presetAdsBlockTitle => 'Ads and trackers';

  @override
  String get presetAdsBlockDescription => 'Blocks advertising domains';

  @override
  String get presetSocialProxyTitle => 'Social networks';

  @override
  String get presetSocialProxyDescription =>
      'Social networks always via tunnel';

  @override
  String get splitErrorLoadFailed => 'Could not load rules';

  @override
  String get splitErrorSaveFailed => 'Could not save rules';

  @override
  String get splitErrorRuleNotFound => 'Rule not found';

  @override
  String get splitErrorPresetUnknown => 'Unknown rule set';

  @override
  String get splitErrorNoProviderRules =>
      'The subscription has no applicable rules';

  @override
  String splitErrorLimitReached(int limit) {
    return 'Rule limit reached ($limit)';
  }

  @override
  String splitErrorPatternTooShort(int min) {
    return 'Pattern is too short (minimum $min characters)';
  }

  @override
  String splitErrorPatternTooLong(int max) {
    return 'Pattern is too long (maximum $max characters)';
  }

  @override
  String get splitErrorPatternEmpty => 'Pattern is empty after normalization';

  @override
  String get splitErrorDuplicate => 'This rule already exists';

  @override
  String get splitErrorInvalidRegex => 'Invalid regular expression';

  @override
  String get splitErrorInvalidDomain => 'A domain is expected, e.g. vk.com';

  @override
  String get splitErrorInvalidKeyword =>
      'Keyword: letters, digits, dots and hyphens';

  @override
  String get splitErrorInvalidGeoip => 'A GeoIP code is expected, e.g. ru';

  @override
  String get splitErrorInvalidPackage =>
      'A package name is expected, e.g. com.example.app';

  @override
  String get splitErrorInvalidCidr =>
      'Invalid IP/CIDR (example: 192.168.1.0/24)';

  @override
  String get splitErrorReloadFailed =>
      'Rules were saved, but could not be applied to the active connection';

  @override
  String get subTooltipRefresh => 'Refresh subscription';

  @override
  String get subTooltipAdd => 'Add subscription';

  @override
  String get subSectionServers => 'Servers';

  @override
  String get subEmptyTitle => 'No subscription added';

  @override
  String get subEmptyHint => 'Get a link from your provider and add it here';

  @override
  String get subAddButton => 'Add subscription';

  @override
  String get subDefaultTitle => 'Subscription';

  @override
  String subCopied(String value) {
    return 'Copied: $value';
  }

  @override
  String subConnectingTo(String node) {
    return 'Connecting to “$node”…';
  }

  @override
  String subConnectFailed(String node) {
    return 'Could not connect to “$node”';
  }

  @override
  String subProviderRulesApplied(int count) {
    return 'Provider rules applied ($count)';
  }

  @override
  String get subDialogAddTitle => 'Add subscription';

  @override
  String get subDialogHint =>
      'Paste the link from your provider. QR scanning is coming later.';

  @override
  String get subDialogFieldLabel => 'Subscription URL';

  @override
  String get subDialogFieldHint => 'https://provider.example/sub';

  @override
  String get subDialogLoad => 'Load';

  @override
  String get subUrlEmpty => 'Enter the subscription URL';

  @override
  String get subUrlScheme => 'Only https:// and vpn:// links are supported';

  @override
  String get accountPlanNotSpecified => 'Plan not specified';

  @override
  String get accountExpiredLabel => 'expired';

  @override
  String accountDevices(int used, int max) {
    return 'Devices: $used of $max';
  }

  @override
  String accountBalance(String value) {
    return 'Balance: $value';
  }

  @override
  String accountValidUntil(String date) {
    return 'Valid until $date';
  }

  @override
  String get trafficUnlimited => 'unlimited';

  @override
  String get trafficOutOf => 'of';

  @override
  String get unitBytes => 'B';

  @override
  String get unitMegabytes => 'MB';

  @override
  String get unitGigabytes => 'GB';

  @override
  String providerRulesTitle(int count) {
    return 'Provider rules: $count';
  }

  @override
  String get providerRulesSubtitle => 'Split tunneling from the subscription';

  @override
  String get nodeConnect => 'Connect';

  @override
  String get subTooltipHideAnnouncement => 'Hide announcement';

  @override
  String get subTooltipCopy => 'Copy';

  @override
  String get subErrorEnterUrl => 'Enter the subscription URL';

  @override
  String get subErrorNoUpdateUrl => 'Update URL is not set';

  @override
  String get subErrorNetwork =>
      'Network unavailable or the subscription server did not respond';

  @override
  String get subErrorLoadFailed => 'Could not load the subscription';

  @override
  String get subErrorBroken => 'Saved subscription is corrupted';

  @override
  String get subErrorSaveFailed => 'Could not save the subscription';

  @override
  String get subErrorNoKeys =>
      'vpn:// subscription keys are not set — configure them in Settings';

  @override
  String get subErrorInvalidKey =>
      'Invalid subscription key (check Base64 and length)';

  @override
  String get subErrorExpired => 'Subscription has expired';

  @override
  String get subErrorOutdatedVersion => 'Outdated subscription format version';

  @override
  String get subErrorNoNodes => 'No available servers';

  @override
  String get subErrorNoTcpChannel =>
      'One of the nodes has no TCP channel (reliability rule)';

  @override
  String get subErrorInvalid => 'Invalid subscription';

  @override
  String get subErrorSignature => 'Subscription signature is invalid';

  @override
  String get diagnosticsTitle => 'Diagnostics';

  @override
  String get realDelayTitle => 'Real-Delay (HTTP 204)';

  @override
  String get realDelayMeasure => 'Measure';

  @override
  String realDelayValue(int ms) {
    return '$ms ms';
  }

  @override
  String get realDelayFailed => 'Probe unavailable';

  @override
  String get realDelayNoTunnel => 'Connect to measure';

  @override
  String get telemetrySection => 'Tunnel telemetry';

  @override
  String get telemetryState => 'State';

  @override
  String get telemetryProtocol => 'Protocol';

  @override
  String get telemetryTunnelMode => 'Core mode';

  @override
  String get telemetryLatency => 'Latency (ping)';

  @override
  String telemetryLatencyValue(int ms) {
    return '$ms ms';
  }

  @override
  String get telemetryDownload => 'Download';

  @override
  String get telemetryUpload => 'Upload';

  @override
  String get telemetryDuration => 'Session time';

  @override
  String get telemetrySplitRules => 'Routing rules';

  @override
  String telemetrySplitRulesValue(int active, int total) {
    return '$active active of $total';
  }

  @override
  String get telemetrySubscription => 'Subscription';

  @override
  String telemetrySubscriptionValue(String provider, int nodes) {
    return '$provider · $nodes nodes';
  }

  @override
  String get telemetryNoValue => '—';

  @override
  String get devMetaTitle => 'developer_meta';

  @override
  String devMetaGenerated(int ms) {
    return 'Config generation: $ms ms';
  }

  @override
  String devMetaBackend(String node) {
    return 'Backend: $node';
  }

  @override
  String devMetaAbGroup(String group) {
    return 'A/B group: $group';
  }

  @override
  String devMetaRecommendedMode(String mode) {
    return 'Recommended mode: $mode';
  }

  @override
  String get devMetaWebhook => 'Diagnostic webhook: set';

  @override
  String get devMetaEmpty => 'The provider did not pass developer_meta';

  @override
  String get reportSection => 'Diagnostic report';

  @override
  String get reportRefresh => 'Refresh';

  @override
  String get reportCopy => 'Copy';

  @override
  String get reportShare => 'Share';

  @override
  String get reportCopied => 'Report copied';

  @override
  String get reportNote =>
      'The report contains no server addresses or other private information';

  @override
  String get tunnelModeReal => 'real (sing-box)';

  @override
  String get tunnelModeMock => 'mock (development)';

  @override
  String reportLineGenerated(String date) {
    return 'Report of $date';
  }

  @override
  String reportLineApp(String version, String mode) {
    return 'App: Fetu $version (mode: $mode)';
  }

  @override
  String reportLineTunnel(String state, String protocol) {
    return 'Tunnel: $state, protocol: $protocol';
  }

  @override
  String reportLineTunnelNoProtocol(String state) {
    return 'Tunnel: $state';
  }

  @override
  String reportLineMetrics(String down, String up, String ping) {
    return 'Metrics: ↓ $down / ↑ $up, ping $ping ms';
  }

  @override
  String reportLineRealDelay(int value) {
    return 'Real-Delay 204: $value ms';
  }

  @override
  String get reportLineRealDelayMissing => 'Real-Delay 204: not measured';

  @override
  String reportLineRules(int active, int total) {
    return 'Routing: $active active rules of $total';
  }

  @override
  String reportLineSubscription(String provider, int nodes) {
    return 'Subscription: $provider, nodes: $nodes';
  }

  @override
  String reportLineSubscriptionExpires(String date) {
    return 'Subscription valid until: $date';
  }

  @override
  String get reportLineNoSubscription => 'Subscription: not added';

  @override
  String reportLineCore(String mode) {
    return 'Core: $mode';
  }
}
