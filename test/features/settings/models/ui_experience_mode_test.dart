import 'package:fetu/features/settings/models/ui_experience_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UiExperienceMode', () {
    test('fromStorage разбирает корректные значения', () {
      expect(
        UiExperienceMode.fromStorage('simple'),
        UiExperienceMode.simple,
      );
      expect(
        UiExperienceMode.fromStorage('advanced'),
        UiExperienceMode.advanced,
      );
    });

    test('fromStorage: null и мусор → режим не выбран', () {
      expect(UiExperienceMode.fromStorage(null), isNull);
      expect(UiExperienceMode.fromStorage(''), isNull);
      expect(UiExperienceMode.fromStorage('Pro'), isNull);
      expect(UiExperienceMode.fromStorage('SIMPLE'), isNull);
    });

    test('storageName — стабильные значения для хранилища', () {
      expect(UiExperienceMode.simple.storageName, 'simple');
      expect(UiExperienceMode.advanced.storageName, 'advanced');
    });

    test('round-trip: storageName → fromStorage', () {
      for (final mode in UiExperienceMode.values) {
        expect(
          UiExperienceMode.fromStorage(mode.storageName),
          mode,
        );
      }
    });
  });
}
