import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:runner_boi/src/app.dart';
import 'package:runner_boi/src/features/providers.dart';
import 'package:runner_boi/src/services/update_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('boots and opens the editor', (tester) async {
    await tester.pumpWidget(_smokeApp());

    await _pumpUi(tester);

    expect(find.text('Runner Boi'), findsOneWidget);
    expect(
      find.text('Build the plan. Lock GPS. Do the segment.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('quickStartButton')), findsOneWidget);
    expect(find.text('New plan'), findsOneWidget);

    await tester.tap(find.byKey(const Key('quickStartButton')));
    await _pumpUi(tester);

    expect(find.text('Plan run'), findsOneWidget);
    expect(find.byKey(const Key('addRunSegmentButton')), findsOneWidget);
    expect(find.text('Add run'), findsOneWidget);
    expect(find.byKey(const Key('addRestSegmentButton')), findsOneWidget);
    expect(find.text('Add rest'), findsOneWidget);
    expect(find.byKey(const Key('startRunButton')), findsOneWidget);
    expect(find.text('Segments'), findsOneWidget);
  });

  testWidgets('opens settings from bottom navigation', (tester) async {
    await tester.pumpWidget(_smokeApp());
    await _pumpUi(tester);

    await tester.tap(find.text('Settings'));
    await _pumpUi(tester);

    expect(find.text('Settings'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('App version'),
      240,
      scrollable: find.byType(Scrollable).last,
    );
    await _pumpUi(tester);

    expect(find.text('App version'), findsOneWidget);
    expect(find.byKey(const Key('checkForUpdatesButton')), findsOneWidget);
  });
}

Widget _smokeApp() {
  return ProviderScope(
    overrides: [
      selfUpdateServiceProvider.overrideWith((ref) async {
        final prefs = await ref.watch(sharedPreferencesProvider.future);
        return SelfUpdateService(
          preferences: prefs,
          log: ref.watch(logServiceProvider),
          releaseFetcher: (_) async => null,
          installedVersionLoader: () async => const InstalledAppVersion(
            version: '1.0.2',
            buildNumber: '100000',
          ),
        );
      }),
    ],
    child: const RunnerBoiApp(),
  );
}

Future<void> _pumpUi(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
}
