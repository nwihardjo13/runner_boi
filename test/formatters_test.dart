import 'package:flutter_test/flutter_test.dart';
import 'package:runner_boi/src/core/formatters.dart';
import 'package:runner_boi/src/domain/models.dart';

void main() {
  test('formats metric distances with meters below one km', () {
    expect(formatDistance(400, MeasurementSystem.metric), '400 m');
    expect(formatDistance(1200, MeasurementSystem.metric), '1.20 km');
  });

  test('formats pace in selected unit system', () {
    expect(formatPace(300, MeasurementSystem.metric), '5:00 /km');
    expect(formatPace(300, MeasurementSystem.imperial), '8:03 /mi');
  });

  test('formats duration and pace for speech', () {
    expect(formatDurationSpeech(120), '2 minutes');
    expect(formatDurationSpeech(3723), '1 hour 2 minutes 3 seconds');
    expect(
      formatPaceSpeech(300, MeasurementSystem.metric),
      '5 minutes per kilometer',
    );
  });

  test('segment cue speech avoids clock-style time', () {
    const segment = SegmentPlan(
      id: 'segment-1',
      kind: SegmentKind.run,
      targetType: SegmentTargetType.time,
      durationSeconds: 120,
      targetPaceSecondsPerKm: 300,
    );

    expect(
      segmentCueSpeech(segment, MeasurementSystem.metric),
      'run 2 minutes at 5 minutes per kilometer',
    );
  });

  test('manual segment cue uses requested phrase', () {
    final segment = SegmentPlan(
      id: 'segment-1',
      kind: SegmentKind.rest,
      targetType: SegmentTargetType.manual,
    );

    expect(segmentCue(segment, MeasurementSystem.metric), 'fuck about segment');
  });
}
