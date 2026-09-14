import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/app_database.dart';
import '../data/repositories.dart';
import '../domain/models.dart';
import '../services/location_service.dart';
import '../services/log_service.dart';
import '../services/voice_service.dart';

final localeProvider = Provider<LocaleLike>((ref) {
  final dispatcherLocale = WidgetsBinding.instance.platformDispatcher.locale;
  return LocaleLike(dispatcherLocale.countryCode);
});

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository(ref.watch(databaseProvider));
});

final runHistoryRepositoryProvider = Provider<RunHistoryRepository>((ref) {
  return RunHistoryRepository(ref.watch(databaseProvider));
});

final runHistoryProvider = StreamProvider<List<RunRecord>>((ref) {
  return ref.watch(runHistoryRepositoryProvider).watchRuns();
});

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

final logServiceProvider = Provider<AppLogService>((ref) {
  final service = AppLogService();
  unawaited(service.start());
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});

final settingsRepositoryProvider = FutureProvider<SettingsRepository>((
  ref,
) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return SettingsRepository(prefs, ref.watch(localeProvider));
});

final activeRunRepositoryProvider = FutureProvider<ActiveRunRepository>((
  ref,
) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return ActiveRunRepository(prefs);
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService(ref.watch(logServiceProvider));
});

final voiceServiceProvider = Provider<VoiceService>((ref) {
  final service = VoiceService(ref.watch(logServiceProvider));
  service.configure();
  ref.onDispose(service.stop);
  return service;
});
