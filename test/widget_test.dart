import 'package:fetu/app.dart';
import 'package:fetu/features/connection/controllers/connection_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'helpers/test_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setupTestDependencies();
  });

  tearDownAll(() {
    GetIt.instance.reset();
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FetuApp());
    await tester.pump();

    expect(find.byType(FetuApp), findsOneWidget);

    GetIt.instance<ConnectionController>().dispose();
  });
}
