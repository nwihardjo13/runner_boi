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

String formatDurationSpeech(int seconds) {
  final clamped = seconds.clamp(0, 24 * 60 * 60);
  final hours = clamped ~/ 3600;
  final minutes = (clamped % 3600) ~/ 60;
  final secs = clamped % 60;
  final parts = <String>[
    if (hours > 0) _plural(hours, 'hour'),
    if (minutes > 0) _plural(minutes, 'minute'),
    if (secs > 0 || (hours == 0 && minutes == 0)) _plural(secs, 'second'),
  ];
  return parts.join(' ');
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

String formatDistanceSpeech(double meters, MeasurementSystem units) {
  if (units == MeasurementSystem.imperial) {
    final miles = meters / metersPerMile;
    final rounded = miles < 10
        ? miles.toStringAsFixed(2)
        : miles.toStringAsFixed(1);
    return '$rounded ${miles == 1 ? 'mile' : 'miles'}';
  }
  if (meters < 1000) {
    final roundedMeters = meters.round();
    return '$roundedMeters ${roundedMeters == 1 ? 'meter' : 'meters'}';
  }
  final km = meters / 1000;
  final rounded = km < 10 ? km.toStringAsFixed(2) : km.toStringAsFixed(1);
  return '$rounded kilometers';
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

String formatPaceSpeech(double? secondsPerKm, MeasurementSystem units) {
  if (secondsPerKm == null || secondsPerKm.isNaN || secondsPerKm.isInfinite) {
    return 'no pace';
  }
  final secondsPerUnit = units == MeasurementSystem.imperial
      ? secondsPerKm * metersPerMile / 1000
      : secondsPerKm;
  final totalSeconds = secondsPerUnit.round();
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  final unit = units == MeasurementSystem.imperial ? 'mile' : 'kilometer';
  final parts = <String>[
    if (minutes > 0) _plural(minutes, 'minute'),
    if (seconds > 0 || minutes == 0) _plural(seconds, 'second'),
  ];
  return '${parts.join(' ')} per $unit';
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

String segmentCueSpeech(SegmentPlan segment, MeasurementSystem units) {
  if (segment.isManual) {
    return 'fuck about segment';
  }
  final kind = segment.kind == SegmentKind.rest ? 'rest' : 'run';
  final target = switch (segment.targetType) {
    SegmentTargetType.time => formatDurationSpeech(
      segment.durationSeconds ?? 0,
    ),
    SegmentTargetType.distance => formatDistanceSpeech(
      segment.distanceMeters ?? 0,
      units,
    ),
    SegmentTargetType.manual => 'manual',
  };
  final pace = segment.targetPaceSecondsPerKm == null
      ? ''
      : ' at ${formatPaceSpeech(segment.targetPaceSecondsPerKm, units)}';
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

String _plural(int value, String unit) {
  return '$value $unit${value == 1 ? '' : 's'}';
}
