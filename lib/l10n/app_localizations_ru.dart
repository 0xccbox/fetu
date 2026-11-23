import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get statusDisconnected => 'Отключено';

  @override
  String get statusConnecting => 'Подключается';

  @override
  String get statusConnected => 'Подключено';

  @override
  String get statusDisconnecting => 'Отключается';

  @override
  String get statusError => 'Ошибка';

  @override
  String get actionCancel => 'Отмена';

  @override
  String get actionSave => 'Сохранить';

  @override
  String get actionApply => 'Применить';

  @override
  String get actionRefresh => 'Обновить';

  @override
  String get homeTooltipSubscription => 'Подписка';

  @override
  String get homeTooltipSplitTunnel => 'Раздельное туннелирование';

  @override
  String get homeTooltipSettings => 'Настройки';

  @override
  String get homeTooltipToggleTheme => 'Переключить тему';

  @override
  String get homeAppName => 'Fetu';

  @override
  String get homeMenu => 'Меню';

  @override
  String get homeStartTitle => 'Настройте подключение';

  @override
  String get homeStartHint =>
      'Добавьте ссылку от провайдера, чтобы получить список серверов.';

  @override
  String get homeNoServerSelected => 'Сервер не выбран';

  @override
  String get homeUnknownLocation => 'Локация не указана';

  @override
  String get homeLoadingSubscription => 'Загрузка подписки…';

  @override
  String get homeServersAfterImport =>
      'Серверы появятся после добавления подписки.';

  @override
  String get homeRenewHint =>
      'Обновите подписку у провайдера или добавьте новую.';

  @override
  String get homeRestoreFailed => 'Не удалось прочитать сохранённую подписку';

  @override
  String get homeRestoreHint =>
      'Защищённое хранилище недоступно. Повторите загрузку.';

  @override
  String get homeRetry => 'Повторить';

  @override
  String get homeUseForSession => 'Добавить на этот сеанс';

  @override
  String get homeSessionOnly => 'Подписка не сохранится после перезапуска.';

  @override
  String get homeDisconnectToChooseServer =>
      'Отключите соединение, чтобы выбрать другой сервер.';

  @override
  String get homeProviderTelegram => 'Telegram';

  @override
  String get homeProviderWebsite => 'Сайт';

  @override
  String get homeProviderSupport => 'Поддержка';

  @override
  String get homeProviderLink => 'Ссылка';

  @override
  String get homeMoreLinks => 'Другие ссылки';

  @override
  String get homeLinkFailed => 'Не удалось открыть ссылку';

  @override
  String get homeDownload => 'Загрузка';

  @override
  String get serverCountryGermany => 'Германия';

  @override
  String get serverCountryNetherlands => 'Нидерланды';

  @override
  String get serverCountryJapan => 'Япония';

  @override
  String get serverCountryUS => 'США';

  @override
  String get serverCountryRussia => 'Россия';

  @override
  String get serverCountryFrance => 'Франция';

  @override
  String get serverCountryFinland => 'Финляндия';

  @override
  String get serverCountryUK => 'Великобритания';

  @override
  String get serverCountryKazakhstan => 'Казахстан';

  @override
  String get serverCountrySingapore => 'Сингапур';

  @override
  String homeProtectionMode(String mode) {
    return 'Режим защиты: $mode';
  }

  @override
  String get modeSelectionTitle => 'Выберите режим';

  @override
  String get modeSelectionSubtitle =>
      'Как вам удобнее пользоваться приложением?';

  @override
  String get modeSimpleTitle => 'Простой режим';

  @override
  String get modeSimpleDescription =>
      'Умный доступ, максимальная скрытность и двойная защита маршрута включаются автоматически. Сетевые термины переведены на человеческий язык.';

  @override
  String get modeAdvancedTitle => 'Расширенный режим';

  @override
  String get modeAdvancedDescription =>
      'Полная телеметрия: протоколы, Real-Delay 204, статусы .srs-правил и developer_meta провайдера.';

  @override
  String get modeSelectionHint =>
      'Режим можно изменить в настройках в любой момент.';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsSectionInterface => 'Интерфейс';

  @override
  String get settingsSectionAppearance => 'Оформление';

  @override
  String get themeModeLight => 'Светлая';

  @override
  String get themeModeDark => 'Тёмная';

  @override
  String get themeModeSystem => 'Системная';

  @override
  String get settingsSectionSubscriptionKeys => 'Ключи подписки (vpn://)';

  @override
  String get settingsKeysHint =>
      'Ключи от провайдера в Base64: публичный Ed25519 и ключ AES-256. Если провайдер использует HMAC, добавьте hmac: перед секретом проверки подписи.';

  @override
  String get settingsKeyVerifyLabel => 'Ключ проверки подписи';

  @override
  String get settingsKeyDecryptLabel => 'Ключ расшифровки';

  @override
  String get settingsKeysSave => 'Сохранить ключи';

  @override
  String get settingsKeysClear => 'Очистить ключи';

  @override
  String get settingsKeysSaved => 'Ключи сохранены';

  @override
  String get settingsKeysCleared => 'Ключи удалены';

  @override
  String get settingsKeysInvalid =>
      'Проверьте ключи: ожидаются корректные Base64-строки (32 байта)';

  @override
  String get settingsSectionAdvanced => 'Для профи';

  @override
  String get settingsDiagnosticsTitle => 'Диагностика';

  @override
  String get settingsDiagnosticsSubtitle =>
      'Real-Delay, телеметрия туннеля, диагностический отчёт';

  @override
  String get settingsSectionAbout => 'О приложении';

  @override
  String settingsVersion(String version) {
    return 'Версия $version';
  }

  @override
  String get uxTermSmartAccess => 'Умный доступ';

  @override
  String get uxTermMaxStealth => 'Максимальная скрытность';

  @override
  String get uxTermClassicProtection => 'Классическая защита';

  @override
  String get uxTermCascade => 'Двойная защита маршрута';

  @override
  String get uiModeSimpleLabel => 'простой';

  @override
  String get uiModeAdvancedLabel => 'расширенный';

  @override
  String get failoverTitle => 'Переключение протокола';

  @override
  String get failoverReasonTimeoutSimple =>
      'Канал не отвечает — включили запасной';

  @override
  String failoverReasonTimeoutAdvanced(String protocol) {
    return 'Таймаут подключения $protocol';
  }

  @override
  String get failoverReasonPacketLossSimple =>
      'Связь стала нестабильной — включили запасной канал';

  @override
  String failoverReasonPacketLossAdvanced(String protocol) {
    return 'Потеря пакетов на $protocol';
  }

  @override
  String get failoverReasonBlockedSimple =>
      'Канал заблокирован — включили скрытый';

  @override
  String failoverReasonBlockedAdvanced(String protocol) {
    return '$protocol заблокирован';
  }

  @override
  String get failoverReasonHandshakeSimple =>
      'Канал не установился — пробуем другой';

  @override
  String failoverReasonHandshakeAdvanced(String protocol) {
    return 'Ошибка handshake $protocol';
  }

  @override
  String get failoverReasonManual => 'Ручное переключение';

  @override
  String failoverSwitchedTo(String protocol) {
    return 'Переключение на $protocol…';
  }

  @override
  String get connectionErrorNodeMissing => 'Не выбран сервер для подключения';

  @override
  String get connectionErrorConnectFailed => 'Не удалось подключиться';

  @override
  String get connectionErrorCoreUnavailable =>
      'В этой сборке отсутствует сетевое ядро';

  @override
  String get homeDisconnect => 'Отключить';

  @override
  String get homeSelectServer => 'Выбрать сервер';

  @override
  String get homeChooseServerHint => 'Выберите сервер из списка ниже';

  @override
  String get homeSelectedServer => 'Выбран';

  @override
  String get smartSelectionTitle => 'УМНЫЙ ВЫБОР СЕРВЕРА';

  @override
  String get smartSelectionSubtitle => 'Автоматически выбрать лучший сервер';

  @override
  String get connectionErrorDisconnectFailed => 'Не удалось отключиться';

  @override
  String get metricTime => 'Время';

  @override
  String get metricPing => 'Ping';

  @override
  String get metricTraffic => 'Трафик';

  @override
  String serverHealthScoreValue(int score) {
    return 'Рейтинг $score';
  }

  @override
  String get splitTitle => 'Раздельное туннелирование';

  @override
  String get splitTooltipAddRule => 'Добавить правило';

  @override
  String get splitSectionPresets => 'Готовые наборы';

  @override
  String get splitSectionMyRules => 'Мои правила';

  @override
  String get splitEmptyRules =>
      'Правил пока нет.\nПримените готовый набор или добавьте правило кнопкой «+».';

  @override
  String get splitNewRule => 'Новое правило';

  @override
  String get splitEditRule => 'Изменить правило';

  @override
  String get splitFieldPattern => 'Паттерн';

  @override
  String get splitFieldType => 'Тип правила';

  @override
  String get splitFieldAction => 'Действие';

  @override
  String get splitPatternRequired => 'Введите паттерн';

  @override
  String get ruleTypeDomain => 'Точный домен';

  @override
  String get ruleTypeDomainSuffix => 'Домен и поддомены';

  @override
  String get ruleTypeKeyword => 'Ключевое слово';

  @override
  String get ruleTypeRegex => 'Regex';

  @override
  String get ruleTypeCidr => 'IP / CIDR';

  @override
  String get ruleTypeGeoip => 'Страна (GeoIP)';

  @override
  String get ruleTypeApp => 'Приложение (Android)';

  @override
  String get ruleTypeDomainHint => 'например: vk.com';

  @override
  String get ruleTypeDomainSuffixHint => 'например: google.com';

  @override
  String get ruleTypeKeywordHint => 'например: youtube';

  @override
  String get ruleTypeRegexHint => 'например: ^ads\\d*\\.';

  @override
  String get ruleTypeCidrHint => 'например: 192.168.1.0/24';

  @override
  String get ruleTypeGeoipHint => 'например: ru, cn';

  @override
  String get ruleTypeAppHint => 'например: com.example.app';

  @override
  String get ruleActionProxy => 'Через туннель';

  @override
  String get ruleActionDirect => 'Напрямую';

  @override
  String get ruleActionBlock => 'Блокировать';

  @override
  String get ruleSourcePreset => 'набор';

  @override
  String ruleEnabledSemantic(Object pattern) {
    return 'Правило $pattern активно';
  }

  @override
  String ruleDisabledSemantic(Object pattern) {
    return 'Правило $pattern выключено';
  }

  @override
  String get splitTooltipDeleteRule => 'Удалить правило';

  @override
  String get splitTooltipApplyPreset => 'Применить набор';

  @override
  String get splitTooltipRemovePreset => 'Убрать набор';

  @override
  String presetDomainsSuffix(int count) {
    return '$count дом.';
  }

  @override
  String get presetRuDirectTitle => 'Российские сайты';

  @override
  String get presetRuDirectDescription =>
      'RU-ресурсы идут напрямую, в обход туннеля';

  @override
  String get presetBlockedProxyTitle => 'Заблокированные ресурсы';

  @override
  String get presetBlockedProxyDescription =>
      'Через туннель всегда, независимо от страны';

  @override
  String get presetAdsBlockTitle => 'Реклама и трекеры';

  @override
  String get presetAdsBlockDescription => 'Блокировка рекламных доменов';

  @override
  String get presetSocialProxyTitle => 'Социальные сети';

  @override
  String get presetSocialProxyDescription => 'Соцсети всегда через туннель';

  @override
  String get splitErrorLoadFailed => 'Не удалось загрузить правила';

  @override
  String get splitErrorSaveFailed => 'Не удалось сохранить правила';

  @override
  String get splitErrorRuleNotFound => 'Правило не найдено';

  @override
  String get splitErrorPresetUnknown => 'Неизвестный набор правил';

  @override
  String get splitErrorNoProviderRules => 'В подписке нет применимых правил';

  @override
  String splitErrorLimitReached(int limit) {
    return 'Достигнут лимит правил ($limit)';
  }

  @override
  String splitErrorPatternTooShort(int min) {
    return 'Паттерн слишком короткий (минимум $min символа)';
  }

  @override
  String splitErrorPatternTooLong(int max) {
    return 'Паттерн слишком длинный (максимум $max символов)';
  }

  @override
  String get splitErrorPatternEmpty => 'Паттерн пуст после нормализации';

  @override
  String get splitErrorDuplicate => 'Такое правило уже существует';

  @override
  String get splitErrorInvalidRegex => 'Некорректное регулярное выражение';

  @override
  String get splitErrorInvalidDomain => 'Ожидается домен, например vk.com';

  @override
  String get splitErrorInvalidKeyword =>
      'Ключевое слово: буквы, цифры, точки и дефисы';

  @override
  String get splitErrorInvalidGeoip => 'Ожидается GeoIP-код, например ru';

  @override
  String get splitErrorInvalidPackage =>
      'Ожидается имя пакета, например com.example.app';

  @override
  String get splitErrorInvalidCidr =>
      'Некорректный IP/CIDR (пример: 192.168.1.0/24)';

  @override
  String get splitErrorReloadFailed =>
      'Правила сохранены, но применить их к активному соединению не удалось';

  @override
  String get subTooltipRefresh => 'Обновить подписку';

  @override
  String get subTooltipAdd => 'Добавить подписку';

  @override
  String get subSectionServers => 'Серверы';

  @override
  String get subEmptyTitle => 'Подписка не добавлена';

  @override
  String get subEmptyHint => 'Получите ссылку у провайдера и добавьте её здесь';

  @override
  String get subAddButton => 'Добавить подписку';

  @override
  String get subDefaultTitle => 'Подписка';

  @override
  String subCopied(String value) {
    return 'Скопировано: $value';
  }

  @override
  String subConnectingTo(String node) {
    return 'Подключение к «$node»…';
  }

  @override
  String subConnectFailed(String node) {
    return 'Не удалось подключиться к «$node»';
  }

  @override
  String subProviderRulesApplied(int count) {
    return 'Правила провайдера применены ($count)';
  }

  @override
  String get subDialogAddTitle => 'Добавить подписку';

  @override
  String get subDialogHint =>
      'Вставьте ссылку от провайдера. QR-сканирование появится позже.';

  @override
  String get subDialogFieldLabel => 'URL подписки';

  @override
  String get subDialogFieldHint => 'https://provider.example/sub';

  @override
  String get subDialogLoad => 'Загрузить';

  @override
  String get subUrlEmpty => 'Введите URL подписки';

  @override
  String get subUrlScheme => 'Поддерживаются https:// и vpn:// ссылки';

  @override
  String get accountPlanNotSpecified => 'Тариф не указан';

  @override
  String get accountExpiredLabel => 'истёк';

  @override
  String accountDevices(int used, int max) {
    return 'Устройства: $used из $max';
  }

  @override
  String accountBalance(String value) {
    return 'Баланс: $value';
  }

  @override
  String accountValidUntil(String date) {
    return 'Действует до $date';
  }

  @override
  String get trafficUnlimited => 'безлимит';

  @override
  String get trafficOutOf => 'из';

  @override
  String get unitBytes => 'Б';

  @override
  String get unitMegabytes => 'МБ';

  @override
  String get unitGigabytes => 'ГБ';

  @override
  String providerRulesTitle(int count) {
    return 'Правила провайдера: $count';
  }

  @override
  String get providerRulesSubtitle => 'Раздельное туннелирование из подписки';

  @override
  String get nodeConnect => 'Подключить';

  @override
  String get subTooltipHideAnnouncement => 'Скрыть объявление';

  @override
  String get subTooltipCopy => 'Копировать';

  @override
  String get subErrorEnterUrl => 'Введите URL подписки';

  @override
  String get subErrorNoUpdateUrl => 'URL обновления не задан';

  @override
  String get subErrorNetwork =>
      'Сеть недоступна или сервер подписки не ответил';

  @override
  String get subErrorLoadFailed => 'Не удалось загрузить подписку';

  @override
  String get subErrorBroken => 'Сохранённая подписка повреждена';

  @override
  String get subErrorSaveFailed => 'Не удалось сохранить подписку';

  @override
  String get subErrorNoKeys =>
      'Ключи для vpn://-подписки не заданы — настройте их в «Настройках»';

  @override
  String get subErrorInvalidKey =>
      'Некорректный ключ подписки (проверьте Base64 и длину)';

  @override
  String get subErrorExpired => 'Подписка истекла';

  @override
  String get subErrorOutdatedVersion => 'Устаревшая версия формата подписки';

  @override
  String get subErrorNoNodes => 'Нет доступных серверов';

  @override
  String get subErrorNoTcpChannel =>
      'У одного из узлов нет TCP-канала (правило надёжности)';

  @override
  String get subErrorInvalid => 'Некорректная подписка';

  @override
  String get subErrorSignature => 'Подпись подписки невалидна';

  @override
  String get diagnosticsTitle => 'Диагностика';

  @override
  String get realDelayTitle => 'Real-Delay (HTTP 204)';

  @override
  String get realDelayMeasure => 'Измерить';

  @override
  String realDelayValue(int ms) {
    return '$ms мс';
  }

  @override
  String get realDelayFailed => 'Зонд недоступен';

  @override
  String get realDelayNoTunnel => 'Подключитесь, чтобы измерить';

  @override
  String get telemetrySection => 'Телеметрия туннеля';

  @override
  String get telemetryState => 'Состояние';

  @override
  String get telemetryProtocol => 'Протокол';

  @override
  String get telemetryTunnelMode => 'Режим ядра';

  @override
  String get telemetryLatency => 'Задержка (ping)';

  @override
  String telemetryLatencyValue(int ms) {
    return '$ms мс';
  }

  @override
  String get telemetryDownload => 'Загрузка';

  @override
  String get telemetryUpload => 'Отдача';

  @override
  String get telemetryDuration => 'Время сессии';

  @override
  String get telemetrySplitRules => 'Правила маршрутизации';

  @override
  String telemetrySplitRulesValue(int active, int total) {
    return '$active активных из $total';
  }

  @override
  String get telemetrySubscription => 'Подписка';

  @override
  String telemetrySubscriptionValue(String provider, int nodes) {
    return '$provider · $nodes узл.';
  }

  @override
  String get telemetryNoValue => '—';

  @override
  String get devMetaTitle => 'developer_meta';

  @override
  String devMetaGenerated(int ms) {
    return 'Генерация конфига: $ms мс';
  }

  @override
  String devMetaBackend(String node) {
    return 'Бэкенд: $node';
  }

  @override
  String devMetaAbGroup(String group) {
    return 'A/B-группа: $group';
  }

  @override
  String devMetaRecommendedMode(String mode) {
    return 'Рекомендованный режим: $mode';
  }

  @override
  String get devMetaWebhook => 'Диагностический webhook: задан';

  @override
  String get devMetaEmpty => 'Провайдер не передал developer_meta';

  @override
  String get reportSection => 'Диагностический отчёт';

  @override
  String get reportRefresh => 'Обновить';

  @override
  String get reportCopy => 'Скопировать';

  @override
  String get reportShare => 'Поделиться';

  @override
  String get reportCopied => 'Отчёт скопирован';

  @override
  String get reportNote =>
      'Отчёт не содержит адресов серверов и другой приватной информации';

  @override
  String get tunnelModeReal => 'реальный (sing-box)';

  @override
  String get tunnelModeMock => 'мок (разработка)';

  @override
  String reportLineGenerated(String date) {
    return 'Отчёт от $date';
  }

  @override
  String reportLineApp(String version, String mode) {
    return 'Приложение: Fetu $version (режим: $mode)';
  }

  @override
  String reportLineTunnel(String state, String protocol) {
    return 'Туннель: $state, протокол: $protocol';
  }

  @override
  String reportLineTunnelNoProtocol(String state) {
    return 'Туннель: $state';
  }

  @override
  String reportLineMetrics(String down, String up, String ping) {
    return 'Метрики: ↓ $down / ↑ $up, ping $ping мс';
  }

  @override
  String reportLineRealDelay(int value) {
    return 'Real-Delay 204: $value мс';
  }

  @override
  String get reportLineRealDelayMissing => 'Real-Delay 204: не измерялся';

  @override
  String reportLineRules(int active, int total) {
    return 'Маршрутизация: $active активных правил из $total';
  }

  @override
  String reportLineSubscription(String provider, int nodes) {
    return 'Подписка: $provider, узлов: $nodes';
  }

  @override
  String reportLineSubscriptionExpires(String date) {
    return 'Подписка действительна до: $date';
  }

  @override
  String get reportLineNoSubscription => 'Подписка: не добавлена';

  @override
  String reportLineCore(String mode) {
    return 'Ядро: $mode';
  }
}
