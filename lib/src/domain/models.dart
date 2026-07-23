import 'dart:convert';

enum MeasurementSystem { metric, imperial }

enum PaceDisplayMode { instant, smoothed5, smoothed10 }

enum SegmentKind { run, rest }

enum SegmentTargetType { time, distance, manual }

enum GpsQuality { excellent, good, weak, bad, unavailable }

enum RunPhase { idle, gpsLock, countdown, running, paused, complete }

class AppSettings {
  const AppSettings({
    required this.measurementSystem,
    required this.paceDisplayMode,
    required this.countdownSeconds,
    required this.voiceCuesEnabled,
    required this.duckAudio,
  });

  factory AppSettings.defaults(LocaleLike locale) {
    return AppSettings(
      measurementSystem: locale.usesImperial
          ? MeasurementSystem.imperial
          : MeasurementSystem.metric,
      paceDisplayMode: PaceDisplayMode.instant,
      countdownSeconds: 3,
      voiceCuesEnabled: true,
      duckAudio: true,
    );
  }

  final MeasurementSystem measurementSystem;
  final PaceDisplayMode paceDisplayMode;
  final int countdownSeconds;
  final bool voiceCuesEnabled;
  final bool duckAudio;

  AppSettings copyWith({
    MeasurementSystem? measurementSystem,
    PaceDisplayMode? paceDisplayMode,
    int? countdownSeconds,
    bool? voiceCuesEnabled,
    bool? duckAudio,
  }) {
    return AppSettings(
      measurementSystem: measurementSystem ?? this.measurementSystem,
      paceDisplayMode: paceDisplayMode ?? this.paceDisplayMode,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      voiceCuesEnabled: voiceCuesEnabled ?? this.voiceCuesEnabled,
      duckAudio: duckAudio ?? this.duckAudio,
    );
  }
}

class LocaleLike {
  const LocaleLike(this.countryCode);

  final String? countryCode;

  bool get usesImperial {
    return const {'US', 'LR', 'MM'}.contains(countryCode?.toUpperCase());
  }
}

class SegmentPlan {
  const SegmentPlan({
    required this.id,
    required this.kind,
    required this.targetType,
    this.label,
    this.distanceMeters,
    this.durationSeconds,
    this.targetPaceSecondsPerKm,
  });

  factory SegmentPlan.fromJson(Map<String, Object?> json) {
    return SegmentPlan(
      id: json['id'] as String,
      kind: SegmentKind.values.byName(json['kind'] as String),
      targetType: SegmentTargetType.values.byName(json['targetType'] as String),
      label: json['label'] as String?,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      targetPaceSecondsPerKm: (json['targetPaceSecondsPerKm'] as num?)
          ?.toDouble(),
    );
  }

  final String id;
  final SegmentKind kind;
  final SegmentTargetType targetType;
  final String? label;
  final double? distanceMeters;
  final int? durationSeconds;
  final double? targetPaceSecondsPerKm;

  bool get isManual => targetType == SegmentTargetType.manual;

  SegmentPlan copyWith({
    String? id,
    SegmentKind? kind,
    SegmentTargetType? targetType,
    String? label,
    double? distanceMeters,
    int? durationSeconds,
    double? targetPaceSecondsPerKm,
    bool clearDistance = false,
    bool clearDuration = false,
    bool clearPace = false,
  }) {
    return SegmentPlan(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      targetType: targetType ?? this.targetType,
      label: label ?? this.label,
      distanceMeters: clearDistance
          ? null
          : distanceMeters ?? this.distanceMeters,
      durationSeconds: clearDuration
          ? null
          : durationSeconds ?? this.durationSeconds,
      targetPaceSecondsPerKm: clearPace
          ? null
          : targetPaceSecondsPerKm ?? this.targetPaceSecondsPerKm,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'kind': kind.name,
      'targetType': targetType.name,
      'label': label,
      'distanceMeters': distanceMeters,
      'durationSeconds': durationSeconds,
      'targetPaceSecondsPerKm': targetPaceSecondsPerKm,
    };
  }
}

class WorkoutTemplate {
  const WorkoutTemplate({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.segments,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<SegmentPlan> segments;

  WorkoutTemplate copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<SegmentPlan>? segments,
  }) {
    return WorkoutTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      segments: segments ?? this.segments,
    );
  }
}

class SegmentResult {
  const SegmentResult({
    required this.segmentId,
    required this.segmentIndex,
    required this.kind,
    required this.plannedLabel,
    required this.elapsedSeconds,
    required this.distanceMeters,
    this.averagePaceSecondsPerKm,
    this.targetPaceSecondsPerKm,
  });

  factory SegmentResult.fromJson(Map<String, Object?> json) {
    return SegmentResult(
      segmentId: json['segmentId'] as String,
      segmentIndex: (json['segmentIndex'] as num).toInt(),
      kind: SegmentKind.values.byName(json['kind'] as String),
      plannedLabel: json['plannedLabel'] as String,
      elapsedSeconds: (json['elapsedSeconds'] as num).toInt(),
      distanceMeters: (json['distanceMeters'] as num).toDouble(),
      averagePaceSecondsPerKm: (json['averagePaceSecondsPerKm'] as num?)
          ?.toDouble(),
      targetPaceSecondsPerKm: (json['targetPaceSecondsPerKm'] as num?)
          ?.toDouble(),
    );
  }

  final String segmentId;
  final int segmentIndex;
  final SegmentKind kind;
  final String plannedLabel;
  final int elapsedSeconds;
  final double distanceMeters;
  final double? averagePaceSecondsPerKm;
  final double? targetPaceSecondsPerKm;

  Map<String, Object?> toJson() {
    return {
      'segmentId': segmentId,
      'segmentIndex': segmentIndex,
      'kind': kind.name,
      'plannedLabel': plannedLabel,
      'elapsedSeconds': elapsedSeconds,
      'distanceMeters': distanceMeters,
      'averagePaceSecondsPerKm': averagePaceSecondsPerKm,
      'targetPaceSecondsPerKm': targetPaceSecondsPerKm,
    };
  }
}

class RunRecord {
  const RunRecord({
    required this.id,
    required this.workoutName,
    required this.startedAt,
    required this.completedAt,
    required this.totalElapsedSeconds,
    required this.totalDistanceMeters,
    required this.plannedSegments,
    required this.segmentResults,
  });

  final String id;
  final String workoutName;
  final DateTime startedAt;
  final DateTime completedAt;
  final int totalElapsedSeconds;
  final double totalDistanceMeters;
  final List<SegmentPlan> plannedSegments;
  final List<SegmentResult> segmentResults;

  double? get averagePaceSecondsPerKm {
    if (totalDistanceMeters < 5 || totalElapsedSeconds <= 0) return null;
    return totalElapsedSeconds / (totalDistanceMeters / 1000);
  }
}

String encodeSegments(List<SegmentPlan> segments) {
  return jsonEncode(segments.map((segment) => segment.toJson()).toList());
}

List<SegmentPlan> decodeSegments(String payload) {
  final raw = jsonDecode(payload) as List<Object?>;
  return raw.cast<Map<String, Object?>>().map(SegmentPlan.fromJson).toList();
}

String encodeSegmentResults(List<SegmentResult> results) {
  return jsonEncode(results.map((result) => result.toJson()).toList());
}

List<SegmentResult> decodeSegmentResults(String payload) {
  final raw = jsonDecode(payload) as List<Object?>;
  return raw.cast<Map<String, Object?>>().map(SegmentResult.fromJson).toList();
}
