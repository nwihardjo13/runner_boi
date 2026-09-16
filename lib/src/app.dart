import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/history/history_screen.dart';
import 'features/home/home_screen.dart';
import 'features/providers.dart';
import 'features/settings/settings_screen.dart';
import 'features/updates/update_prompt.dart';
import 'services/log_service.dart';
import 'theme/app_theme.dart';

class RunnerBoiApp extends StatelessWidget {
  const RunnerBoiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Runner Boi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const AppShell(),
    );
  }
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  var _index = 0;
  late final AppLogService _logService;

  @override
  void initState() {
    super.initState();
    _logService = ref.read(logServiceProvider);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_checkForUpdatesOnStartup());
    });
    unawaited(
      _logService.info(
        'navigation',
        'App shell opened',
        data: {'tab': 'Plans'},
      ),
    );
  }

  Future<void> _checkForUpdatesOnStartup() async {
    try {
      final service = await ref.read(selfUpdateServiceProvider.future);
      final result = await service.checkForUpdate();
      if (!mounted || !result.hasUpdate) return;
      await showUpdatePrompt(context, ref, result);
    } catch (error, stackTrace) {
      unawaited(
        _logService.error(
          'updates',
          'Startup self-update check failed',
          error: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  void dispose() {
    unawaited(_logService.info('app', 'App shell disposed'));
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(
      ref
          .read(logServiceProvider)
          .info(
            'app_lifecycle',
            'App lifecycle changed',
            data: {'state': state.name},
          ),
    );
  }

  @override
  void didHaveMemoryPressure() {
    unawaited(
      ref
          .read(logServiceProvider)
          .warning('app_lifecycle', 'System memory pressure reported'),
    );
  }

  @override
  void didChangeMetrics() {
    unawaited(
      ref
          .read(logServiceProvider)
          .debug(
            'app_lifecycle',
            'Window metrics changed',
            data: {
              'views': WidgetsBinding.instance.platformDispatcher.views
                  .map(
                    (view) => {
                      'devicePixelRatio': view.devicePixelRatio,
                      'physicalWidth': view.physicalSize.width,
                      'physicalHeight': view.physicalSize.height,
                      'padding': view.padding.toString(),
                      'viewInsets': view.viewInsets.toString(),
                    },
                  )
                  .toList(),
            },
          ),
    );
  }

  @override
  void didChangePlatformBrightness() {
    unawaited(
      ref
          .read(logServiceProvider)
          .debug(
            'app_lifecycle',
            'Platform brightness changed',
            data: {
              'brightness': WidgetsBinding
                  .instance
                  .platformDispatcher
                  .platformBrightness
                  .name,
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      const HistoryScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) {
          unawaited(
            ref
                .read(logServiceProvider)
                .info(
                  'navigation',
                  'Tab selected',
                  data: {
                    'fromIndex': _index,
                    'toIndex': index,
                    'toTab': _tabName(index),
                  },
                ),
          );
          setState(() => _index = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.directions_run_outlined),
            selectedIcon: Icon(Icons.directions_run),
            label: 'Plans',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  String _tabName(int index) {
    return switch (index) {
      0 => 'Plans',
      1 => 'History',
      2 => 'Settings',
      _ => 'Unknown',
    };
  }
}
