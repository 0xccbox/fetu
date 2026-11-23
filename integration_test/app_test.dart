import 'dart:io';
import 'dart:ui' as ui;

import 'package:fetu/app.dart';
import 'package:fetu/core/platform/vpn_method_channel.dart';
import 'package:fetu/core/storage/secure_subscription_storage.dart';
import 'package:fetu/core/storage/serialized_secure_storage.dart';
import 'package:fetu/features/connection/controllers/connection_controller.dart';
import 'package:fetu/features/connection/widgets/compact_connect_button.dart';
import 'package:fetu/features/connection/widgets/connection_button.dart';
import 'package:fetu/features/settings/controllers/settings_controller.dart';
import 'package:fetu/features/settings/models/ui_experience_mode.dart';
import 'package:fetu/features/subscription/controllers/subscription_controller.dart';
import 'package:fetu/features/subscription/widgets/server_selection_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import '../test/helpers/subscription_fixtures.dart';
import '../test/helpers/test_setup.dart';
import '../test/helpers/test_storage.dart';

const _fixtureUrl = 'https://provider.example/sub';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Android: прежняя запись переносится в защищённое хранилище',
    (_) async {
      const key = 'fetu.integration.storage.probe';
      const fixture = 'disposable synthetic subscription';
      final legacy = TestStorage();
      final secure = SerializedSecureStorage(
        const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        ),
      );
      final storage = SecureSubscriptionStorage(legacy: legacy, secure: secure);
      addTearDown(() => storage.delete(key: key));
      await legacy.write(key: key, value: fixture);
      expect(await storage.read(key: key), fixture);
      expect(await legacy.read(key: key), isNull);
      expect(await secure.read(key: key), fixture);
    },
    skip: !Platform.isAndroid,
  );

  testWidgets('Android: запуск, форма и список V4, отказ без ядра', (
    tester,
  ) async {
    final frame = GlobalKey();
    tester.platformDispatcher.localesTestValue = const [Locale('ru')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    // Реальный нативный канал, но подписка и настройки только в памяти.
    await setupTestDependencies(
      fetcher: (url) async {
        expect(url, _fixtureUrl);
        return asJson(_previewFixture());
      },
    );
    final services = GetIt.instance;
    final connection = services<ConnectionController>();
    addTearDown(() async {
      connection.dispose();
      await services.reset();
    });
    await services<SettingsController>().setMode(UiExperienceMode.simple);
    await tester.pumpWidget(
      RepaintBoundary(key: frame, child: const FetuApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Настройте подключение'), findsOneWidget);
    await tester.tap(find.byType(ConnectionButton).hitTestable());
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    await _capture(frame, 'home-empty');

    await tester.tap(find.byType(ConnectionButton).hitTestable());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), _fixtureUrl);
    await tester.tap(find.text('Загрузить'));
    await tester.pumpAndSettle();
    expect(services<SubscriptionController>().nodes, hasLength(5));
    final list = find.byType(ServerSelectionTile).hitTestable();
    await tester.tap(find.byType(ConnectionButton).hitTestable());
    await tester.pumpAndSettle();
    expect(list, findsWidgets);
    await tester.tap(list.first);
    await tester.pumpAndSettle();
    expect(tester.widget<ServerSelectionTile>(list.first).selected, isTrue);
    await _capture(frame, 'server-list');

    final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
    scroll.position.jumpTo(0);
    await tester.pumpAndSettle();
    await _capture(frame, 'home-selected');

    if (Platform.isAndroid &&
        !await VpnMethodChannel.instance.isVpnAvailable()) {
      // Синтетические адреса не передаём сборкам с рабочим ядром.
      await tester.tap(find.byType(ConnectionButton).hitTestable());
      await tester.pumpAndSettle();
      expect(
        find.text('В этой сборке отсутствует сетевое ядро'),
        findsOneWidget,
      );
      expect(connection.state.isActive, isFalse);
      expect(find.byType(AlertDialog), findsNothing);
      await tester.tap(find.byTooltip('Серверы').hitTestable());
      await tester.pumpAndSettle();
      expect(find.byType(CompactConnectButton).hitTestable(), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}

Future<void> _capture(GlobalKey frame, String name) async {
  if (!const bool.fromEnvironment('FETU_CAPTURE_HOME')) return;
  final boundary =
      frame.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 2);
  try {
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    final dir = await getTemporaryDirectory();
    await File('${dir.path}/fetu-v4-$name.png')
        .writeAsBytes(png!.buffer.asUint8List());
  } finally {
    image.dispose();
  }
}

Map<String, dynamic> _previewFixture() => {
      ...minimalSubscription(
        nodes: [
          _node('berlin', 'Berlin-01', 'DE', 'Берлин'),
          _node('tokyo', 'Tokyo-01', 'JP', 'Токио'),
          _node('ny', 'New York-01', 'US', 'Нью-Йорк'),
          _node('helsinki', 'Helsinki-01', 'FI', 'Хельсинки'),
          _node('paris', 'Paris-01', 'FR', 'Париж'),
        ],
      ),
      'name': 'Demo Provider',
      'branding': {
        'links': {
          'telegram': 'https://provider.example/telegram',
          'website': 'https://provider.example/',
          'support': 'https://provider.example/help',
        },
      },
    };

Map<String, dynamic> _node(
  String id,
  String name,
  String country,
  String city,
) =>
    {
      ...validNode(id: id),
      'name': name,
      'country': country,
      'city': city,
      'domains': [
        {'address': '$id.example', 'type': 'domain', 'status': 'active'},
      ],
    };
