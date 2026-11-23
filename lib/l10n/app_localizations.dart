import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru')
  ];

  /// No description provided for @statusDisconnected.
  ///
  /// In ru, this message translates to:
  /// **'Отключено'**
  String get statusDisconnected;

  /// No description provided for @statusConnecting.
  ///
  /// In ru, this message translates to:
  /// **'Подключается'**
  String get statusConnecting;

  /// No description provided for @statusConnected.
  ///
  /// In ru, this message translates to:
  /// **'Подключено'**
  String get statusConnected;

  /// No description provided for @statusDisconnecting.
  ///
  /// In ru, this message translates to:
  /// **'Отключается'**
  String get statusDisconnecting;

  /// No description provided for @statusError.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка'**
  String get statusError;

  /// No description provided for @actionCancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get actionCancel;

  /// No description provided for @actionSave.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get actionSave;

  /// No description provided for @actionApply.
  ///
  /// In ru, this message translates to:
  /// **'Применить'**
  String get actionApply;

  /// No description provided for @actionRefresh.
  ///
  /// In ru, this message translates to:
  /// **'Обновить'**
  String get actionRefresh;

  /// No description provided for @homeTooltipSubscription.
  ///
  /// In ru, this message translates to:
  /// **'Подписка'**
  String get homeTooltipSubscription;

  /// No description provided for @homeTooltipSplitTunnel.
  ///
  /// In ru, this message translates to:
  /// **'Раздельное туннелирование'**
  String get homeTooltipSplitTunnel;

  /// No description provided for @homeTooltipSettings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get homeTooltipSettings;

  /// No description provided for @homeTooltipToggleTheme.
  ///
  /// In ru, this message translates to:
  /// **'Переключить тему'**
  String get homeTooltipToggleTheme;

  /// No description provided for @homeAppName.
  ///
  /// In ru, this message translates to:
  /// **'Fetu'**
  String get homeAppName;

  /// No description provided for @homeMenu.
  ///
  /// In ru, this message translates to:
  /// **'Меню'**
  String get homeMenu;

  /// No description provided for @homeStartTitle.
  ///
  /// In ru, this message translates to:
  /// **'Настройте подключение'**
  String get homeStartTitle;

  /// No description provided for @homeStartHint.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте ссылку от провайдера, чтобы получить список серверов.'**
  String get homeStartHint;

  /// No description provided for @homeNoServerSelected.
  ///
  /// In ru, this message translates to:
  /// **'Сервер не выбран'**
  String get homeNoServerSelected;

  /// No description provided for @homeUnknownLocation.
  ///
  /// In ru, this message translates to:
  /// **'Локация не указана'**
  String get homeUnknownLocation;

  /// No description provided for @homeLoadingSubscription.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка подписки…'**
  String get homeLoadingSubscription;

  /// No description provided for @homeServersAfterImport.
  ///
  /// In ru, this message translates to:
  /// **'Серверы появятся после добавления подписки.'**
  String get homeServersAfterImport;

  /// No description provided for @homeRenewHint.
  ///
  /// In ru, this message translates to:
  /// **'Обновите подписку у провайдера или добавьте новую.'**
  String get homeRenewHint;

  /// No description provided for @homeRestoreFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось прочитать сохранённую подписку'**
  String get homeRestoreFailed;

  /// No description provided for @homeRestoreHint.
  ///
  /// In ru, this message translates to:
  /// **'Защищённое хранилище недоступно. Повторите загрузку.'**
  String get homeRestoreHint;

  /// No description provided for @homeRetry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get homeRetry;

  /// No description provided for @homeUseForSession.
  ///
  /// In ru, this message translates to:
  /// **'Добавить на этот сеанс'**
  String get homeUseForSession;

  /// No description provided for @homeSessionOnly.
  ///
  /// In ru, this message translates to:
  /// **'Подписка не сохранится после перезапуска.'**
  String get homeSessionOnly;

  /// No description provided for @homeDisconnectToChooseServer.
  ///
  /// In ru, this message translates to:
  /// **'Отключите соединение, чтобы выбрать другой сервер.'**
  String get homeDisconnectToChooseServer;

  /// No description provided for @homeProviderTelegram.
  ///
  /// In ru, this message translates to:
  /// **'Telegram'**
  String get homeProviderTelegram;

  /// No description provided for @homeProviderWebsite.
  ///
  /// In ru, this message translates to:
  /// **'Сайт'**
  String get homeProviderWebsite;

  /// No description provided for @homeProviderSupport.
  ///
  /// In ru, this message translates to:
  /// **'Поддержка'**
  String get homeProviderSupport;

  /// No description provided for @homeProviderLink.
  ///
  /// In ru, this message translates to:
  /// **'Ссылка'**
  String get homeProviderLink;

  /// No description provided for @homeMoreLinks.
  ///
  /// In ru, this message translates to:
  /// **'Другие ссылки'**
  String get homeMoreLinks;

  /// No description provided for @homeLinkFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть ссылку'**
  String get homeLinkFailed;

  /// No description provided for @homeDownload.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка'**
  String get homeDownload;

  /// No description provided for @serverCountryGermany.
  ///
  /// In ru, this message translates to:
  /// **'Германия'**
  String get serverCountryGermany;

  /// No description provided for @serverCountryNetherlands.
  ///
  /// In ru, this message translates to:
  /// **'Нидерланды'**
  String get serverCountryNetherlands;

  /// No description provided for @serverCountryJapan.
  ///
  /// In ru, this message translates to:
  /// **'Япония'**
  String get serverCountryJapan;

  /// No description provided for @serverCountryUS.
  ///
  /// In ru, this message translates to:
  /// **'США'**
  String get serverCountryUS;

  /// No description provided for @serverCountryRussia.
  ///
  /// In ru, this message translates to:
  /// **'Россия'**
  String get serverCountryRussia;

  /// No description provided for @serverCountryFrance.
  ///
  /// In ru, this message translates to:
  /// **'Франция'**
  String get serverCountryFrance;

  /// No description provided for @serverCountryFinland.
  ///
  /// In ru, this message translates to:
  /// **'Финляндия'**
  String get serverCountryFinland;

  /// No description provided for @serverCountryUK.
  ///
  /// In ru, this message translates to:
  /// **'Великобритания'**
  String get serverCountryUK;

  /// No description provided for @serverCountryKazakhstan.
  ///
  /// In ru, this message translates to:
  /// **'Казахстан'**
  String get serverCountryKazakhstan;

  /// No description provided for @serverCountrySingapore.
  ///
  /// In ru, this message translates to:
  /// **'Сингапур'**
  String get serverCountrySingapore;

  /// No description provided for @homeProtectionMode.
  ///
  /// In ru, this message translates to:
  /// **'Режим защиты: {mode}'**
  String homeProtectionMode(String mode);

  /// No description provided for @modeSelectionTitle.
  ///
  /// In ru, this message translates to:
  /// **'Выберите режим'**
  String get modeSelectionTitle;

  /// No description provided for @modeSelectionSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Как вам удобнее пользоваться приложением?'**
  String get modeSelectionSubtitle;

  /// No description provided for @modeSimpleTitle.
  ///
  /// In ru, this message translates to:
  /// **'Простой режим'**
  String get modeSimpleTitle;

  /// No description provided for @modeSimpleDescription.
  ///
  /// In ru, this message translates to:
  /// **'Умный доступ, максимальная скрытность и двойная защита маршрута включаются автоматически. Сетевые термины переведены на человеческий язык.'**
  String get modeSimpleDescription;

  /// No description provided for @modeAdvancedTitle.
  ///
  /// In ru, this message translates to:
  /// **'Расширенный режим'**
  String get modeAdvancedTitle;

  /// No description provided for @modeAdvancedDescription.
  ///
  /// In ru, this message translates to:
  /// **'Полная телеметрия: протоколы, Real-Delay 204, статусы .srs-правил и developer_meta провайдера.'**
  String get modeAdvancedDescription;

  /// No description provided for @modeSelectionHint.
  ///
  /// In ru, this message translates to:
  /// **'Режим можно изменить в настройках в любой момент.'**
  String get modeSelectionHint;

  /// No description provided for @settingsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settingsTitle;

  /// No description provided for @settingsSectionInterface.
  ///
  /// In ru, this message translates to:
  /// **'Интерфейс'**
  String get settingsSectionInterface;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In ru, this message translates to:
  /// **'Оформление'**
  String get settingsSectionAppearance;

  /// No description provided for @themeModeLight.
  ///
  /// In ru, this message translates to:
  /// **'Светлая'**
  String get themeModeLight;

  /// No description provided for @themeModeDark.
  ///
  /// In ru, this message translates to:
  /// **'Тёмная'**
  String get themeModeDark;

  /// No description provided for @themeModeSystem.
  ///
  /// In ru, this message translates to:
  /// **'Системная'**
  String get themeModeSystem;

  /// No description provided for @settingsSectionSubscriptionKeys.
  ///
  /// In ru, this message translates to:
  /// **'Ключи подписки (vpn://)'**
  String get settingsSectionSubscriptionKeys;

  /// No description provided for @settingsKeysHint.
  ///
  /// In ru, this message translates to:
  /// **'Ключи от провайдера в Base64: публичный Ed25519 и ключ AES-256. Если провайдер использует HMAC, добавьте hmac: перед секретом проверки подписи.'**
  String get settingsKeysHint;

  /// No description provided for @settingsKeyVerifyLabel.
  ///
  /// In ru, this message translates to:
  /// **'Ключ проверки подписи'**
  String get settingsKeyVerifyLabel;

  /// No description provided for @settingsKeyDecryptLabel.
  ///
  /// In ru, this message translates to:
  /// **'Ключ расшифровки'**
  String get settingsKeyDecryptLabel;

  /// No description provided for @settingsKeysSave.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить ключи'**
  String get settingsKeysSave;

  /// No description provided for @settingsKeysClear.
  ///
  /// In ru, this message translates to:
  /// **'Очистить ключи'**
  String get settingsKeysClear;

  /// No description provided for @settingsKeysSaved.
  ///
  /// In ru, this message translates to:
  /// **'Ключи сохранены'**
  String get settingsKeysSaved;

  /// No description provided for @settingsKeysCleared.
  ///
  /// In ru, this message translates to:
  /// **'Ключи удалены'**
  String get settingsKeysCleared;

  /// No description provided for @settingsKeysInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте ключи: ожидаются корректные Base64-строки (32 байта)'**
  String get settingsKeysInvalid;

  /// No description provided for @settingsSectionAdvanced.
  ///
  /// In ru, this message translates to:
  /// **'Для профи'**
  String get settingsSectionAdvanced;

  /// No description provided for @settingsDiagnosticsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Диагностика'**
  String get settingsDiagnosticsTitle;

  /// No description provided for @settingsDiagnosticsSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Real-Delay, телеметрия туннеля, диагностический отчёт'**
  String get settingsDiagnosticsSubtitle;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In ru, this message translates to:
  /// **'О приложении'**
  String get settingsSectionAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In ru, this message translates to:
  /// **'Версия {version}'**
  String settingsVersion(String version);

  /// No description provided for @uxTermSmartAccess.
  ///
  /// In ru, this message translates to:
  /// **'Умный доступ'**
  String get uxTermSmartAccess;

  /// No description provided for @uxTermMaxStealth.
  ///
  /// In ru, this message translates to:
  /// **'Максимальная скрытность'**
  String get uxTermMaxStealth;

  /// No description provided for @uxTermClassicProtection.
  ///
  /// In ru, this message translates to:
  /// **'Классическая защита'**
  String get uxTermClassicProtection;

  /// No description provided for @uxTermCascade.
  ///
  /// In ru, this message translates to:
  /// **'Двойная защита маршрута'**
  String get uxTermCascade;

  /// No description provided for @uiModeSimpleLabel.
  ///
  /// In ru, this message translates to:
  /// **'простой'**
  String get uiModeSimpleLabel;

  /// No description provided for @uiModeAdvancedLabel.
  ///
  /// In ru, this message translates to:
  /// **'расширенный'**
  String get uiModeAdvancedLabel;

  /// No description provided for @failoverTitle.
  ///
  /// In ru, this message translates to:
  /// **'Переключение протокола'**
  String get failoverTitle;

  /// No description provided for @failoverReasonTimeoutSimple.
  ///
  /// In ru, this message translates to:
  /// **'Канал не отвечает — включили запасной'**
  String get failoverReasonTimeoutSimple;

  /// No description provided for @failoverReasonTimeoutAdvanced.
  ///
  /// In ru, this message translates to:
  /// **'Таймаут подключения {protocol}'**
  String failoverReasonTimeoutAdvanced(String protocol);

  /// No description provided for @failoverReasonPacketLossSimple.
  ///
  /// In ru, this message translates to:
  /// **'Связь стала нестабильной — включили запасной канал'**
  String get failoverReasonPacketLossSimple;

  /// No description provided for @failoverReasonPacketLossAdvanced.
  ///
  /// In ru, this message translates to:
  /// **'Потеря пакетов на {protocol}'**
  String failoverReasonPacketLossAdvanced(String protocol);

  /// No description provided for @failoverReasonBlockedSimple.
  ///
  /// In ru, this message translates to:
  /// **'Канал заблокирован — включили скрытый'**
  String get failoverReasonBlockedSimple;

  /// No description provided for @failoverReasonBlockedAdvanced.
  ///
  /// In ru, this message translates to:
  /// **'{protocol} заблокирован'**
  String failoverReasonBlockedAdvanced(String protocol);

  /// No description provided for @failoverReasonHandshakeSimple.
  ///
  /// In ru, this message translates to:
  /// **'Канал не установился — пробуем другой'**
  String get failoverReasonHandshakeSimple;

  /// No description provided for @failoverReasonHandshakeAdvanced.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка handshake {protocol}'**
  String failoverReasonHandshakeAdvanced(String protocol);

  /// No description provided for @failoverReasonManual.
  ///
  /// In ru, this message translates to:
  /// **'Ручное переключение'**
  String get failoverReasonManual;

  /// No description provided for @failoverSwitchedTo.
  ///
  /// In ru, this message translates to:
  /// **'Переключение на {protocol}…'**
  String failoverSwitchedTo(String protocol);

  /// No description provided for @connectionErrorNodeMissing.
  ///
  /// In ru, this message translates to:
  /// **'Не выбран сервер для подключения'**
  String get connectionErrorNodeMissing;

  /// No description provided for @connectionErrorConnectFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось подключиться'**
  String get connectionErrorConnectFailed;

  /// No description provided for @connectionErrorCoreUnavailable.
  ///
  /// In ru, this message translates to:
  /// **'В этой сборке отсутствует сетевое ядро'**
  String get connectionErrorCoreUnavailable;

  /// No description provided for @homeDisconnect.
  ///
  /// In ru, this message translates to:
  /// **'Отключить'**
  String get homeDisconnect;

  /// No description provided for @homeSelectServer.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать сервер'**
  String get homeSelectServer;

  /// No description provided for @homeChooseServerHint.
  ///
  /// In ru, this message translates to:
  /// **'Выберите сервер из списка ниже'**
  String get homeChooseServerHint;

  /// No description provided for @homeSelectedServer.
  ///
  /// In ru, this message translates to:
  /// **'Выбран'**
  String get homeSelectedServer;

  /// No description provided for @smartSelectionTitle.
  ///
  /// In ru, this message translates to:
  /// **'УМНЫЙ ВЫБОР СЕРВЕРА'**
  String get smartSelectionTitle;

  /// No description provided for @smartSelectionSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Автоматически выбрать лучший сервер'**
  String get smartSelectionSubtitle;

  /// No description provided for @connectionErrorDisconnectFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отключиться'**
  String get connectionErrorDisconnectFailed;

  /// No description provided for @metricTime.
  ///
  /// In ru, this message translates to:
  /// **'Время'**
  String get metricTime;

  /// No description provided for @metricPing.
  ///
  /// In ru, this message translates to:
  /// **'Ping'**
  String get metricPing;

  /// No description provided for @metricTraffic.
  ///
  /// In ru, this message translates to:
  /// **'Трафик'**
  String get metricTraffic;

  /// No description provided for @serverHealthScoreValue.
  ///
  /// In ru, this message translates to:
  /// **'Рейтинг {score}'**
  String serverHealthScoreValue(int score);

  /// No description provided for @splitTitle.
  ///
  /// In ru, this message translates to:
  /// **'Раздельное туннелирование'**
  String get splitTitle;

  /// No description provided for @splitTooltipAddRule.
  ///
  /// In ru, this message translates to:
  /// **'Добавить правило'**
  String get splitTooltipAddRule;

  /// No description provided for @splitSectionPresets.
  ///
  /// In ru, this message translates to:
  /// **'Готовые наборы'**
  String get splitSectionPresets;

  /// No description provided for @splitSectionMyRules.
  ///
  /// In ru, this message translates to:
  /// **'Мои правила'**
  String get splitSectionMyRules;

  /// No description provided for @splitEmptyRules.
  ///
  /// In ru, this message translates to:
  /// **'Правил пока нет.\nПримените готовый набор или добавьте правило кнопкой «+».'**
  String get splitEmptyRules;

  /// No description provided for @splitNewRule.
  ///
  /// In ru, this message translates to:
  /// **'Новое правило'**
  String get splitNewRule;

  /// No description provided for @splitEditRule.
  ///
  /// In ru, this message translates to:
  /// **'Изменить правило'**
  String get splitEditRule;

  /// No description provided for @splitFieldPattern.
  ///
  /// In ru, this message translates to:
  /// **'Паттерн'**
  String get splitFieldPattern;

  /// No description provided for @splitFieldType.
  ///
  /// In ru, this message translates to:
  /// **'Тип правила'**
  String get splitFieldType;

  /// No description provided for @splitFieldAction.
  ///
  /// In ru, this message translates to:
  /// **'Действие'**
  String get splitFieldAction;

  /// No description provided for @splitPatternRequired.
  ///
  /// In ru, this message translates to:
  /// **'Введите паттерн'**
  String get splitPatternRequired;

  /// No description provided for @ruleTypeDomain.
  ///
  /// In ru, this message translates to:
  /// **'Точный домен'**
  String get ruleTypeDomain;

  /// No description provided for @ruleTypeDomainSuffix.
  ///
  /// In ru, this message translates to:
  /// **'Домен и поддомены'**
  String get ruleTypeDomainSuffix;

  /// No description provided for @ruleTypeKeyword.
  ///
  /// In ru, this message translates to:
  /// **'Ключевое слово'**
  String get ruleTypeKeyword;

  /// No description provided for @ruleTypeRegex.
  ///
  /// In ru, this message translates to:
  /// **'Regex'**
  String get ruleTypeRegex;

  /// No description provided for @ruleTypeCidr.
  ///
  /// In ru, this message translates to:
  /// **'IP / CIDR'**
  String get ruleTypeCidr;

  /// No description provided for @ruleTypeGeoip.
  ///
  /// In ru, this message translates to:
  /// **'Страна (GeoIP)'**
  String get ruleTypeGeoip;

  /// No description provided for @ruleTypeApp.
  ///
  /// In ru, this message translates to:
  /// **'Приложение (Android)'**
  String get ruleTypeApp;

  /// No description provided for @ruleTypeDomainHint.
  ///
  /// In ru, this message translates to:
  /// **'например: vk.com'**
  String get ruleTypeDomainHint;

  /// No description provided for @ruleTypeDomainSuffixHint.
  ///
  /// In ru, this message translates to:
  /// **'например: google.com'**
  String get ruleTypeDomainSuffixHint;

  /// No description provided for @ruleTypeKeywordHint.
  ///
  /// In ru, this message translates to:
  /// **'например: youtube'**
  String get ruleTypeKeywordHint;

  /// No description provided for @ruleTypeRegexHint.
  ///
  /// In ru, this message translates to:
  /// **'например: ^ads\\d*\\.'**
  String get ruleTypeRegexHint;

  /// No description provided for @ruleTypeCidrHint.
  ///
  /// In ru, this message translates to:
  /// **'например: 192.168.1.0/24'**
  String get ruleTypeCidrHint;

  /// No description provided for @ruleTypeGeoipHint.
  ///
  /// In ru, this message translates to:
  /// **'например: ru, cn'**
  String get ruleTypeGeoipHint;

  /// No description provided for @ruleTypeAppHint.
  ///
  /// In ru, this message translates to:
  /// **'например: com.example.app'**
  String get ruleTypeAppHint;

  /// No description provided for @ruleActionProxy.
  ///
  /// In ru, this message translates to:
  /// **'Через туннель'**
  String get ruleActionProxy;

  /// No description provided for @ruleActionDirect.
  ///
  /// In ru, this message translates to:
  /// **'Напрямую'**
  String get ruleActionDirect;

  /// No description provided for @ruleActionBlock.
  ///
  /// In ru, this message translates to:
  /// **'Блокировать'**
  String get ruleActionBlock;

  /// No description provided for @ruleSourcePreset.
  ///
  /// In ru, this message translates to:
  /// **'набор'**
  String get ruleSourcePreset;

  /// No description provided for @ruleEnabledSemantic.
  ///
  /// In ru, this message translates to:
  /// **'Правило {pattern} активно'**
  String ruleEnabledSemantic(Object pattern);

  /// No description provided for @ruleDisabledSemantic.
  ///
  /// In ru, this message translates to:
  /// **'Правило {pattern} выключено'**
  String ruleDisabledSemantic(Object pattern);

  /// No description provided for @splitTooltipDeleteRule.
  ///
  /// In ru, this message translates to:
  /// **'Удалить правило'**
  String get splitTooltipDeleteRule;

  /// No description provided for @splitTooltipApplyPreset.
  ///
  /// In ru, this message translates to:
  /// **'Применить набор'**
  String get splitTooltipApplyPreset;

  /// No description provided for @splitTooltipRemovePreset.
  ///
  /// In ru, this message translates to:
  /// **'Убрать набор'**
  String get splitTooltipRemovePreset;

  /// No description provided for @presetDomainsSuffix.
  ///
  /// In ru, this message translates to:
  /// **'{count} дом.'**
  String presetDomainsSuffix(int count);

  /// No description provided for @presetRuDirectTitle.
  ///
  /// In ru, this message translates to:
  /// **'Российские сайты'**
  String get presetRuDirectTitle;

  /// No description provided for @presetRuDirectDescription.
  ///
  /// In ru, this message translates to:
  /// **'RU-ресурсы идут напрямую, в обход туннеля'**
  String get presetRuDirectDescription;

  /// No description provided for @presetBlockedProxyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Заблокированные ресурсы'**
  String get presetBlockedProxyTitle;

  /// No description provided for @presetBlockedProxyDescription.
  ///
  /// In ru, this message translates to:
  /// **'Через туннель всегда, независимо от страны'**
  String get presetBlockedProxyDescription;

  /// No description provided for @presetAdsBlockTitle.
  ///
  /// In ru, this message translates to:
  /// **'Реклама и трекеры'**
  String get presetAdsBlockTitle;

  /// No description provided for @presetAdsBlockDescription.
  ///
  /// In ru, this message translates to:
  /// **'Блокировка рекламных доменов'**
  String get presetAdsBlockDescription;

  /// No description provided for @presetSocialProxyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Социальные сети'**
  String get presetSocialProxyTitle;

  /// No description provided for @presetSocialProxyDescription.
  ///
  /// In ru, this message translates to:
  /// **'Соцсети всегда через туннель'**
  String get presetSocialProxyDescription;

  /// No description provided for @splitErrorLoadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить правила'**
  String get splitErrorLoadFailed;

  /// No description provided for @splitErrorSaveFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить правила'**
  String get splitErrorSaveFailed;

  /// No description provided for @splitErrorRuleNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Правило не найдено'**
  String get splitErrorRuleNotFound;

  /// No description provided for @splitErrorPresetUnknown.
  ///
  /// In ru, this message translates to:
  /// **'Неизвестный набор правил'**
  String get splitErrorPresetUnknown;

  /// No description provided for @splitErrorNoProviderRules.
  ///
  /// In ru, this message translates to:
  /// **'В подписке нет применимых правил'**
  String get splitErrorNoProviderRules;

  /// No description provided for @splitErrorLimitReached.
  ///
  /// In ru, this message translates to:
  /// **'Достигнут лимит правил ({limit})'**
  String splitErrorLimitReached(int limit);

  /// No description provided for @splitErrorPatternTooShort.
  ///
  /// In ru, this message translates to:
  /// **'Паттерн слишком короткий (минимум {min} символа)'**
  String splitErrorPatternTooShort(int min);

  /// No description provided for @splitErrorPatternTooLong.
  ///
  /// In ru, this message translates to:
  /// **'Паттерн слишком длинный (максимум {max} символов)'**
  String splitErrorPatternTooLong(int max);

  /// No description provided for @splitErrorPatternEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Паттерн пуст после нормализации'**
  String get splitErrorPatternEmpty;

  /// No description provided for @splitErrorDuplicate.
  ///
  /// In ru, this message translates to:
  /// **'Такое правило уже существует'**
  String get splitErrorDuplicate;

  /// No description provided for @splitErrorInvalidRegex.
  ///
  /// In ru, this message translates to:
  /// **'Некорректное регулярное выражение'**
  String get splitErrorInvalidRegex;

  /// No description provided for @splitErrorInvalidDomain.
  ///
  /// In ru, this message translates to:
  /// **'Ожидается домен, например vk.com'**
  String get splitErrorInvalidDomain;

  /// No description provided for @splitErrorInvalidKeyword.
  ///
  /// In ru, this message translates to:
  /// **'Ключевое слово: буквы, цифры, точки и дефисы'**
  String get splitErrorInvalidKeyword;

  /// No description provided for @splitErrorInvalidGeoip.
  ///
  /// In ru, this message translates to:
  /// **'Ожидается GeoIP-код, например ru'**
  String get splitErrorInvalidGeoip;

  /// No description provided for @splitErrorInvalidPackage.
  ///
  /// In ru, this message translates to:
  /// **'Ожидается имя пакета, например com.example.app'**
  String get splitErrorInvalidPackage;

  /// No description provided for @splitErrorInvalidCidr.
  ///
  /// In ru, this message translates to:
  /// **'Некорректный IP/CIDR (пример: 192.168.1.0/24)'**
  String get splitErrorInvalidCidr;

  /// No description provided for @splitErrorReloadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Правила сохранены, но применить их к активному соединению не удалось'**
  String get splitErrorReloadFailed;

  /// No description provided for @subTooltipRefresh.
  ///
  /// In ru, this message translates to:
  /// **'Обновить подписку'**
  String get subTooltipRefresh;

  /// No description provided for @subTooltipAdd.
  ///
  /// In ru, this message translates to:
  /// **'Добавить подписку'**
  String get subTooltipAdd;

  /// No description provided for @subSectionServers.
  ///
  /// In ru, this message translates to:
  /// **'Серверы'**
  String get subSectionServers;

  /// No description provided for @subEmptyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Подписка не добавлена'**
  String get subEmptyTitle;

  /// No description provided for @subEmptyHint.
  ///
  /// In ru, this message translates to:
  /// **'Получите ссылку у провайдера и добавьте её здесь'**
  String get subEmptyHint;

  /// No description provided for @subAddButton.
  ///
  /// In ru, this message translates to:
  /// **'Добавить подписку'**
  String get subAddButton;

  /// No description provided for @subDefaultTitle.
  ///
  /// In ru, this message translates to:
  /// **'Подписка'**
  String get subDefaultTitle;

  /// No description provided for @subCopied.
  ///
  /// In ru, this message translates to:
  /// **'Скопировано: {value}'**
  String subCopied(String value);

  /// No description provided for @subConnectingTo.
  ///
  /// In ru, this message translates to:
  /// **'Подключение к «{node}»…'**
  String subConnectingTo(String node);

  /// No description provided for @subConnectFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось подключиться к «{node}»'**
  String subConnectFailed(String node);

  /// No description provided for @subProviderRulesApplied.
  ///
  /// In ru, this message translates to:
  /// **'Правила провайдера применены ({count})'**
  String subProviderRulesApplied(int count);

  /// No description provided for @subDialogAddTitle.
  ///
  /// In ru, this message translates to:
  /// **'Добавить подписку'**
  String get subDialogAddTitle;

  /// No description provided for @subDialogHint.
  ///
  /// In ru, this message translates to:
  /// **'Вставьте ссылку от провайдера. QR-сканирование появится позже.'**
  String get subDialogHint;

  /// No description provided for @subDialogFieldLabel.
  ///
  /// In ru, this message translates to:
  /// **'URL подписки'**
  String get subDialogFieldLabel;

  /// No description provided for @subDialogFieldHint.
  ///
  /// In ru, this message translates to:
  /// **'https://provider.example/sub'**
  String get subDialogFieldHint;

  /// No description provided for @subDialogLoad.
  ///
  /// In ru, this message translates to:
  /// **'Загрузить'**
  String get subDialogLoad;

  /// No description provided for @subUrlEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Введите URL подписки'**
  String get subUrlEmpty;

  /// No description provided for @subUrlScheme.
  ///
  /// In ru, this message translates to:
  /// **'Поддерживаются https:// и vpn:// ссылки'**
  String get subUrlScheme;

  /// No description provided for @accountPlanNotSpecified.
  ///
  /// In ru, this message translates to:
  /// **'Тариф не указан'**
  String get accountPlanNotSpecified;

  /// No description provided for @accountExpiredLabel.
  ///
  /// In ru, this message translates to:
  /// **'истёк'**
  String get accountExpiredLabel;

  /// No description provided for @accountDevices.
  ///
  /// In ru, this message translates to:
  /// **'Устройства: {used} из {max}'**
  String accountDevices(int used, int max);

  /// No description provided for @accountBalance.
  ///
  /// In ru, this message translates to:
  /// **'Баланс: {value}'**
  String accountBalance(String value);

  /// No description provided for @accountValidUntil.
  ///
  /// In ru, this message translates to:
  /// **'Действует до {date}'**
  String accountValidUntil(String date);

  /// No description provided for @trafficUnlimited.
  ///
  /// In ru, this message translates to:
  /// **'безлимит'**
  String get trafficUnlimited;

  /// No description provided for @trafficOutOf.
  ///
  /// In ru, this message translates to:
  /// **'из'**
  String get trafficOutOf;

  /// No description provided for @unitBytes.
  ///
  /// In ru, this message translates to:
  /// **'Б'**
  String get unitBytes;

  /// No description provided for @unitMegabytes.
  ///
  /// In ru, this message translates to:
  /// **'МБ'**
  String get unitMegabytes;

  /// No description provided for @unitGigabytes.
  ///
  /// In ru, this message translates to:
  /// **'ГБ'**
  String get unitGigabytes;

  /// No description provided for @providerRulesTitle.
  ///
  /// In ru, this message translates to:
  /// **'Правила провайдера: {count}'**
  String providerRulesTitle(int count);

  /// No description provided for @providerRulesSubtitle.
  ///
  /// In ru, this message translates to:
  /// **'Раздельное туннелирование из подписки'**
  String get providerRulesSubtitle;

  /// No description provided for @nodeConnect.
  ///
  /// In ru, this message translates to:
  /// **'Подключить'**
  String get nodeConnect;

  /// No description provided for @subTooltipHideAnnouncement.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть объявление'**
  String get subTooltipHideAnnouncement;

  /// No description provided for @subTooltipCopy.
  ///
  /// In ru, this message translates to:
  /// **'Копировать'**
  String get subTooltipCopy;

  /// No description provided for @subErrorEnterUrl.
  ///
  /// In ru, this message translates to:
  /// **'Введите URL подписки'**
  String get subErrorEnterUrl;

  /// No description provided for @subErrorNoUpdateUrl.
  ///
  /// In ru, this message translates to:
  /// **'URL обновления не задан'**
  String get subErrorNoUpdateUrl;

  /// No description provided for @subErrorNetwork.
  ///
  /// In ru, this message translates to:
  /// **'Сеть недоступна или сервер подписки не ответил'**
  String get subErrorNetwork;

  /// No description provided for @subErrorLoadFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить подписку'**
  String get subErrorLoadFailed;

  /// No description provided for @subErrorBroken.
  ///
  /// In ru, this message translates to:
  /// **'Сохранённая подписка повреждена'**
  String get subErrorBroken;

  /// No description provided for @subErrorSaveFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить подписку'**
  String get subErrorSaveFailed;

  /// No description provided for @subErrorNoKeys.
  ///
  /// In ru, this message translates to:
  /// **'Ключи для vpn://-подписки не заданы — настройте их в «Настройках»'**
  String get subErrorNoKeys;

  /// No description provided for @subErrorInvalidKey.
  ///
  /// In ru, this message translates to:
  /// **'Некорректный ключ подписки (проверьте Base64 и длину)'**
  String get subErrorInvalidKey;

  /// No description provided for @subErrorExpired.
  ///
  /// In ru, this message translates to:
  /// **'Подписка истекла'**
  String get subErrorExpired;

  /// No description provided for @subErrorOutdatedVersion.
  ///
  /// In ru, this message translates to:
  /// **'Устаревшая версия формата подписки'**
  String get subErrorOutdatedVersion;

  /// No description provided for @subErrorNoNodes.
  ///
  /// In ru, this message translates to:
  /// **'Нет доступных серверов'**
  String get subErrorNoNodes;

  /// No description provided for @subErrorNoTcpChannel.
  ///
  /// In ru, this message translates to:
  /// **'У одного из узлов нет TCP-канала (правило надёжности)'**
  String get subErrorNoTcpChannel;

  /// No description provided for @subErrorInvalid.
  ///
  /// In ru, this message translates to:
  /// **'Некорректная подписка'**
  String get subErrorInvalid;

  /// No description provided for @subErrorSignature.
  ///
  /// In ru, this message translates to:
  /// **'Подпись подписки невалидна'**
  String get subErrorSignature;

  /// No description provided for @diagnosticsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Диагностика'**
  String get diagnosticsTitle;

  /// No description provided for @realDelayTitle.
  ///
  /// In ru, this message translates to:
  /// **'Real-Delay (HTTP 204)'**
  String get realDelayTitle;

  /// No description provided for @realDelayMeasure.
  ///
  /// In ru, this message translates to:
  /// **'Измерить'**
  String get realDelayMeasure;

  /// No description provided for @realDelayValue.
  ///
  /// In ru, this message translates to:
  /// **'{ms} мс'**
  String realDelayValue(int ms);

  /// No description provided for @realDelayFailed.
  ///
  /// In ru, this message translates to:
  /// **'Зонд недоступен'**
  String get realDelayFailed;

  /// No description provided for @realDelayNoTunnel.
  ///
  /// In ru, this message translates to:
  /// **'Подключитесь, чтобы измерить'**
  String get realDelayNoTunnel;

  /// No description provided for @telemetrySection.
  ///
  /// In ru, this message translates to:
  /// **'Телеметрия туннеля'**
  String get telemetrySection;

  /// No description provided for @telemetryState.
  ///
  /// In ru, this message translates to:
  /// **'Состояние'**
  String get telemetryState;

  /// No description provided for @telemetryProtocol.
  ///
  /// In ru, this message translates to:
  /// **'Протокол'**
  String get telemetryProtocol;

  /// No description provided for @telemetryTunnelMode.
  ///
  /// In ru, this message translates to:
  /// **'Режим ядра'**
  String get telemetryTunnelMode;

  /// No description provided for @telemetryLatency.
  ///
  /// In ru, this message translates to:
  /// **'Задержка (ping)'**
  String get telemetryLatency;

  /// No description provided for @telemetryLatencyValue.
  ///
  /// In ru, this message translates to:
  /// **'{ms} мс'**
  String telemetryLatencyValue(int ms);

  /// No description provided for @telemetryDownload.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка'**
  String get telemetryDownload;

  /// No description provided for @telemetryUpload.
  ///
  /// In ru, this message translates to:
  /// **'Отдача'**
  String get telemetryUpload;

  /// No description provided for @telemetryDuration.
  ///
  /// In ru, this message translates to:
  /// **'Время сессии'**
  String get telemetryDuration;

  /// No description provided for @telemetrySplitRules.
  ///
  /// In ru, this message translates to:
  /// **'Правила маршрутизации'**
  String get telemetrySplitRules;

  /// No description provided for @telemetrySplitRulesValue.
  ///
  /// In ru, this message translates to:
  /// **'{active} активных из {total}'**
  String telemetrySplitRulesValue(int active, int total);

  /// No description provided for @telemetrySubscription.
  ///
  /// In ru, this message translates to:
  /// **'Подписка'**
  String get telemetrySubscription;

  /// No description provided for @telemetrySubscriptionValue.
  ///
  /// In ru, this message translates to:
  /// **'{provider} · {nodes} узл.'**
  String telemetrySubscriptionValue(String provider, int nodes);

  /// No description provided for @telemetryNoValue.
  ///
  /// In ru, this message translates to:
  /// **'—'**
  String get telemetryNoValue;

  /// No description provided for @devMetaTitle.
  ///
  /// In ru, this message translates to:
  /// **'developer_meta'**
  String get devMetaTitle;

  /// No description provided for @devMetaGenerated.
  ///
  /// In ru, this message translates to:
  /// **'Генерация конфига: {ms} мс'**
  String devMetaGenerated(int ms);

  /// No description provided for @devMetaBackend.
  ///
  /// In ru, this message translates to:
  /// **'Бэкенд: {node}'**
  String devMetaBackend(String node);

  /// No description provided for @devMetaAbGroup.
  ///
  /// In ru, this message translates to:
  /// **'A/B-группа: {group}'**
  String devMetaAbGroup(String group);

  /// No description provided for @devMetaRecommendedMode.
  ///
  /// In ru, this message translates to:
  /// **'Рекомендованный режим: {mode}'**
  String devMetaRecommendedMode(String mode);

  /// No description provided for @devMetaWebhook.
  ///
  /// In ru, this message translates to:
  /// **'Диагностический webhook: задан'**
  String get devMetaWebhook;

  /// No description provided for @devMetaEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Провайдер не передал developer_meta'**
  String get devMetaEmpty;

  /// No description provided for @reportSection.
  ///
  /// In ru, this message translates to:
  /// **'Диагностический отчёт'**
  String get reportSection;

  /// No description provided for @reportRefresh.
  ///
  /// In ru, this message translates to:
  /// **'Обновить'**
  String get reportRefresh;

  /// No description provided for @reportCopy.
  ///
  /// In ru, this message translates to:
  /// **'Скопировать'**
  String get reportCopy;

  /// No description provided for @reportShare.
  ///
  /// In ru, this message translates to:
  /// **'Поделиться'**
  String get reportShare;

  /// No description provided for @reportCopied.
  ///
  /// In ru, this message translates to:
  /// **'Отчёт скопирован'**
  String get reportCopied;

  /// No description provided for @reportNote.
  ///
  /// In ru, this message translates to:
  /// **'Отчёт не содержит адресов серверов и другой приватной информации'**
  String get reportNote;

  /// No description provided for @tunnelModeReal.
  ///
  /// In ru, this message translates to:
  /// **'реальный (sing-box)'**
  String get tunnelModeReal;

  /// No description provided for @tunnelModeMock.
  ///
  /// In ru, this message translates to:
  /// **'мок (разработка)'**
  String get tunnelModeMock;

  /// No description provided for @reportLineGenerated.
  ///
  /// In ru, this message translates to:
  /// **'Отчёт от {date}'**
  String reportLineGenerated(String date);

  /// No description provided for @reportLineApp.
  ///
  /// In ru, this message translates to:
  /// **'Приложение: Fetu {version} (режим: {mode})'**
  String reportLineApp(String version, String mode);

  /// No description provided for @reportLineTunnel.
  ///
  /// In ru, this message translates to:
  /// **'Туннель: {state}, протокол: {protocol}'**
  String reportLineTunnel(String state, String protocol);

  /// No description provided for @reportLineTunnelNoProtocol.
  ///
  /// In ru, this message translates to:
  /// **'Туннель: {state}'**
  String reportLineTunnelNoProtocol(String state);

  /// No description provided for @reportLineMetrics.
  ///
  /// In ru, this message translates to:
  /// **'Метрики: ↓ {down} / ↑ {up}, ping {ping} мс'**
  String reportLineMetrics(String down, String up, String ping);

  /// No description provided for @reportLineRealDelay.
  ///
  /// In ru, this message translates to:
  /// **'Real-Delay 204: {value} мс'**
  String reportLineRealDelay(int value);

  /// No description provided for @reportLineRealDelayMissing.
  ///
  /// In ru, this message translates to:
  /// **'Real-Delay 204: не измерялся'**
  String get reportLineRealDelayMissing;

  /// No description provided for @reportLineRules.
  ///
  /// In ru, this message translates to:
  /// **'Маршрутизация: {active} активных правил из {total}'**
  String reportLineRules(int active, int total);

  /// No description provided for @reportLineSubscription.
  ///
  /// In ru, this message translates to:
  /// **'Подписка: {provider}, узлов: {nodes}'**
  String reportLineSubscription(String provider, int nodes);

  /// No description provided for @reportLineSubscriptionExpires.
  ///
  /// In ru, this message translates to:
  /// **'Подписка действительна до: {date}'**
  String reportLineSubscriptionExpires(String date);

  /// No description provided for @reportLineNoSubscription.
  ///
  /// In ru, this message translates to:
  /// **'Подписка: не добавлена'**
  String get reportLineNoSubscription;

  /// No description provided for @reportLineCore.
  ///
  /// In ru, this message translates to:
  /// **'Ядро: {mode}'**
  String reportLineCore(String mode);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
