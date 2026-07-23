import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';
import 'app_database.dart';

class WorkoutRepository {
  WorkoutRepository(this._db);

  final AppDatabase _db;

  Stream<List<WorkoutTemplate>> watchTemplates() {
    final query = _db.select(_db.workoutTemplateRows)
      ..where((row) => row.archived.equals(false))
      ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)]);
    return query.watch().map((rows) => rows.map(_templateFromRow).toList());
  }

  Future<List<WorkoutTemplate>> listTemplates() async {
    final query = _db.select(_db.workoutTemplateRows)
      ..where((row) => row.archived.equals(false))
      ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)]);
    final rows = await query.get();
    return rows.map(_templateFromRow).toList();
  }

  Future<void> saveTemplate(WorkoutTemplate template) async {
    await _db
        .into(_db.workoutTemplateRows)
        .insertOnConflictUpdate(
          WorkoutTemplateRowsCompanion(
            id: Value(template.id),
            name: Value(template.name),
            createdAt: Value(template.createdAt),
            updatedAt: Value(template.updatedAt),
            segmentsJson: Value(encodeSegments(template.segments)),
            archived: const Value(false),
          ),
        );
  }

  Future<void> deleteTemplate(String id) async {
    await (_db.update(_db.workoutTemplateRows)
          ..where((row) => row.id.equals(id)))
        .write(const WorkoutTemplateRowsCompanion(archived: Value(true)));
  }

  WorkoutTemplate _templateFromRow(WorkoutTemplateRow row) {
    return WorkoutTemplate(
      id: row.id,
      name: row.name,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      segments: decodeSegments(row.segmentsJson),
    );
  }
}

class RunHistoryRepository {
  RunHistoryRepository(this._db);

  final AppDatabase _db;

  Stream<List<RunRecord>> watchRuns() {
    final query = _db.select(_db.runRecordRows)
      ..orderBy([(row) => OrderingTerm.desc(row.startedAt)]);
    return query.watch().map((rows) => rows.map(_runFromRow).toList());
  }

  Future<void> saveRun(RunRecord run) async {
    await _db
        .into(_db.runRecordRows)
        .insertOnConflictUpdate(
          RunRecordRowsCompanion(
            id: Value(run.id),
            workoutName: Value(run.workoutName),
            startedAt: Value(run.startedAt),
            completedAt: Value(run.completedAt),
            totalElapsedSeconds: Value(run.totalElapsedSeconds),
            totalDistanceMeters: Value(run.totalDistanceMeters),
            plannedSegmentsJson: Value(encodeSegments(run.plannedSegments)),
            segmentResultsJson: Value(encodeSegmentResults(run.segmentResults)),
          ),
        );
  }

  Future<void> deleteRun(String id) async {
    await (_db.delete(
      _db.runRecordRows,
    )..where((row) => row.id.equals(id))).go();
  }

  Future<void> deleteAllRuns() async {
    await _db.delete(_db.runRecordRows).go();
  }

  RunRecord _runFromRow(RunRecordRow row) {
    return RunRecord(
      id: row.id,
      workoutName: row.workoutName,
      startedAt: row.startedAt,
      completedAt: row.completedAt,
      totalElapsedSeconds: row.totalElapsedSeconds,
      totalDistanceMeters: row.totalDistanceMeters,
      plannedSegments: decodeSegments(row.plannedSegmentsJson),
      segmentResults: decodeSegmentResults(row.segmentResultsJson),
    );
  }
}

class SettingsRepository {
  SettingsRepository(this._prefs, this._locale);

  static const _unitsKey = 'units';
  static const _paceModeKey = 'pace_display_mode';
  static const _countdownKey = 'countdown_seconds';
  static const _voiceKey = 'voice_cues';
  static const _duckAudioKey = 'duck_audio';

  final SharedPreferences _prefs;
  final LocaleLike _locale;

  AppSettings load() {
    final defaults = AppSettings.defaults(_locale);
    return AppSettings(
      measurementSystem: _enumValue(
        MeasurementSystem.values,
        _prefs.getString(_unitsKey),
        defaults.measurementSystem,
      ),
      paceDisplayMode: _enumValue(
        PaceDisplayMode.values,
        _prefs.getString(_paceModeKey),
        defaults.paceDisplayMode,
      ),
      countdownSeconds:
          _prefs.getInt(_countdownKey) ?? defaults.countdownSeconds,
      voiceCuesEnabled: _prefs.getBool(_voiceKey) ?? defaults.voiceCuesEnabled,
      duckAudio: _prefs.getBool(_duckAudioKey) ?? defaults.duckAudio,
    );
  }

  Future<void> save(AppSettings settings) async {
    await _prefs.setString(_unitsKey, settings.measurementSystem.name);
    await _prefs.setString(_paceModeKey, settings.paceDisplayMode.name);
    await _prefs.setInt(_countdownKey, settings.countdownSeconds);
    await _prefs.setBool(_voiceKey, settings.voiceCuesEnabled);
    await _prefs.setBool(_duckAudioKey, settings.duckAudio);
  }

  T _enumValue<T extends Enum>(List<T> values, String? name, T fallback) {
    if (name == null) return fallback;
    return values.where((value) => value.name == name).firstOrNull ?? fallback;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
