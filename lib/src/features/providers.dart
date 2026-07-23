import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../core/formatters.dart';
import '../data/app_database.dart';
import '../data/repositories.dart';
import '../domain/models.dart';
import '../services/location_service.dart';
import '../services/voice_service.dart';

const _uuid = Uuid();

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

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

final settingsRepositoryProvider = FutureProvider<SettingsRepository>((
  ref,
) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return SettingsRepository(prefs, ref.watch(localeProvider));
});

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, AppSettings>(
      SettingsController.new,
    );

class SettingsController extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final repository = await ref.watch(settingsRepositoryProvider.future);
    return repository.load();
  }

  Future<void> saveSettings(AppSettings settings) async {
    state = AsyncData(settings);
    final repository = await ref.read(settingsRepositoryProvider.future);
    await repository.save(settings);
  }
}

final templatesProvider =
    AsyncNotifierProvider<TemplatesController, List<WorkoutTemplate>>(
      TemplatesController.new,
    );

class TemplatesController extends AsyncNotifier<List<WorkoutTemplate>> {
  @override
  Future<List<WorkoutTemplate>> build() async {
    final repository = ref.watch(workoutRepositoryProvider);
    final templates = await repository.listTemplates();
    if (templates.isNotEmpty) return templates;
    final starter = _starterTemplate();
    await repository.saveTemplate(starter);
    return [starter];
  }

  Future<void> save(WorkoutTemplate template) async {
    final repository = ref.read(workoutRepositoryProvider);
    final now = DateTime.now();
    final next = template.copyWith(updatedAt: now);
    await repository.saveTemplate(next);
    state = AsyncData(await repository.listTemplates());
  }

  Future<void> delete(String id) async {
    final repository = ref.read(workoutRepositoryProvider);
    await repository.deleteTemplate(id);
    state = AsyncData(await repository.listTemplates());
  }

  Future<void> duplicate(WorkoutTemplate template) async {
    final now = DateTime.now();
    await save(
      template.copyWith(
        id: _uuid.v4(),
        name: '${template.name} copy',
        createdAt: now,
        updatedAt: now,
        segments: template.segments
            .map((segment) => segment.copyWith(id: _uuid.v4()))
            .toList(),
      ),
    );
  }

  WorkoutTemplate _starterTemplate() {
    final now = DateTime.now();
    return WorkoutTemplate(
      id: _uuid.v4(),
      name: 'Easy intervals',
      createdAt: now,
      updatedAt: now,
      segments: [
        SegmentPlan(
          id: _uuid.v4(),
          kind: SegmentKind.run,
          targetType: SegmentTargetType.time,
          durationSeconds: 5 * 60,
        ),
        SegmentPlan(
          id: _uuid.v4(),
          kind: SegmentKind.rest,
          targetType: SegmentTargetType.time,
          durationSeconds: 90,
        ),
        SegmentPlan(
          id: _uuid.v4(),
          kind: SegmentKind.run,
          targetType: SegmentTargetType.distance,
          distanceMeters: 400,
        ),
      ],
    );
  }
}

