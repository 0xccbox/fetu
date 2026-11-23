import 'package:fetu/features/subscription/widgets/add_subscription_dialog.dart';
import 'package:fetu/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AddSubscriptionDialog очищает NUL-байты и управляющие символы',
      (tester) async {
    String? returnedUrl;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                returnedUrl = await showDialog<String>(
                  context: context,
                  builder: (_) => const AddSubscriptionDialog(),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField),
      'https://sub.example.com/token123\u0000\u0000\u200B',
    );
    await tester.tap(find.text('Загрузить'));
    await tester.pumpAndSettle();

    expect(returnedUrl, 'https://sub.example.com/token123');
  });
}
