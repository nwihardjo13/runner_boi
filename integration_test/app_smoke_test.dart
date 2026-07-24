import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:runner_boi/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('boots and opens the plan editor', (tester) async {
    app.main();

    await tester.pumpAndSettle();

    expect(find.text('runner boi'), findsOneWidget);
    expect(
      find.text('Build the plan. Lock GPS. Do the segment.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'New plan'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'New plan'));
    await tester.pumpAndSettle();

    expect(find.text('New plan'), findsWidgets);
    expect(find.widgetWithText(FilledButton, 'Run'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Rest'), findsOneWidget);
    expect(find.text('Segments'), findsOneWidget);
  });
}