final runHistoryProvider = StreamProvider<List<RunRecord>>((ref) {
  return ref.watch(runHistoryRepositoryProvider).watchRuns();
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final voiceServiceProvider = Provider<VoiceService>((ref) {
  final service = VoiceService();
  service.configure();
  ref.onDispose(service.stop);
  return service;
});

final runControllerProvider = NotifierProvider<RunController, RunState>(
  RunController.new,
);

class RunState {
  const RunState({
    required this.phase,
    this.workout,
    this.startedAt,
    this.segmentIndex = 0,
    this.elapsedSegmentSeconds = 0,
    this.elapsedTotalSeconds = 0,
    this.segmentDistanceMeters = 0,
    this.totalDistanceMeters = 0,
    this.currentPaceSecondsPerKm,
    this.segmentAveragePaceSecondsPerKm,
    this.gpsFix,
    this.allowStartAnyway = false,
    this.completedSegments = const [],
    this.statusMessage,
  });

  factory RunState.idle() => const RunState(phase: RunPhase.idle);

  final RunPhase phase;
  final WorkoutTemplate? workout;
  final DateTime? startedAt;
  final int segmentIndex;
  final int elapsedSegmentSeconds;
  final int elapsedTotalSeconds;
  final double segmentDistanceMeters;
  final double totalDistanceMeters;
  final double? currentPaceSecondsPerKm;
  final double? segmentAveragePaceSecondsPerKm;
  final GpsFix? gpsFix;
  final bool allowStartAnyway;
  final List<SegmentResult> completedSegments;
  final String? statusMessage;

  SegmentPlan? get currentSegment {
    final segments = workout?.segments;
    if (segments == null || segmentIndex >= segments.length) return null;
    return segments[segmentIndex];
  }

  SegmentPlan? get nextSegment {
    final segments = workout?.segments;
    if (segments == null || segmentIndex + 1 >= segments.length) return null;
    return segments[segmentIndex + 1];
  }

  SegmentPlan? get previousSegment {
    final segments = workout?.segments;
    if (segments == null || segmentIndex - 1 < 0) return null;
    return segments[segmentIndex - 1];
  }

  bool get isActive => phase == RunPhase.running || phase == RunPhase.paused;
  bool get isFinished => phase == RunPhase.complete;

  RunState copyWith({
    RunPhase? phase,
    WorkoutTemplate? workout,
    DateTime? startedAt,
    int? segmentIndex,
    int? elapsedSegmentSeconds,
    int? elapsedTotalSeconds,
    double? segmentDistanceMeters,
    double? totalDistanceMeters,
    double? currentPaceSecondsPerKm,
    double? segmentAveragePaceSecondsPerKm,
    GpsFix? gpsFix,
    bool? allowStartAnyway,
    List<SegmentResult>? completedSegments,
    String? statusMessage,
    bool clearPace = false,
    bool clearStatus = false,
  }) {
    return RunState(
      phase: phase ?? this.phase,
      workout: workout ?? this.workout,
      startedAt: startedAt ?? this.startedAt,
      segmentIndex: segmentIndex ?? this.segmentIndex,
      elapsedSegmentSeconds:
          elapsedSegmentSeconds ?? this.elapsedSegmentSeconds,
      elapsedTotalSeconds: elapsedTotalSeconds ?? this.elapsedTotalSeconds,
      segmentDistanceMeters:
          segmentDistanceMeters ?? this.segmentDistanceMeters,
      totalDistanceMeters: totalDistanceMeters ?? this.totalDistanceMeters,
      currentPaceSecondsPerKm: clearPace
          ? null
          : currentPaceSecondsPerKm ?? this.currentPaceSecondsPerKm,
      segmentAveragePaceSecondsPerKm: clearPace
          ? null
          : segmentAveragePaceSecondsPerKm ??
                this.segmentAveragePaceSecondsPerKm,
      gpsFix: gpsFix ?? this.gpsFix,
      allowStartAnyway: allowStartAnyway ?? this.allowStartAnyway,
      completedSegments: completedSegments ?? this.completedSegments,
      statusMessage: clearStatus ? null : statusMessage ?? this.statusMessage,
    );
  }
}

class RunController extends Notifier<RunState> {
  Timer? _timer;
  Timer? _gpsLockTimer;
  StreamSubscription<LocationSample>? _locationSub;
  LocationSample? _lastSample;
  final _paceWindow = Queue<_PacePoint>();

  @override
  RunState build() {
    ref.onDispose(_disposeTracking);
    return RunState.idle();
  }

  Future<void> prepare(WorkoutTemplate workout) async {
    _disposeTracking();
    state = RunState(
      phase: RunPhase.gpsLock,
      workout: workout,
      statusMessage: 'Checking GPS',
    );
    await refreshGps();
    _gpsLockTimer = Timer(const Duration(seconds: 30), () {
      state = state.copyWith(allowStartAnyway: true);
    });
  }

  Future<void> refreshGps() async {
    final fix = await ref.read(locationServiceProvider).currentFix();
    state = state.copyWith(gpsFix: fix, statusMessage: fix.message);
  }

  Future<void> start() async {
    final workout = state.workout;
    final segment = state.currentSegment;
    if (workout == null || segment == null) return;
    _gpsLockTimer?.cancel();
    final settings = await ref.read(settingsControllerProvider.future);
    state = state.copyWith(
      phase: RunPhase.countdown,
      statusMessage: 'Next segment',
    );
    if (settings.voiceCuesEnabled) {
      final voice = ref.read(voiceServiceProvider);
      await voice.announceSegment(
        segment: segment,
        units: settings.measurementSystem,
        duckAudio: settings.duckAudio,
      );
      await voice.countdown(
        settings.countdownSeconds,
        duckAudio: settings.duckAudio,
      );
    } else {
      await Future<void>.delayed(Duration(seconds: settings.countdownSeconds));
    }
    state = state.copyWith(
      phase: RunPhase.running,
      startedAt: state.startedAt ?? DateTime.now(),
      statusMessage: 'Running',
      clearPace: true,
    );
    _startTracking(settings);
  }

  void pause() {
    if (state.phase != RunPhase.running) return;
    _timer?.cancel();
    _locationSub?.pause();
    state = state.copyWith(phase: RunPhase.paused, statusMessage: 'Paused');
  }

  Future<void> resume() async {
    if (state.phase != RunPhase.paused) return;
    final settings = await ref.read(settingsControllerProvider.future);
    _locationSub?.resume();
    _startTimer();
    state = state.copyWith(phase: RunPhase.running, statusMessage: 'Running');
    if (_locationSub == null) {
      _startTracking(settings);
    }
  }

  Future<void> skipSegment() async {
    if (state.currentSegment == null) return;
    await _completeCurrentSegment(manualAdvance: true);
  }

  Future<void> endRun() async {
    final workout = state.workout;
    if (workout == null || state.startedAt == null) {
      state = RunState.idle();
      return;
    }
    final results = [...state.completedSegments];
    if (state.currentSegment != null && state.elapsedSegmentSeconds > 0) {
      results.add(_currentResult());
    }
    await _saveRun(results);
    _disposeTracking();
    state = state.copyWith(
      phase: RunPhase.complete,
      completedSegments: results,
      statusMessage: 'Run saved',
    );
  }

  void reset() {
    _disposeTracking();
    state = RunState.idle();
  }

  void _startTracking(AppSettings settings) {
    _locationSub ??= ref
        .read(locationServiceProvider)
        .samples()
        .listen(
          (sample) => _onLocation(sample, settings),
          onError: (_) {
            state = state.copyWith(statusMessage: 'GPS stream interrupted');
          },
        );
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (state.phase != RunPhase.running) return;
    state = state.copyWith(
      elapsedSegmentSeconds: state.elapsedSegmentSeconds + 1,
      elapsedTotalSeconds: state.elapsedTotalSeconds + 1,
      segmentAveragePaceSecondsPerKm: _averagePace(
        state.elapsedSegmentSeconds + 1,
        state.segmentDistanceMeters,
      ),
    );
    final segment = state.currentSegment;
    if (segment == null) return;
    if (segment.targetType == SegmentTargetType.time &&
        state.elapsedSegmentSeconds >= (segment.durationSeconds ?? 0)) {
      unawaited(_completeCurrentSegment());
    }
  }

  void _onLocation(LocationSample sample, AppSettings settings) {
    if (state.phase != RunPhase.running) return;
    final fix = GpsFix.fromAccuracy(sample.accuracyMeters);
    var addedDistance = 0.0;
    if (_lastSample != null && sample.accuracyMeters <= 50) {
      final distance = ref
          .read(locationServiceProvider)
          .distanceBetween(_lastSample!, sample);
      if (distance <= 100) {
        addedDistance = distance;
      }
    }
    _lastSample = sample;

    final now = sample.timestamp;
    _paceWindow.addLast(_PacePoint(now, sample.speedMetersPerSecond));
    final maxWindow = switch (settings.paceDisplayMode) {
      PaceDisplayMode.instant => const Duration(seconds: 1),
      PaceDisplayMode.smoothed5 => const Duration(seconds: 5),
      PaceDisplayMode.smoothed10 => const Duration(seconds: 10),
    };
    while (_paceWindow.isNotEmpty &&
        now.difference(_paceWindow.first.timestamp) > maxWindow) {
      _paceWindow.removeFirst();
    }

    final segmentDistance = state.segmentDistanceMeters + addedDistance;
    final totalDistance = state.totalDistanceMeters + addedDistance;
    state = state.copyWith(
      gpsFix: fix,
      segmentDistanceMeters: segmentDistance,
      totalDistanceMeters: totalDistance,
      currentPaceSecondsPerKm: _displayPace(settings.paceDisplayMode, sample),
      segmentAveragePaceSecondsPerKm: _averagePace(
        state.elapsedSegmentSeconds,
        segmentDistance,
      ),
    );

    final segment = state.currentSegment;
    if (segment?.targetType == SegmentTargetType.distance &&
        segmentDistance >= (segment?.distanceMeters ?? double.infinity)) {
      unawaited(_completeCurrentSegment());
    }
  }

  double? _displayPace(PaceDisplayMode mode, LocationSample latest) {
    final speed = mode == PaceDisplayMode.instant
        ? latest.speedMetersPerSecond
        : _paceWindow.map((point) => point.speedMetersPerSecond).average;
    if (speed <= 0.4) return null;
    return 1000 / speed;
  }

  double? _averagePace(int seconds, double meters) {
    if (seconds <= 0 || meters < 5) return null;
    return seconds / (meters / 1000);
  }

  Future<void> _completeCurrentSegment({bool manualAdvance = false}) async {
    if (state.phase == RunPhase.countdown || state.phase == RunPhase.complete) {
      return;
    }
    final workout = state.workout;
    final segment = state.currentSegment;
    if (workout == null || segment == null) return;

    _timer?.cancel();
    await _locationSub?.cancel();
    _locationSub = null;
    _lastSample = null;
    _paceWindow.clear();

    final results = [...state.completedSegments, _currentResult()];
    final nextIndex = state.segmentIndex + 1;
    if (nextIndex >= workout.segments.length) {
      await _saveRun(results);
      _disposeTracking();
      state = state.copyWith(
        phase: RunPhase.complete,
        completedSegments: results,
        statusMessage: manualAdvance ? 'Skipped and saved' : 'Run saved',
      );
      return;
    }

    state = state.copyWith(
      phase: RunPhase.countdown,
      segmentIndex: nextIndex,
      elapsedSegmentSeconds: 0,
      segmentDistanceMeters: 0,
      completedSegments: results,
      clearPace: true,
      statusMessage: 'Next segment',
    );
    await start();
  }

  SegmentResult _currentResult() {
    final segment = state.currentSegment!;
    final settings = ref.read(settingsControllerProvider).value;
    return SegmentResult(
      segmentId: segment.id,
      segmentIndex: state.segmentIndex,
      kind: segment.kind,
      plannedLabel: settings == null
          ? segment.targetType.name
          : segmentCue(segment, settings.measurementSystem),
      elapsedSeconds: state.elapsedSegmentSeconds,
      distanceMeters: state.segmentDistanceMeters,
      averagePaceSecondsPerKm: state.segmentAveragePaceSecondsPerKm,
      targetPaceSecondsPerKm: segment.targetPaceSecondsPerKm,
    );
  }

  Future<void> _saveRun(List<SegmentResult> results) async {
    final workout = state.workout!;
    final startedAt = state.startedAt ?? DateTime.now();
    final record = RunRecord(
      id: _uuid.v4(),
      workoutName: workout.name,
      startedAt: startedAt,
      completedAt: DateTime.now(),
      totalElapsedSeconds: max(
        state.elapsedTotalSeconds,
        results.fold(0, (sum, segment) => sum + segment.elapsedSeconds),
      ),
      totalDistanceMeters: max(
        state.totalDistanceMeters,
        results.fold(0.0, (sum, segment) => sum + segment.distanceMeters),
      ),
      plannedSegments: workout.segments,
      segmentResults: results,
    );
    await ref.read(runHistoryRepositoryProvider).saveRun(record);
  }

  void _disposeTracking() {
    _timer?.cancel();
    _gpsLockTimer?.cancel();
    _locationSub?.cancel();
    _timer = null;
    _gpsLockTimer = null;
    _locationSub = null;
    _lastSample = null;
    _paceWindow.clear();
  }
}

class _PacePoint {
  const _PacePoint(this.timestamp, this.speedMetersPerSecond);

  final DateTime timestamp;
  final double speedMetersPerSecond;
}

extension _Average on Iterable<double> {
  double get average {
    var count = 0;
    var total = 0.0;
    for (final value in this) {
      if (value > 0) {
        count++;
        total += value;
      }
    }
    if (count == 0) return 0;
    return total / count;
  }
}
