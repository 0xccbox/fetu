import 'package:fetu/l10n/app_localizations.dart';
import 'package:fetu/l10n/app_localizations_en.dart';
import 'package:fetu/l10n/app_localizations_ru.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLocalizations (RU/EN паритет, правило 14/28)', () {
    final ru = AppLocalizationsRu();
    final en = AppLocalizationsEn();

    test('все ключевые группы строк непустые в обеих локалях', () {
      // Представители каждой группы ключей arb: статусы, режимы,
      // настройки, failover, ошибки, split/subscription, диагностика.
      final ruKeys = [
        ru.statusConnected,
        ru.modeSimpleDescription,
        ru.settingsKeysHint,
        ru.uxTermSmartAccess,
        ru.failoverTitle,
        ru.connectionErrorConnectFailed,
        ru.splitTitle,
        ru.subErrorNetwork,
        ru.realDelayTitle,
        ru.reportLineNoSubscription,
      ];
      final enKeys = [
        en.statusConnected,
        en.modeSimpleDescription,
        en.settingsKeysHint,
        en.uxTermSmartAccess,
        en.failoverTitle,
        en.connectionErrorConnectFailed,
        en.splitTitle,
        en.subErrorNetwork,
        en.realDelayTitle,
        en.reportLineNoSubscription,
      ];
      for (final value in ruKeys) {
        expect(value, isNotEmpty);
      }
      for (final value in enKeys) {
        expect(value, isNotEmpty);
      }
    });

    test('ключевые строки различаются между RU и EN', () {
      expect(ru.statusConnected, isNot(equals(en.statusConnected)));
      expect(ru.splitTitle, isNot(equals(en.splitTitle)));
      expect(ru.settingsTitle, isNot(equals(en.settingsTitle)));
    });

    test('локали корректно инициализируются', () {
      expect(AppLocalizationsRu().localeName, 'ru');
      expect(AppLocalizationsEn().localeName, 'en');
    });

    test('поддерживаемые локали: ru и en', () {
      expect(AppLocalizations.supportedLocales, contains(const Locale('ru')));
      expect(AppLocalizations.supportedLocales, contains(const Locale('en')));
      expect(AppLocalizations.supportedLocales, hasLength(2));
    });

    test('параметризованные строки подставляют значения', () {
      expect(ru.accountDevices(2, 5), contains('2'));
      expect(ru.accountDevices(2, 5), contains('5'));
      expect(en.presetDomainsSuffix(10), contains('10'));
      expect(ru.failoverSwitchedTo('Reality'), contains('Reality'));
      expect(ru.reportLineApp('1.0.0', 'простой'), contains('1.0.0'));
    });

    test('делегат поддерживает ru и en, en-US сворачивается к en', () async {
      const delegate = AppLocalizations.delegate;

      expect(delegate.isSupported(const Locale('ru')), isTrue);
      expect(delegate.isSupported(const Locale('en')), isTrue);
      expect(delegate.isSupported(const Locale('fr')), isFalse);

      final loaded = await delegate.load(const Locale('en', 'US'));
      expect(loaded.localeName, 'en');
    });
  });
}
