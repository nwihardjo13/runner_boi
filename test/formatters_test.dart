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

  test('manual segment cue uses requested phrase', () {
    final segment = SegmentPlan(
      id: 'segment-1',
      kind: SegmentKind.rest,
      targetType: SegmentTargetType.manual,
    );

    expect(segmentCue(segment, MeasurementSystem.metric), 'fuck about segment');
  });
}
