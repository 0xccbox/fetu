import 'package:fetu/features/subscription/controllers/subscription_controller.dart';
import 'package:fetu/features/subscription/models/subscription.dart';
import 'package:fetu/features/subscription/services/subscription_updater.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/subscription_fixtures.dart';
import '../../../helpers/test_storage.dart';

void main() {
  group('SubscriptionUpdater', () {
    test('планирует интервал по update.interval и сохраняет LKG при сбое',
        () async {
      final storage = TestStorage();
      await storage.init();
      var failFetch = false;
      var subName = 'Initial VPN';

      final controller = SubscriptionController(
        storage: storage,
        enableAutoUpdate: true,
        fetcher: (_) async {
          if (failFetch) {
            throw StateError('Network down');
          }
          return asJson({
            ...minimalSubscription(),
            'name': subName,
            'update': {
              'url': 'https://provider.example/sub',
              'interval': 600,
            },
          });
        },
      );
      addTearDown(controller.dispose);

      await controller.addFromUrl('https://provider.example/sub');
      expect(controller.subscription?.name, 'Initial VPN');
      expect(
        controller.updater?.activeInterval,
        const Duration(seconds: 600),
      );

      // Сбой обновления -> остаётся LKG-подписка.
      failFetch = true;
      final failedOk = await controller.updater!.triggerNow();
      expect(failedOk, isFalse);
      expect(controller.updater?.status, SubscriptionUpdateStatus.fallbackLkg);
      expect(controller.subscription?.name, 'Initial VPN');

      // Восстановление сети -> подписка обновляется.
      failFetch = false;
      subName = 'Updated VPN';
      final ok = await controller.updater!.triggerNow();
      expect(ok, isTrue);
      expect(controller.updater?.status, SubscriptionUpdateStatus.succeeded);
      expect(controller.subscription?.name, 'Updated VPN');
    });

    test('останавливает таймер при remove() и отсутствии update.url', () async {
      final updater = SubscriptionUpdater(onRefresh: () async {});
      addTearDown(updater.dispose);

      updater.configure(
        Subscription.fromJson({
          ...minimalSubscription(),
          'update': const {
            'url': 'https://provider.example/sub',
            'interval': 60,
          },
        }),
      );
      // Клэмпится к минимуму (300с).
      expect(updater.activeInterval, const Duration(seconds: 300));

      updater.configure(Subscription.fromJson(minimalSubscription()));
      expect(updater.activeInterval, isNull);
    });

    test(
        'remove() во время загрузки не даёт устаревшему fetch перезаписать состояние',
        () async {
      final storage = TestStorage();
      await storage.init();

      final controller = SubscriptionController(
        storage: storage,
        enableAutoUpdate: true,
        fetcher: (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return asJson({
            ...minimalSubscription(),
            'update': {
              'url': 'https://provider.example/sub',
              'interval': 600,
            },
          });
        },
      );
      addTearDown(controller.dispose);

      final future = controller.addFromUrl('https://provider.example/sub');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await controller.remove();
      await future;

      expect(controller.subscription, isNull);
      expect(controller.updater?.activeInterval, isNull);
    });
  });
}
