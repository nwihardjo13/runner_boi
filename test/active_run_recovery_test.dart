import 'package:flutter_test/flutter_test.dart';
import 'package:runner_boi/src/data/repositories.dart';
import 'package:runner_boi/src/domain/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('active run snapshot round trips through json', () {
    final snapshot = _snapshot();

    final restored = decodeActiveRunSnapshot(encodeActiveRunSnapshot(snapshot));

    expect(restored.workout.name, 'Track ladder');
    expect(restored.phase, RunPhase.running);
    expect(restored.startedAt, DateTime.utc(2026, 8, 31, 7, 0));
    expect(restored.segmentIndex, 1);
    expect(restored.elapsedSegmentSeconds, 90);
    expect(restored.elapsedTotalSeconds, 390);
    expect(restored.segmentDistanceMeters, 260);
    expect(restored.totalDistanceMeters, 1260);
    expect(restored.segmentAveragePaceSecondsPerKm, 346);
    expect(restored.completedSegments.single.plannedLabel, 'Run 1.00 km');
  });

  test(
    'active run repository stores, loads, and clears the snapshot',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = ActiveRunRepository(prefs);

      await repository.save(_snapshot());

      final restored = await repository.load();
      expect(restored, isNotNull);
      expect(restored!.workout.id, 'workout-1');

      await repository.clear();

      expect(await repository.load(), isNull);
    },
  );

  test('active run repository drops malformed snapshots', () async {
    SharedPreferences.setMockInitialValues({
      'active_run_snapshot_v1': 'not-json',
    });
    final prefs = await SharedPreferences.getInstance();
    final repository = ActiveRunRepository(prefs);

    expect(await repository.load(), isNull);
    expect(prefs.containsKey('active_run_snapshot_v1'), isFalse);
  });
}

ActiveRunSnapshot _snapshot() {
  return ActiveRunSnapshot(
    workout: WorkoutTemplate(
      id: 'workout-1',
      name: 'Track ladder',
      createdAt: DateTime.utc(2026, 8, 31, 6, 30),
      updatedAt: DateTime.utc(2026, 8, 31, 6, 45),
      segments: const [
        SegmentPlan(
          id: 'segment-1',
          kind: SegmentKind.run,
          targetType: SegmentTargetType.distance,
          distanceMeters: 1000,
        ),
        SegmentPlan(
          id: 'segment-2',
          kind: SegmentKind.rest,
          targetType: SegmentTargetType.time,
          durationSeconds: 120,
        ),
      ],
    ),
    phase: RunPhase.running,
    capturedAt: DateTime.utc(2026, 8, 31, 7, 6, 30),
    startedAt: DateTime.utc(2026, 8, 31, 7, 0),
    segmentIndex: 1,
    elapsedSegmentSeconds: 90,
    elapsedTotalSeconds: 390,
    segmentDistanceMeters: 260,
    totalDistanceMeters: 1260,
    currentPaceSecondsPerKm: 320,
    segmentAveragePaceSecondsPerKm: 346,
    completedSegments: const [
      SegmentResult(
        segmentId: 'segment-1',
        segmentIndex: 0,
        kind: SegmentKind.run,
        plannedLabel: 'Run 1.00 km',
        elapsedSeconds: 300,
        distanceMeters: 1000,
        averagePaceSecondsPerKm: 300,
      ),
    ],
  );
}
