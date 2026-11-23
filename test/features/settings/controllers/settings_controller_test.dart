import 'package:fetu/features/settings/controllers/settings_controller.dart';
import 'package:fetu/features/settings/models/subscription_keys.dart';
import 'package:fetu/features/settings/models/ui_experience_mode.dart';
import 'package:fetu/features/settings/services/settings_service.dart';
import 'package:fetu/features/settings/services/subscription_key_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_secure_storage.dart';
import '../../../helpers/test_storage.dart';

void main() {
  group('SettingsController', () {
    test('до выбора: isModeSelected = false, режим по умолчанию simple',
        () async {
      final controller = SettingsController(
        service: SettingsService(storage: TestStorage()),
      );
      await controller.initialize();

      expect(controller.isModeSelected, isFalse);
      expect(controller.mode, UiExperienceMode.simple);
    });

    test('setMode сохраняет режим и уведомляет слушателей', () async {
      final storage = TestStorage();
      final controller = SettingsController(
        service: SettingsService(storage: storage),
      );
      await controller.initialize();

      var notified = 0;
      controller.addListener(() => notified++);

      await controller.setMode(UiExperienceMode.advanced);

      expect(controller.isModeSelected, isTrue);
      expect(controller.mode, UiExperienceMode.advanced);
      expect(notified, greaterThan(0));
      expect(
        await storage.read(key: 'fetu.settings.ui_experience_mode'),
        'advanced',
      );
    });

    test('повторная инициализация восстанавливает режим', () async {
      final storage = TestStorage();
      final first = SettingsController(
        service: SettingsService(storage: storage),
      );
      await first.setMode(UiExperienceMode.advanced);

      final second = SettingsController(
        service: SettingsService(storage: storage),
      );
      await second.initialize();

      expect(second.isModeSelected, isTrue);
      expect(second.mode, UiExperienceMode.advanced);
    });

    test('ключи: валидный Base64 сохраняется, мусор отклоняется', () async {
      final controller = SettingsController(
        service: SettingsService(storage: TestStorage()),
        keyStore: SubscriptionKeyStore(storage: FakeSecureStorage()),
      );

      final saved = await controller.saveKeys(
        const SubscriptionKeys(
          verifyKey: 'dmVyaWZ5LWtleS0zMi1ieXRlcy1hYmNkZWY=',
          decryptKey: 'ZGVjcnlwdC1rZXktMzItYnl0ZXMtYWJjZGVm',
        ),
      );
      expect(saved, isTrue);

      final invalid = await controller.saveKeys(
        const SubscriptionKeys(verifyKey: 'не-base64!!!'),
      );
      expect(invalid, isFalse);
      expect(controller.errorMessage, isNotNull);
    });

    test('ключи: clear очищает хранилище', () async {
      final controller = SettingsController(
        service: SettingsService(storage: TestStorage()),
        keyStore: SubscriptionKeyStore(storage: FakeSecureStorage()),
      );

      await controller.saveKeys(
        const SubscriptionKeys(verifyKey: 'dmVyaWZ5a2V5'),
      );
      await controller.clearKeys();

      expect((await controller.loadKeys()).isEmpty, isTrue);
    });

    test('без keyStore: saveKeys проходит, loadKeys — пусто', () async {
      final controller = SettingsController(
        service: SettingsService(storage: TestStorage()),
        keyStore: null,
      );

      expect((await controller.loadKeys()).isEmpty, isTrue);
      expect(
        await controller.saveKeys(const SubscriptionKeys()),
        isTrue,
      );
    });
  });
}
