import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class WorkoutTemplateRows extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get segmentsJson => text()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

class RunRecordRows extends Table {
  TextColumn get id => text()();
  TextColumn get workoutName => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime()();
  IntColumn get totalElapsedSeconds => integer()();
  RealColumn get totalDistanceMeters => real()();
  TextColumn get plannedSegmentsJson => text()();
  TextColumn get segmentResultsJson => text()();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

@DriftDatabase(tables: [WorkoutTemplateRows, RunRecordRows])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'runner_boi'));

  @override
  int get schemaVersion => 1;
}
