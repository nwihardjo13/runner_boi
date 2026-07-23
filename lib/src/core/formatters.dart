import '../domain/models.dart';

const metersPerMile = 1609.344;

String formatDurationClock(int seconds) {
  final clamped = seconds.clamp(0, 24 * 60 * 60);
  final hours = clamped ~/ 3600;
  final minutes = (clamped % 3600) ~/ 60;
  final secs = clamped % 60;
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
  return '$minutes:${secs.toString().padLeft(2, '0')}';
}

String formatDistance(double meters, MeasurementSystem units) {
  if (units == MeasurementSystem.imperial) {
    final miles = meters / metersPerMile;
    return '${miles.toStringAsFixed(miles < 10 ? 2 : 1)} mi';
  }
  if (meters < 1000) {
    return '${meters.round()} m';
  }
  final km = meters / 1000;
  return '${km.toStringAsFixed(km < 10 ? 2 : 1)} km';
}

String formatPace(double? secondsPerKm, MeasurementSystem units) {
  if (secondsPerKm == null || secondsPerKm.isNaN || secondsPerKm.isInfinite) {
    return '--';
  }
  final secondsPerUnit = units == MeasurementSystem.imperial
      ? secondsPerKm * metersPerMile / 1000
      : secondsPerKm;
  final minutes = secondsPerUnit ~/ 60;
  final seconds = secondsPerUnit.round() % 60;
  final suffix = units == MeasurementSystem.imperial ? '/mi' : '/km';
  return '$minutes:${seconds.toString().padLeft(2, '0')} $suffix';
}

double? paceInputToSecondsPerKm({
  required int minutes,
  required int seconds,
  required MeasurementSystem units,
}) {
  final totalSeconds = minutes * 60 + seconds;
  if (totalSeconds <= 0) return null;
  if (units == MeasurementSystem.imperial) {
    return totalSeconds * 1000 / metersPerMile;
  }
  return totalSeconds.toDouble();
}

double distanceInputToMeters(double value, MeasurementSystem units) {
  if (units == MeasurementSystem.imperial) {
    return value * metersPerMile;
  }
  return value >= 1 ? value * 1000 : value * 1000;
}

String formatSegmentTarget(SegmentPlan segment, MeasurementSystem units) {
  return switch (segment.targetType) {
    SegmentTargetType.time => formatDurationClock(segment.durationSeconds ?? 0),
    SegmentTargetType.distance => formatDistance(
      segment.distanceMeters ?? 0,
      units,
    ),
    SegmentTargetType.manual => 'manual',
  };
}

String segmentCue(SegmentPlan segment, MeasurementSystem units) {
  if (segment.isManual) {
    return 'fuck about segment';
  }
  final target = formatSegmentTarget(segment, units);
  final kind = segment.kind == SegmentKind.rest ? 'rest' : 'run';
  final pace = segment.targetPaceSecondsPerKm == null
      ? ''
      : ' at ${formatPace(segment.targetPaceSecondsPerKm, units)}';
  return '$kind $target$pace';
}

String formatGpsAccuracy(double? accuracyMeters) {
  if (accuracyMeters == null) return '--';
  return '${accuracyMeters.round()} m';
}

String plannedSummary(List<SegmentPlan> segments, MeasurementSystem units) {
  if (segments.isEmpty) return 'No segments';
  final totalDistance = segments.fold<double>(
    0,
    (sum, segment) => sum + (segment.distanceMeters ?? 0),
  );
  final totalTime = segments.fold<int>(
    0,
    (sum, segment) => sum + (segment.durationSeconds ?? 0),
  );
  final parts = <String>[
    '${segments.length} segments',
    if (totalDistance > 0) formatDistance(totalDistance, units),
    if (totalTime > 0) formatDurationClock(totalTime),
  ];
  return parts.join(' · ');
}
