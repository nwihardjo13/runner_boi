import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../app_providers.dart';

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, AppSettings>(
      SettingsController.new,
    );

class SettingsController extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final repository = await ref.watch(settingsRepositoryProvider.future);
    final settings = repository.load();
    unawaited(
      ref
          .read(logServiceProvider)
          .info(
            'settings',
            'Settings loaded',
            data: _settingsLogData(settings),
          ),
    );
    return settings;
  }

  Future<void> saveSettings(AppSettings settings) async {
    unawaited(
      ref
          .read(logServiceProvider)
          .info(
            'settings',
            'Settings save requested',
            data: _settingsLogData(settings),
          ),
    );
    state = AsyncData(settings);
    final repository = await ref.read(settingsRepositoryProvider.future);
    await repository.save(settings);
    unawaited(
      ref
          .read(logServiceProvider)
          .info('settings', 'Settings saved', data: _settingsLogData(settings)),
    );
  }

  Map<String, Object?> _settingsLogData(AppSettings settings) {
    return {
      'measurementSystem': settings.measurementSystem,
      'paceDisplayMode': settings.paceDisplayMode,
      'countdownSeconds': settings.countdownSeconds,
      'voiceCuesEnabled': settings.voiceCuesEnabled,
      'duckAudio': settings.duckAudio,
      'runUpdateCueMode': settings.runUpdateCueMode,
      'runUpdateMinutes': settings.runUpdateMinutes,
      'runUpdateDistance': settings.runUpdateDistance,
      'autoUpdateChecksEnabled': settings.autoUpdateChecksEnabled,
    };
  }
}
