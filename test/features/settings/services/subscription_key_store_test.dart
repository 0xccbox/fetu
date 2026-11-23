import 'package:fetu/features/settings/models/subscription_keys.dart';
import 'package:fetu/features/settings/services/subscription_key_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_secure_storage.dart';

void main() {
  group('SubscriptionKeyStore', () {
    test('save → load: round-trip пары ключей', () async {
      final store = SubscriptionKeyStore(storage: FakeSecureStorage());

      await store.save(
        const SubscriptionKeys(
          verifyKey: 'dmVyaWZ5a2V5',
          decryptKey: 'ZGVjcnlwdGtleQ==',
        ),
      );

      final keys = await store.load();
      expect(keys.verifyKey, 'dmVyaWZ5a2V5');
      expect(keys.decryptKey, 'ZGVjcnlwdGtleQ==');
      expect(keys.isEmpty, isFalse);
    });

    test('пустые ключи: save удаляет записи, isEmpty = true', () async {
      final fake = FakeSecureStorage();
      final store = SubscriptionKeyStore(storage: fake);

      await store.save(
        const SubscriptionKeys(verifyKey: 'dmVyaWZ5a2V5'),
      );
      await store.save(const SubscriptionKeys());

      final keys = await store.load();
      expect(keys.isEmpty, isTrue);
      expect(fake.length, isZero);
    });

    test('clear удаляет оба ключа', () async {
      final store = SubscriptionKeyStore(storage: FakeSecureStorage());

      await store.save(
        const SubscriptionKeys(verifyKey: 'a', decryptKey: 'b'),
      );
      await store.clear();

      expect((await store.load()).isEmpty, isTrue);
    });

    test('сбой платформенного хранилища не роняет load', () async {
      final store = SubscriptionKeyStore(
        storage: ThrowingSecureStorage(),
      );

      final keys = await store.load();
      expect(keys.isEmpty, isTrue);
    });
  });
}
