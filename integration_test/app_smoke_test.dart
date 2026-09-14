import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:runner_boi/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('boots, opens the editor, and shows diagnostics', (tester) async {
    await app.main();

    await tester.pumpAndSettle();

    expect(find.text('Runner Boi'), findsOneWidget);
    expect(
      find.text('Build the plan. Lock GPS. Do the segment.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('quickStartButton')), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'New plan'), findsOneWidget);

    await tester.tap(find.byKey(const Key('quickStartButton')));
    await tester.pumpAndSettle();

    expect(find.text('Plan run'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Run'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Rest'), findsOneWidget);
    expect(find.byKey(const Key('startRunButton')), findsOneWidget);
    expect(find.text('Segments'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('settings'), findsOneWidget);
    expect(find.text('Diagnostics'), findsOneWidget);
    expect(find.byKey(const Key('exportLogsButton')), findsOneWidget);
  });
}
