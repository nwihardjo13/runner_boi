import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../app_providers.dart';
import '../settings/settings_controller.dart';
import '../../core/formatters.dart';
import '../../domain/models.dart';
import '../../services/location_service.dart';

const _uuid = Uuid();

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
  bool get needsEndConfirmation =>
      isActive || (phase == RunPhase.countdown && startedAt != null);
  bool get hasRecoverableSession =>
      workout != null && phase != RunPhase.idle && phase != RunPhase.complete;

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
  Future<void> _activeRunPersistence = Future.value();
  final _paceWindow = Queue<_PacePoint>();

  @override
  RunState build() {
    ref.onDispose(_disposeTracking);
    _logInfo('Run controller initialized');
    unawaited(_restoreActiveRun());
    return RunState.idle();
  }

  Future<void> prepare(WorkoutTemplate workout) async {
    _logInfo('Preparing workout run', data: _workoutLogData(workout));
    _disposeTracking();
    _setState(
      RunState(
        phase: RunPhase.gpsLock,
        workout: workout,
        statusMessage: 'Checking GPS',
      ),
    );
    await refreshGps();
    _scheduleGpsFallback();
  }

  Future<void> refreshGps() async {
    _logDebug('Refreshing GPS fix');
    try {
      final fix = await ref.read(locationServiceProvider).currentFix();
      _logInfo('GPS fix refreshed', data: _gpsFixLogData(fix));
      _setState(state.copyWith(gpsFix: fix, statusMessage: fix.message));
    } catch (error, stackTrace) {
      _logError('GPS refresh failed', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> start() async {
    final workout = state.workout;
    final segment = state.currentSegment;
    if (workout == null || segment == null) {
      _logWarning(
        'Start ignored because workout or segment is missing',
        data: _runStateLogData(state),
      );
      return;
    }
    _gpsLockTimer?.cancel();
    final settings = await ref.read(settingsControllerProvider.future);
    _logInfo(
      'Starting segment countdown',
      data: {
        ..._runStateLogData(state),
        'segment': _segmentLogData(segment),
        'voiceCuesEnabled': settings.voiceCuesEnabled,
        'duckAudio': settings.duckAudio,
        'countdownSeconds': settings.countdownSeconds,
      },
    );
    _setState(
      state.copyWith(phase: RunPhase.countdown, statusMessage: 'Next segment'),
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
    _setState(
      state.copyWith(
        phase: RunPhase.running,
        startedAt: state.startedAt ?? DateTime.now(),
        statusMessage: 'Running',
        clearPace: true,
      ),
    );
    _logInfo(
      'Segment running',
      data: {..._runStateLogData(state), 'segment': _segmentLogData(segment)},
    );
    _startTracking(settings);
  }

  void pause() {
    if (state.phase != RunPhase.running) {
      _logWarning(
        'Pause ignored because run is not active',
        data: _runStateLogData(state),
      );
      return;
    }
    _timer?.cancel();
    _locationSub?.pause();
    _setState(state.copyWith(phase: RunPhase.paused, statusMessage: 'Paused'));
    _logInfo('Run paused', data: _runStateLogData(state));
  }

  Future<void> resume() async {
    if (state.phase != RunPhase.paused) {
      _logWarning(
        'Resume ignored because run is not paused',
        data: _runStateLogData(state),
      );
      return;
    }
    final settings = await ref.read(settingsControllerProvider.future);
    _locationSub?.resume();
    _startTimer();
    _setState(
      state.copyWith(phase: RunPhase.running, statusMessage: 'Running'),
    );
    if (_locationSub == null) {
      _startTracking(settings);
    }
    _logInfo('Run resumed', data: _runStateLogData(state));
  }

  Future<void> skipSegment() async {
    if (state.currentSegment == null) {
      _logWarning(
        'Skip ignored because there is no current segment',
        data: _runStateLogData(state),
      );
      return;
    }
    _logInfo('Manual segment skip requested', data: _runStateLogData(state));
    await _completeCurrentSegment(manualAdvance: true);
  }

  Future<void> endRun() async {
    final workout = state.workout;
    if (workout == null || state.startedAt == null) {
      _logInfo(
        'End run requested before run start; resetting',
        data: _runStateLogData(state),
      );
      await reset();
      return;
    }
    _logInfo('End run requested', data: _runStateLogData(state));
    final results = [...state.completedSegments];
    if (state.currentSegment != null && state.elapsedSegmentSeconds > 0) {
      results.add(_currentResult());
    }
    await _saveRun(results);
    _disposeTracking();
    _setState(
      state.copyWith(
        phase: RunPhase.complete,
        completedSegments: results,
        statusMessage: 'Run saved',
      ),
    );
    await _persistActiveRunNow();
    _logInfo(
      'Run ended and saved',
      data: {
        ..._runStateLogData(state),
        'segmentResults': results.map(_segmentResultLogData).toList(),
      },
    );
  }

  Future<void> reset() async {
    _logInfo('Run reset requested', data: _runStateLogData(state));
    _disposeTracking();
    _setState(RunState.idle());
    await _persistActiveRunNow();
    _logInfo('Run reset complete', data: _runStateLogData(state));
  }

  void _startTracking(AppSettings settings) {
    _logInfo(
      'Starting tracking loop',
      data: {
        ..._runStateLogData(state),
        'paceDisplayMode': settings.paceDisplayMode,
      },
    );
    _locationSub ??= ref
        .read(locationServiceProvider)
        .samples()
        .listen(
          (sample) => _onLocation(sample, settings),
          onError: (Object error, StackTrace stackTrace) {
            _logError(
              'GPS stream interrupted',
              error: error,
              stackTrace: stackTrace,
            );
            _setState(state.copyWith(statusMessage: 'GPS stream interrupted'));
          },
        );
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _logDebug('Run timer started', data: _runStateLogData(state));
  }

  void _scheduleGpsFallback() {
    _gpsLockTimer?.cancel();
    _logDebug('GPS fallback timer scheduled');
    _gpsLockTimer = Timer(const Duration(seconds: 30), () {
      if (state.phase != RunPhase.gpsLock) return;
      _setState(state.copyWith(allowStartAnyway: true));
      _logWarning(
        'GPS fallback enabled after timeout',
        data: _runStateLogData(state),
      );
    });
  }

  Future<void> _restoreActiveRun() async {
    final repository = await ref.read(activeRunRepositoryProvider.future);
    final snapshot = await repository.load();
    if (snapshot == null) {
      _logDebug('No active run snapshot found');
      return;
    }
    if (state.phase != RunPhase.idle) {
      _logWarning(
        'Active run snapshot ignored because controller is not idle',
        data: _runStateLogData(state),
      );
      return;
    }
    if (snapshot.phase == RunPhase.idle ||
        snapshot.phase == RunPhase.complete ||
        snapshot.workout.segments.isEmpty) {
      await repository.clear();
      _logWarning(
        'Invalid active run snapshot cleared',
        data: _activeRunSnapshotLogData(snapshot),
      );
      return;
    }

    final segmentIndex = min(
      max(snapshot.segmentIndex, 0),
      snapshot.workout.segments.length - 1,
    );
    final restoredPhase =
        snapshot.startedAt == null || snapshot.phase == RunPhase.gpsLock
        ? RunPhase.gpsLock
        : RunPhase.paused;
    _setState(
      RunState(
        phase: restoredPhase,
        workout: snapshot.workout,
        startedAt: snapshot.startedAt,
        segmentIndex: segmentIndex,
        elapsedSegmentSeconds: snapshot.elapsedSegmentSeconds,
        elapsedTotalSeconds: snapshot.elapsedTotalSeconds,
        segmentDistanceMeters: snapshot.segmentDistanceMeters,
        totalDistanceMeters: snapshot.totalDistanceMeters,
        segmentAveragePaceSecondsPerKm: snapshot.segmentAveragePaceSecondsPerKm,
        allowStartAnyway: snapshot.allowStartAnyway,
        completedSegments: snapshot.completedSegments,
        statusMessage: restoredPhase == RunPhase.paused
            ? 'Recovered paused run'
            : 'Recovered run',
      ),
    );
    _logInfo(
      'Active run snapshot restored',
      data: {
        'snapshot': _activeRunSnapshotLogData(snapshot),
        'restoredState': _runStateLogData(state),
      },
    );
    if (restoredPhase == RunPhase.gpsLock && !snapshot.allowStartAnyway) {
      _scheduleGpsFallback();
    }
  }

  void _setState(RunState next, {bool persist = true}) {
    final previous = state;
    state = next;
    _logDebug(
      'Run state updated',
      data: {
        'fromPhase': previous.phase,
        'toPhase': next.phase,
        'persist': persist,
        'state': _runStateLogData(next),
      },
    );
    if (persist) _queueActiveRunPersist();
  }

  void _queueActiveRunPersist() {
    final snapshot = _activeRunSnapshot();
    _activeRunPersistence = _activeRunPersistence
        .catchError((Object error, StackTrace stackTrace) {})
        .then((_) => _writeActiveRunSnapshot(snapshot));
    unawaited(_activeRunPersistence);
  }

  Future<void> _persistActiveRunNow() {
    final snapshot = _activeRunSnapshot();
    _activeRunPersistence = _activeRunPersistence
        .catchError((Object error, StackTrace stackTrace) {})
        .then((_) => _writeActiveRunSnapshot(snapshot));
    return _activeRunPersistence;
  }

  Future<void> _writeActiveRunSnapshot(ActiveRunSnapshot? snapshot) async {
    final repository = await ref.read(activeRunRepositoryProvider.future);
    if (snapshot == null) {
      await repository.clear();
      _logDebug('Active run snapshot cleared');
      return;
    }
    await repository.save(snapshot);
    _logDebug(
      'Active run snapshot saved',
      data: _activeRunSnapshotLogData(snapshot),
    );
  }

  ActiveRunSnapshot? _activeRunSnapshot() {
    if (!state.hasRecoverableSession) return null;
    return ActiveRunSnapshot(
      workout: state.workout!,
      phase: state.phase,
      capturedAt: DateTime.now(),
      startedAt: state.startedAt,
      segmentIndex: state.segmentIndex,
      elapsedSegmentSeconds: state.elapsedSegmentSeconds,
      elapsedTotalSeconds: state.elapsedTotalSeconds,
      segmentDistanceMeters: state.segmentDistanceMeters,
      totalDistanceMeters: state.totalDistanceMeters,
      currentPaceSecondsPerKm: state.currentPaceSecondsPerKm,
      segmentAveragePaceSecondsPerKm: state.segmentAveragePaceSecondsPerKm,
      allowStartAnyway: state.allowStartAnyway,
      completedSegments: state.completedSegments,
    );
  }

  void _tick() {
    if (state.phase != RunPhase.running) return;
    final nextElapsedSegmentSeconds = state.elapsedSegmentSeconds + 1;
    final nextElapsedTotalSeconds = state.elapsedTotalSeconds + 1;
    _setState(
      state.copyWith(
        elapsedSegmentSeconds: nextElapsedSegmentSeconds,
        elapsedTotalSeconds: nextElapsedTotalSeconds,
        segmentAveragePaceSecondsPerKm: _averagePace(
          nextElapsedSegmentSeconds,
          state.segmentDistanceMeters,
        ),
      ),
    );
    _logDebug(
      'Run timer tick',
      data: {
        ..._runStateLogData(state),
        'nextElapsedSegmentSeconds': nextElapsedSegmentSeconds,
        'nextElapsedTotalSeconds': nextElapsedTotalSeconds,
      },
    );
    final segment = state.currentSegment;
    if (segment == null) return;
    if (segment.targetType == SegmentTargetType.time &&
        state.elapsedSegmentSeconds >= (segment.durationSeconds ?? 0)) {
      _logInfo(
        'Time segment target reached',
        data: {
          ..._runStateLogData(state),
          'targetDurationSeconds': segment.durationSeconds,
        },
      );
      unawaited(_completeCurrentSegment());
    }
  }

  void _onLocation(LocationSample sample, AppSettings settings) {
    if (state.phase != RunPhase.running) return;
    final fix = GpsFix.fromAccuracy(sample.accuracyMeters);
    var addedDistance = 0.0;
    double? rawDistanceMeters;
    String distanceDecision;
    final previousSample = _lastSample;
    if (previousSample == null) {
      distanceDecision = 'first_sample';
    } else if (sample.accuracyMeters > 50) {
      distanceDecision = 'rejected_accuracy_over_50m';
    } else {
      final distance = ref
          .read(locationServiceProvider)
          .distanceBetween(previousSample, sample);
      rawDistanceMeters = distance;
      if (distance <= 100) {
        addedDistance = distance;
        distanceDecision = 'accepted';
      } else {
        distanceDecision = 'rejected_distance_jump_over_100m';
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
    final displayPace = _displayPace(settings.paceDisplayMode, sample);
    final averagePace = _averagePace(
      state.elapsedSegmentSeconds,
      segmentDistance,
    );
    _setState(
      state.copyWith(
        gpsFix: fix,
        segmentDistanceMeters: segmentDistance,
        totalDistanceMeters: totalDistance,
        currentPaceSecondsPerKm: displayPace,
        segmentAveragePaceSecondsPerKm: averagePace,
      ),
    );
    final sampleLogData = {
      'latitude': sample.latitude,
      'longitude': sample.longitude,
      'timestamp': sample.timestamp,
      'accuracyMeters': sample.accuracyMeters,
      'gpsQuality': fix.quality,
      'gpsCanStart': fix.canStart,
      'rawSpeedMetersPerSecond': sample.speedMetersPerSecond,
      'rawDistanceMeters': rawDistanceMeters,
      'addedDistanceMeters': addedDistance,
      'distanceDecision': distanceDecision,
      'paceDisplayMode': settings.paceDisplayMode,
      'paceWindowSamples': _paceWindow.length,
      'currentPaceSecondsPerKm': displayPace,
      'segmentAveragePaceSecondsPerKm': averagePace,
      'segmentDistanceMeters': segmentDistance,
      'totalDistanceMeters': totalDistance,
      'elapsedSegmentSeconds': state.elapsedSegmentSeconds,
      'elapsedTotalSeconds': state.elapsedTotalSeconds,
      'segmentIndex': state.segmentIndex,
    };
    _logDebug('GPS sample processed', data: sampleLogData);
    if (sample.accuracyMeters > 30) {
      _logWarning('Poor GPS sample accuracy', data: sampleLogData);
    }
    if (distanceDecision.startsWith('rejected')) {
      _logWarning('GPS distance sample rejected', data: sampleLogData);
    }
    if (sample.speedMetersPerSecond > 8) {
      _logWarning('Suspicious GPS speed sample', data: sampleLogData);
    }

    final segment = state.currentSegment;
    if (segment?.targetType == SegmentTargetType.distance &&
        segmentDistance >= (segment?.distanceMeters ?? double.infinity)) {
      _logInfo(
        'Distance segment target reached',
        data: {
          ..._runStateLogData(state),
          'targetDistanceMeters': segment?.distanceMeters,
          'segmentDistanceMeters': segmentDistance,
        },
      );
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
      _logWarning(
        'Segment completion ignored in non-running phase',
        data: {..._runStateLogData(state), 'manualAdvance': manualAdvance},
      );
      return;
    }
    final workout = state.workout;
    final segment = state.currentSegment;
    if (workout == null || segment == null) {
      _logWarning(
        'Segment completion ignored because workout or segment is missing',
        data: {..._runStateLogData(state), 'manualAdvance': manualAdvance},
      );
      return;
    }

    _timer?.cancel();
    await _locationSub?.cancel();
    _locationSub = null;
    _lastSample = null;
    _paceWindow.clear();

    final results = [...state.completedSegments, _currentResult()];
    _logInfo(
      'Segment completed',
      data: {
        ..._runStateLogData(state),
        'manualAdvance': manualAdvance,
        'completedSegment': _segmentLogData(segment),
        'result': _segmentResultLogData(results.last),
      },
    );
    final nextIndex = state.segmentIndex + 1;
    if (nextIndex >= workout.segments.length) {
      await _saveRun(results);
      _disposeTracking();
      _setState(
        state.copyWith(
          phase: RunPhase.complete,
          completedSegments: results,
          statusMessage: manualAdvance ? 'Skipped and saved' : 'Run saved',
        ),
      );
      await _persistActiveRunNow();
      _logInfo(
        'Workout complete',
        data: {
          ..._runStateLogData(state),
          'manualAdvance': manualAdvance,
          'segmentResults': results.map(_segmentResultLogData).toList(),
        },
      );
      return;
    }

    _setState(
      state.copyWith(
        phase: RunPhase.countdown,
        segmentIndex: nextIndex,
        elapsedSegmentSeconds: 0,
        segmentDistanceMeters: 0,
        completedSegments: results,
        clearPace: true,
        statusMessage: 'Next segment',
      ),
    );
    _logInfo(
      'Advancing to next segment',
      data: {
        ..._runStateLogData(state),
        'nextSegment': _segmentLogData(workout.segments[nextIndex]),
      },
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
    _logInfo(
      'Run history record saved',
      data: {
        'runId': record.id,
        'workoutName': record.workoutName,
        'startedAt': record.startedAt,
        'completedAt': record.completedAt,
        'totalElapsedSeconds': record.totalElapsedSeconds,
        'totalDistanceMeters': record.totalDistanceMeters,
        'plannedSegmentCount': record.plannedSegments.length,
        'completedSegmentCount': record.segmentResults.length,
      },
    );
  }

  void _disposeTracking() {
    _logDebug('Disposing tracking resources', data: _runStateLogData(state));
    _timer?.cancel();
    _gpsLockTimer?.cancel();
    _locationSub?.cancel();
    _timer = null;
    _gpsLockTimer = null;
    _locationSub = null;
    _lastSample = null;
    _paceWindow.clear();
  }

  void _logDebug(String message, {Map<String, Object?> data = const {}}) {
    unawaited(ref.read(logServiceProvider).debug('run', message, data: data));
  }

  void _logInfo(String message, {Map<String, Object?> data = const {}}) {
    unawaited(ref.read(logServiceProvider).info('run', message, data: data));
  }

  void _logWarning(String message, {Map<String, Object?> data = const {}}) {
    unawaited(ref.read(logServiceProvider).warning('run', message, data: data));
  }

  void _logError(
    String message, {
    Map<String, Object?> data = const {},
    Object? error,
    StackTrace? stackTrace,
  }) {
    unawaited(
      ref
          .read(logServiceProvider)
          .error(
            'run',
            message,
            data: data,
            error: error,
            stackTrace: stackTrace,
          ),
    );
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

Map<String, Object?> _workoutLogData(WorkoutTemplate workout) {
  return {
    'workoutId': workout.id,
    'name': workout.name,
    'segmentCount': workout.segments.length,
    'createdAt': workout.createdAt,
    'updatedAt': workout.updatedAt,
    'segments': workout.segments.map(_segmentLogData).toList(),
  };
}

Map<String, Object?> _segmentLogData(SegmentPlan segment) {
  return {
    'segmentId': segment.id,
    'kind': segment.kind,
    'targetType': segment.targetType,
    'durationSeconds': segment.durationSeconds,
    'distanceMeters': segment.distanceMeters,
    'targetPaceSecondsPerKm': segment.targetPaceSecondsPerKm,
  };
}

Map<String, Object?> _segmentResultLogData(SegmentResult result) {
  return {
    'segmentId': result.segmentId,
    'segmentIndex': result.segmentIndex,
    'kind': result.kind,
    'plannedLabel': result.plannedLabel,
    'elapsedSeconds': result.elapsedSeconds,
    'distanceMeters': result.distanceMeters,
    'averagePaceSecondsPerKm': result.averagePaceSecondsPerKm,
    'targetPaceSecondsPerKm': result.targetPaceSecondsPerKm,
  };
}

Map<String, Object?> _gpsFixLogData(GpsFix fix) {
  return {
    'quality': fix.quality,
    'accuracyMeters': fix.accuracyMeters,
    'canStart': fix.canStart,
    'message': fix.message,
  };
}

Map<String, Object?> _runStateLogData(RunState state) {
  return {
    'phase': state.phase,
    'workoutId': state.workout?.id,
    'workoutName': state.workout?.name,
    'startedAt': state.startedAt,
    'segmentIndex': state.segmentIndex,
    'segmentCount': state.workout?.segments.length,
    'elapsedSegmentSeconds': state.elapsedSegmentSeconds,
    'elapsedTotalSeconds': state.elapsedTotalSeconds,
    'segmentDistanceMeters': state.segmentDistanceMeters,
    'totalDistanceMeters': state.totalDistanceMeters,
    'currentPaceSecondsPerKm': state.currentPaceSecondsPerKm,
    'segmentAveragePaceSecondsPerKm': state.segmentAveragePaceSecondsPerKm,
    'gpsFix': state.gpsFix == null ? null : _gpsFixLogData(state.gpsFix!),
    'allowStartAnyway': state.allowStartAnyway,
    'completedSegmentCount': state.completedSegments.length,
    'statusMessage': state.statusMessage,
    'currentSegment': state.currentSegment == null
        ? null
        : _segmentLogData(state.currentSegment!),
  };
}

Map<String, Object?> _activeRunSnapshotLogData(ActiveRunSnapshot snapshot) {
  return {
    'workout': _workoutLogData(snapshot.workout),
    'phase': snapshot.phase,
    'capturedAt': snapshot.capturedAt,
    'startedAt': snapshot.startedAt,
    'segmentIndex': snapshot.segmentIndex,
    'elapsedSegmentSeconds': snapshot.elapsedSegmentSeconds,
    'elapsedTotalSeconds': snapshot.elapsedTotalSeconds,
    'segmentDistanceMeters': snapshot.segmentDistanceMeters,
    'totalDistanceMeters': snapshot.totalDistanceMeters,
    'currentPaceSecondsPerKm': snapshot.currentPaceSecondsPerKm,
    'segmentAveragePaceSecondsPerKm': snapshot.segmentAveragePaceSecondsPerKm,
    'allowStartAnyway': snapshot.allowStartAnyway,
    'completedSegments': snapshot.completedSegments
        .map(_segmentResultLogData)
        .toList(),
  };
}
