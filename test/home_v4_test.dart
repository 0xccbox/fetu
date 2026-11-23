import 'dart:convert';

import 'package:fetu/app.dart';
import 'package:fetu/core/constants/subscription_constants.dart';
import 'package:fetu/core/platform/vpn_method_channel.dart';
import 'package:fetu/core/storage/key_value_storage.dart';
import 'package:fetu/features/connection/controllers/connection_controller.dart';
import 'package:fetu/features/connection/models/connection_metrics.dart';
import 'package:fetu/features/connection/models/connection_state.dart' as vpn;
import 'package:fetu/features/connection/models/server_node.dart';
import 'package:fetu/features/connection/services/vpn_connection_service.dart';
import 'package:fetu/features/connection/widgets/compact_connect_button.dart';
import 'package:fetu/features/connection/widgets/connection_button.dart';
import 'package:fetu/features/settings/controllers/settings_controller.dart';
import 'package:fetu/features/settings/models/ui_experience_mode.dart';
import 'package:fetu/features/subscription/controllers/subscription_controller.dart';
import 'package:fetu/features/subscription/models/subscription_node.dart';
import 'package:fetu/features/subscription/widgets/server_selection_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'helpers/subscription_fixtures.dart';
import 'helpers/test_setup.dart';

const _channel = MethodChannel('com.fetu.app/method_channel');
const _url = 'https://provider.example/sub';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await setupTestDependencies();
    await GetIt.instance<SettingsController>().setMode(UiExperienceMode.simple);
  });

  testWidgets('первый запуск без подписки: центрированный экран без заглушки', (
    tester,
  ) async {
    await _boot(tester, const Size(405, 888));
    expect(find.text('Set up connection').hitTestable(), findsOneWidget);
    expect(find.text('Add subscription').hitTestable(), findsOneWidget);
    expect(find.text('No available servers'), findsNothing);
    final buttonCenter = tester.getCenter(find.byType(ConnectionButton)).dy;
    expect(buttonCenter, greaterThan(360));
    expect(buttonCenter, lessThan(600));
    expect(tester.takeException(), isNull);
  });

  testWidgets('узкий экран: сжатие, ссылки и один сервер под шапкой', (
    tester,
  ) async {
    await _boot(tester, const Size(390, 800), subscription: _fixture());
    final large = find.byType(ConnectionButton).hitTestable();
    final compact = find.byType(CompactConnectButton).hitTestable();
    final website = find.widgetWithText(TextButton, 'Website').hitTestable();
    expect(large, findsOneWidget);
    expect(compact, findsNothing);
    expect(website, findsNothing);

    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    final position = scrollable.position;
    position.jumpTo(position.maxScrollExtent * .4);
    await tester.pumpAndSettle();
    final alphas = tester
        .widgetList<Opacity>(
          find.ancestor(
            of: find.text('Website'),
            matching: find.byType(Opacity),
          ),
        )
        .map((widget) => widget.opacity);
    expect(alphas.any((alpha) => alpha > 0 && alpha < 1), isTrue);
    expect(large.evaluate().length + compact.evaluate().length, 1);

    position.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.tap(large);
    await tester.pumpAndSettle();
    expect(large, findsNothing);
    expect(compact, findsOneWidget);
    expect(website, findsOneWidget);
    final server = find.byType(ServerSelectionTile).hitTestable();
    expect(server, findsOneWidget);
    expect(
      tester.getTopLeft(server).dy,
      greaterThan(tester.getBottomLeft(website).dy),
    );

    await tester.tap(server);
    await tester.pumpAndSettle();
    expect(tester.widget<ServerSelectionTile>(server).selected, isTrue);
    expect(find.text('Connect').hitTestable(), findsOneWidget);
    position.jumpTo(0);
    await tester.pumpAndSettle();
    expect(find.text('Germany · Berlin').hitTestable(), findsWidgets);
    expect(website, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('320 dp, RU и текст 200%: карточки и ссылки не переполняются', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _boot(
      tester,
      const Size(320, 620),
      locale: const Locale('ru'),
      subscription: _fixture(many: true),
    );
    expect(tester.takeException(), isNull, reason: 'развёрнутая панель');
    await tester.tap(find.byType(ConnectionButton).hitTestable());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'закреплённая панель');
    expect(find.byType(ServerSelectionTile).hitTestable(), findsWidgets);
    expect(find.byTooltip('Другие ссылки').hitTestable(), findsOneWidget);
    await tester.tap(find.byTooltip('Другие ссылки').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('Extra provider link 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'широкое окно: слева список, справа подключение; выбор переживает ресайз',
      (
    tester,
  ) async {
    await _boot(
      tester,
      const Size(900, 480),
      subscription: _fixture(many: true),
    );
    final firstTile =
        find.widgetWithText(ServerSelectionTile, 'Berlin-01').hitTestable();
    final button = find.byType(ConnectionButton).hitTestable();
    expect(
      tester.getCenter(firstTile).dx,
      lessThan(tester.getCenter(button).dx),
    );
    final list = find.descendant(
      of: find.byType(CustomScrollView),
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(list).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(firstTile, findsNothing);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(
      tester.widget<ServerSelectionTile>(firstTile).focusNode!.hasFocus,
      isTrue,
    );
    await tester.tap(firstTile);
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(390, 790);
    await tester.pumpAndSettle();
    expect(find.text('Connect').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('короткое окно: управление списком и форма над клавиатурой', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _boot(
      tester,
      const Size(568, 320),
      subscription: _fixture(many: true),
    );
    await tester.tap(find.byType(CompactConnectButton).hitTestable());
    await tester.pumpAndSettle();
    expect(find.byType(ServerSelectionTile).hitTestable(), findsWidgets);
    await GetIt.instance<SubscriptionController>().remove();
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
    scroll.position.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CompactConnectButton).hitTestable());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      'VPN://subscribe?data=test&sig=test',
    );
    final input = tester.state<EditableTextState>(find.byType(EditableText));
    tester.view.viewInsets = const FakeViewPadding(bottom: 220);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(
      tester.state<EditableTextState>(find.byType(EditableText)),
      same(input),
    );
    expect(input.widget.focusNode.hasFocus, isTrue);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ошибка подключения видна в компактной шапке при тексте 200%', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final service = _RejectedSession();
    final fixture = _fixture(many: true);
    final nodes = fixture['nodes'] as List<Map<String, dynamic>>;
    nodes.insert(1, {
      ...validNode(id: 'berlin'),
      'name': 'Tokyo alternate',
      'country': 'JP',
    });
    await _boot(
      tester,
      const Size(390, 560),
      locale: const Locale('ru'),
      subscription: fixture,
      service: service,
    );
    final action = find.text('Выбрать сервер');
    expect(action, findsOneWidget);
    expect(
      tester.getBottomRight(action).dy,
      lessThan(560),
      reason: 'Подпись основной кнопки видна без прокрутки',
    );
    await tester.tap(action.hitTestable());
    await tester.pumpAndSettle();
    final second = find.widgetWithText(ServerSelectionTile, 'Tokyo alternate');
    expect(find.byType(CompactConnectButton).hitTestable(), findsOneWidget);
    final position =
        tester.state<ScrollableState>(find.byType(Scrollable)).position;
    position.jumpTo(position.pixels + 144);
    await tester.pumpAndSettle();
    expect(second.hitTestable(), findsOneWidget);
    await tester.tap(second.hitTestable());
    await tester.pumpAndSettle();
    expect(tester.widget<ServerSelectionTile>(second).selected, isTrue);
    expect(
      tester
          .widget<ServerSelectionTile>(
            find.widgetWithText(ServerSelectionTile, 'Berlin-01'),
          )
          .selected,
      isFalse,
    );
    await tester.tap(find.text('Подключить').hitTestable());
    await tester.pumpAndSettle();
    expect(service.attemptedNode?.name, 'Tokyo alternate');
    expect(
      find.text('В этой сборке отсутствует сетевое ядро').hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('активная сессия: длинное имя и замена подписки с тем же ID', (
    tester,
  ) async {
    const title =
        'Berlin with a very long server display name from the provider';
    final server = _TestSession(
      SubscriptionNode.fromJson(
        {...validNode(id: 'same'), 'name': title, 'country': 'DE'},
      ).toServerNode(),
    );
    await _boot(
      tester,
      const Size(320, 680),
      service: server,
      subscription: minimalSubscription(
        nodes: [
          {...validNode(id: 'same'), 'name': title, 'country': 'DE'},
        ],
      ),
    );
    expect(find.text(title).hitTestable(), findsWidgets);
    expect(find.text('00:02:04').hitTestable(), findsOneWidget);
    expect(
      tester.takeException(),
      isNull,
      reason: 'метрики и длинное имя должны помещаться',
    );
    await tester.runAsync(
      () => GetIt.instance<SubscriptionController>().addFromRaw(
        asJson(
          minimalSubscription(
            nodes: [
              {...validNode(id: 'same'), 'name': 'Tokyo-01', 'country': 'JP'},
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(title).hitTestable(), findsOneWidget);
    await tester.tap(find.byTooltip('Servers').hitTestable());
    await tester.pumpAndSettle();
    final tile = tester.widget<ServerSelectionTile>(
      find.byType(ServerSelectionTile).hitTestable(),
    );
    expect(tile.active, isFalse);
    expect(tile.onTap, isNull);
    expect(find.text('Disconnect').hitTestable(), findsOneWidget);
    expect(
      find.text('Disconnect to choose another server.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'сохранённая истёкшая подписка: нет серверов, обновление доступно', (
    tester,
  ) async {
    await _boot(tester, const Size(390, 780));
    final storage = GetIt.instance<KeyValueStorage>();
    await storage.write(
      key: SubscriptionConstants.storageKey,
      value: jsonEncode({
        'url': _url,
        'raw': asJson(minimalSubscription(expireAt: '2020-01-01T00:00:00Z')),
      }),
    );
    await tester.runAsync(GetIt.instance<SubscriptionController>().initialize);
    await tester.pumpAndSettle();
    expect(find.text('Subscription has expired'), findsOneWidget);
    expect(find.byType(ServerSelectionTile), findsNothing);
    await tester.tap(find.byTooltip('Subscription').hitTestable());
    await tester.pumpAndSettle();
    expect(
      find.byTooltip('Refresh subscription').hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'кнопка SmartSelectionButton выбирает лучший узел и показывает пинг',
      (tester) async {
    final fixture = {
      ..._fixture(many: true),
      'branding': {
        'app_name': 'Fetu',
        'features': {'smart_selection': true},
      },
    };
    await _boot(tester, const Size(390, 820), subscription: fixture);

    final smartBtn = find.text('SMART SERVER SELECTION');
    expect(smartBtn, findsOneWidget);

    await tester.ensureVisible(smartBtn);
    await tester.pumpAndSettle();
    await tester.tap(smartBtn);
    await tester.pumpAndSettle();

    expect(find.text('28 ms'), findsWidgets);
    expect(find.text('Connect').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _boot(
  WidgetTester tester,
  Size size, {
  Locale locale = const Locale('en'),
  Map<String, dynamic>? subscription,
  VpnConnectionService? service,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.platformDispatcher.localesTestValue = [locale];
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(_channel, (call) async {
    expect(call.method, 'getStatus');
    return 'disconnected';
  });
  addTearDown(() async {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearLocalesTestValue();
    messenger.setMockMethodCallHandler(_channel, null);
    await GetIt.instance.reset();
  });
  // Парсер запускает Isolate, а контроллер — периодический таймер.
  final connection = await tester.runAsync(() async {
    if (subscription != null) {
      await GetIt.instance<SubscriptionController>()
          .addFromRaw(asJson(subscription));
    }
    final services = GetIt.instance;
    if (service != null) {
      await services.unregister<ConnectionController>();
      final controller = ConnectionController(service);
      services.registerSingleton(controller);
      return controller;
    }
    return services<ConnectionController>();
  });
  addTearDown(() => connection?.dispose());
  await tester.pumpWidget(const FetuApp());
  await tester.pumpAndSettle();
}

class _RejectedSession extends VpnConnectionService {
  _RejectedSession() : super(mode: VpnServiceMode.mock);

  ServerNode? attemptedNode;

  @override
  Future<void> connect(
    ServerNode node, {
    List<ServerNode> fallbackNodes = const <ServerNode>[],
    List<ServerNode> relayCandidates = const <ServerNode>[],
  }) async {
    attemptedNode = node;
    throw const VpnChannelException(
      'Unavailable',
      code: 'VPN_CORE_UNAVAILABLE',
    );
  }
}

class _TestSession extends VpnConnectionService {
  _TestSession(this.currentNode) : super(mode: VpnServiceMode.mock);

  @override
  final ServerNode currentNode;

  @override
  vpn.ConnectionState get currentState => vpn.ConnectionState.connected;

  @override
  ConnectionMetrics get currentMetrics => const ConnectionMetrics(
        connectionDuration: 124,
        totalDownloaded: 1024,
      );
}

Map<String, dynamic> _fixture({bool many = false}) => {
      ...minimalSubscription(
        nodes: [
          {
            ...validNode(id: 'berlin'),
            'name': 'Berlin-01',
            'country': 'DE',
            'city': 'Berlin',
          },
          if (many)
            for (var i = 1; i <= 8; i++)
              {
                ...validNode(id: 'tokyo-$i'),
                'name': 'Tokyo-$i',
                'country': 'JP',
                'city': 'Tokyo',
              },
        ],
      ),
      'branding': {
        'app_name': 'Fetu',
        'links': {
          'telegram': 'https://t.me/example',
          'website': 'https://provider.example/',
          'support': 'https://provider.example/help',
          'custom': [
            for (var i = 1; i <= 8; i++)
              {
                'label': 'Extra provider link $i',
                'url': 'https://provider.example/link/$i',
              },
          ],
        },
      },
    };
