import 'package:fetu/app.dart';
import 'package:fetu/core/storage/key_value_storage.dart';
import 'package:fetu/features/connection/controllers/connection_controller.dart';
import 'package:fetu/features/connection/widgets/connection_button.dart';
import 'package:fetu/features/settings/controllers/settings_controller.dart';
import 'package:fetu/features/settings/models/ui_experience_mode.dart';
import 'package:fetu/features/subscription/controllers/subscription_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'helpers/subscription_fixtures.dart';
import 'helpers/test_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Инициализируем тестовые зависимости (без нативных плагинов)
    await setupTestDependencies(
      fetcher: (_) async => asJson(minimalSubscription()),
    );
  });

  tearDownAll(() {
    // Очищаем GetIt после тестов
    GetIt.instance.reset();
  });

  testWidgets('Первый запуск: экран выбора режима → выбор → HomeScreen', (
    tester,
  ) async {
    // Локаль теста — русский (шаблон локализации):
    // WidgetsApp разрешает язык по списку locales платформенного диспатчера.
    TestWidgetsFlutterBinding.instance.platformDispatcher.localesTestValue =
        const [
      Locale('ru', 'RU'),
    ];

    await tester.pumpWidget(const FetuApp());
    await tester.pumpAndSettle();

    // До выбора режима показан экран выбора (правило 33).
    expect(find.text('Выберите режим'), findsOneWidget);

    // Выбираем простой режим.
    await tester.tap(find.text('Простой режим'));
    await tester.pumpAndSettle();

    // После выбора открывается главный экран.
    expect(find.text('Fetu'), findsOneWidget);
    expect(find.text('Отключено'), findsOneWidget);

    // Режим сохранён в контроллере и хранилище.
    final settings = GetIt.instance<SettingsController>();
    expect(settings.isModeSelected, isTrue);
    expect(settings.mode, UiExperienceMode.simple);
    expect(
      await GetIt.instance<KeyValueStorage>()
          .read(key: 'fetu.settings.ui_experience_mode'),
      'simple',
    );

    const channel = MethodChannel('com.fetu.app/method_channel');
    final messenger = tester.binding.defaultBinaryMessenger;
    final calls = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      if (call.method == 'connect') {
        throw PlatformException(code: 'VPN_CORE_UNAVAILABLE');
      }
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));

    // Нажатие основной кнопки без подписки сразу открывает форму.
    await tester.tap(find.byType(ConnectionButton));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(calls, isEmpty);

    await tester.enterText(find.byType(TextField), 'invalid-link');
    await tester.tap(find.text('Загрузить'));
    await tester.pumpAndSettle();
    expect(
      find.text('Поддерживаются https:// и vpn:// ссылки'),
      findsOneWidget,
    );
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Отключено'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.runAsync(() async {
      final controller = GetIt.instance<SubscriptionController>();
      await controller.addFromUrl('https://provider.example/sub\u0000\u0000');
    });
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(
      GetIt.instance<SubscriptionController>().subscriptionUrl,
      'https://provider.example/sub',
    );
    expect(GetIt.instance<SubscriptionController>().nodes, hasLength(1));
    expect(calls, isEmpty);

    final connection = GetIt.instance<ConnectionController>();
    final node = GetIt.instance<SubscriptionController>().nodes.single;
    await connection.connectFromSelection(node.toServerNode);
    await tester.pumpAndSettle();
    expect(calls, ['connect']);
    expect(find.text('В этой сборке отсутствует сетевое ядро'), findsOneWidget);
    expect(tester.takeException(), isNull);
    connection.dispose();
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
  });
}
