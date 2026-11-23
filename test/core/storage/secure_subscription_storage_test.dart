import 'dart:async';

import 'package:fetu/core/constants/subscription_constants.dart';
import 'package:fetu/core/storage/secure_subscription_storage.dart';
import 'package:fetu/core/storage/serialized_secure_storage.dart';
import 'package:fetu/features/subscription/controllers/subscription_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_secure_storage.dart';
import '../../helpers/subscription_fixtures.dart';
import '../../helpers/test_storage.dart';

void main() {
  const key = SubscriptionConstants.storageKey;
  const old = 'legacy record';
  const updated = 'secure record';

  test('перенос и повторная компактация после сбоя', () async {
    final legacy = TestStorage();
    final secure = FakeSecureStorage();
    var compactions = 0;
    final storage = SecureSubscriptionStorage(
      legacy: legacy,
      secure: SerializedSecureStorage(secure),
      compactLegacy: () async {
        if (++compactions == 1) throw StateError('compaction failed');
      },
    );
    await legacy.write(key: key, value: old);
    expect(await storage.read(key: key), old);
    expect(await legacy.read(key: key), isNull);
    expect(await secure.read(key: key), old);
    expect(await storage.read(key: key), old);
    expect(compactions, 2);
    await storage.write(key: key, value: updated);
    expect(await legacy.read(key: key), isNull);
    expect(await secure.read(key: key), updated);
    await storage.delete(key: key);
    expect(await storage.read(key: key), isNull);
  });

  test('общая очередь не теряет операции после сбоя записи', () async {
    final secure = FakeSecureStorage();
    final queue = SerializedSecureStorage(secure);
    final gate = Completer<void>();
    final events = <String>[];
    final first = queue.run((_) async {
      events.add('first started');
      await gate.future;
      events.add('first finished');
      throw StateError('first write failed');
    });
    final failure = expectLater(first, throwsStateError);
    final second = queue.run((backend) async {
      events.add('second started');
      await backend.write(key: key, value: updated);
    });
    await Future<void>.value();
    expect(events, ['first started']);
    gate.complete();
    await failure;
    await second;
    expect(events, ['first started', 'first finished', 'second started']);
    expect(await queue.read(key: key), updated);
  });

  test('при отказе чтения временная подписка не перезаписывает старую',
      () async {
    final legacy = TestStorage();
    final backend = ThrowingSecureStorage();
    await legacy.write(key: key, value: old);
    final controller = SubscriptionController(
      storage: SecureSubscriptionStorage(
        legacy: legacy,
        secure: SerializedSecureStorage(backend),
      ),
      fetcher: (_) async => asJson(minimalSubscription()),
    );
    await controller.initialize();
    expect(controller.restoreFailed, isTrue);
    expect(await legacy.read(key: key), old);
    await controller.addForSession('https://provider.example/sub');
    expect(controller.nodes, hasLength(1));
    expect(controller.sessionOnly, isTrue);
    await controller.refresh();
    expect(controller.sessionOnly, isTrue);
    expect(backend.length, isZero);
    await controller.remove();
    expect(await legacy.read(key: key), old);
    controller.dispose();
  });

  test('SerializedSecureStorage не зависает бесконечно при таймауте плагина',
      () async {
    final queue = SerializedSecureStorage(
      FakeSecureStorage(),
      operationTimeout: const Duration(milliseconds: 50),
    );
    final never = Completer<String?>();
    await expectLater(
      queue.run((_) => never.future),
      throwsA(isA<TimeoutException>()),
    );
  });
}
