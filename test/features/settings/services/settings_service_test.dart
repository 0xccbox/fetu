import 'package:fetu/features/settings/models/ui_experience_mode.dart';
import 'package:fetu/features/settings/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_storage.dart';

void main() {
  group('SettingsService', () {
    test('без сохранённого режима loadMode возвращает null', () async {
      final service = SettingsService(storage: TestStorage());

      expect(await service.loadMode(), isNull);
    });

    test('saveMode → loadMode: round-trip', () async {
      final storage = TestStorage();
      final service = SettingsService(storage: storage);

      await service.saveMode(UiExperienceMode.advanced);
      expect(await service.loadMode(), UiExperienceMode.advanced);

      await service.saveMode(UiExperienceMode.simple);
      expect(await service.loadMode(), UiExperienceMode.simple);
    });

    test('битая запись хранилища трактуется как «не выбран»', () async {
      final storage = TestStorage();
      await storage.write(key: 'fetu.settings.ui_experience_mode', value: '42');
      final service = SettingsService(storage: storage);

      expect(await service.loadMode(), isNull);
    });

    test('хранилище без ошибок при записи — ключ верный', () async {
      final storage = TestStorage();
      final service = SettingsService(storage: storage);

      await service.saveMode(UiExperienceMode.simple);

      expect(
        await storage.read(key: 'fetu.settings.ui_experience_mode'),
        'simple',
      );
    });
  });
}
