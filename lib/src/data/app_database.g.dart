// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $WorkoutTemplateRowsTable extends WorkoutTemplateRows
    with TableInfo<$WorkoutTemplateRowsTable, WorkoutTemplateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutTemplateRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _segmentsJsonMeta = const VerificationMeta(
    'segmentsJson',
  );
  @override
  late final GeneratedColumn<String> segmentsJson = GeneratedColumn<String>(
    'segments_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    createdAt,
    updatedAt,
    segmentsJson,
    archived,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_template_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutTemplateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('segments_json')) {
      context.handle(
        _segmentsJsonMeta,
        segmentsJson.isAcceptableOrUnknown(
          data['segments_json']!,
          _segmentsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_segmentsJsonMeta);
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutTemplateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutTemplateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      segmentsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}segments_json'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
    );
  }

  @override
  $WorkoutTemplateRowsTable createAlias(String alias) {
    return $WorkoutTemplateRowsTable(attachedDatabase, alias);
  }
}

class WorkoutTemplateRow extends DataClass
    implements Insertable<WorkoutTemplateRow> {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String segmentsJson;
  final bool archived;
  const WorkoutTemplateRow({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.segmentsJson,
    required this.archived,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['segments_json'] = Variable<String>(segmentsJson);
    map['archived'] = Variable<bool>(archived);
    return map;
  }

  WorkoutTemplateRowsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutTemplateRowsCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      segmentsJson: Value(segmentsJson),
      archived: Value(archived),
    );
  }

  factory WorkoutTemplateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutTemplateRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      segmentsJson: serializer.fromJson<String>(json['segmentsJson']),
      archived: serializer.fromJson<bool>(json['archived']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'segmentsJson': serializer.toJson<String>(segmentsJson),
      'archived': serializer.toJson<bool>(archived),
    };
  }

  WorkoutTemplateRow copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? segmentsJson,
    bool? archived,
  }) => WorkoutTemplateRow(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    segmentsJson: segmentsJson ?? this.segmentsJson,
    archived: archived ?? this.archived,
  );
  WorkoutTemplateRow copyWithCompanion(WorkoutTemplateRowsCompanion data) {
    return WorkoutTemplateRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      segmentsJson: data.segmentsJson.present
          ? data.segmentsJson.value
          : this.segmentsJson,
      archived: data.archived.present ? data.archived.value : this.archived,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutTemplateRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('segmentsJson: $segmentsJson, ')
          ..write('archived: $archived')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, createdAt, updatedAt, segmentsJson, archived);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutTemplateRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.segmentsJson == this.segmentsJson &&
          other.archived == this.archived);
}

class WorkoutTemplateRowsCompanion extends UpdateCompanion<WorkoutTemplateRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> segmentsJson;
  final Value<bool> archived;
  final Value<int> rowid;
  const WorkoutTemplateRowsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.segmentsJson = const Value.absent(),
    this.archived = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkoutTemplateRowsCompanion.insert({
    required String id,
    required String name,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String segmentsJson,
    this.archived = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       segmentsJson = Value(segmentsJson);
  static Insertable<WorkoutTemplateRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? segmentsJson,
    Expression<bool>? archived,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (segmentsJson != null) 'segments_json': segmentsJson,
      if (archived != null) 'archived': archived,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkoutTemplateRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? segmentsJson,
    Value<bool>? archived,
    Value<int>? rowid,
  }) {
    return WorkoutTemplateRowsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      segmentsJson: segmentsJson ?? this.segmentsJson,
      archived: archived ?? this.archived,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (segmentsJson.present) {
      map['segments_json'] = Variable<String>(segmentsJson.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutTemplateRowsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('segmentsJson: $segmentsJson, ')
          ..write('archived: $archived, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RunRecordRowsTable extends RunRecordRows
    with TableInfo<$RunRecordRowsTable, RunRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RunRecordRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workoutNameMeta = const VerificationMeta(
    'workoutName',
  );
  @override
  late final GeneratedColumn<String> workoutName = GeneratedColumn<String>(
    'workout_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalElapsedSecondsMeta =
      const VerificationMeta('totalElapsedSeconds');
  @override
  late final GeneratedColumn<int> totalElapsedSeconds = GeneratedColumn<int>(
    'total_elapsed_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalDistanceMetersMeta =
      const VerificationMeta('totalDistanceMeters');
  @override
  late final GeneratedColumn<double> totalDistanceMeters =
      GeneratedColumn<double>(
        'total_distance_meters',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _plannedSegmentsJsonMeta =
      const VerificationMeta('plannedSegmentsJson');
  @override
  late final GeneratedColumn<String> plannedSegmentsJson =
      GeneratedColumn<String>(
        'planned_segments_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _segmentResultsJsonMeta =
      const VerificationMeta('segmentResultsJson');
  @override
  late final GeneratedColumn<String> segmentResultsJson =
      GeneratedColumn<String>(
        'segment_results_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workoutName,
    startedAt,
    completedAt,
    totalElapsedSeconds,
    totalDistanceMeters,
    plannedSegmentsJson,
    segmentResultsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'run_record_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<RunRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workout_name')) {
      context.handle(
        _workoutNameMeta,
        workoutName.isAcceptableOrUnknown(
          data['workout_name']!,
          _workoutNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workoutNameMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    if (data.containsKey('total_elapsed_seconds')) {
      context.handle(
        _totalElapsedSecondsMeta,
        totalElapsedSeconds.isAcceptableOrUnknown(
          data['total_elapsed_seconds']!,
          _totalElapsedSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalElapsedSecondsMeta);
    }
    if (data.containsKey('total_distance_meters')) {
      context.handle(
        _totalDistanceMetersMeta,
        totalDistanceMeters.isAcceptableOrUnknown(
          data['total_distance_meters']!,
          _totalDistanceMetersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalDistanceMetersMeta);
    }
    if (data.containsKey('planned_segments_json')) {
      context.handle(
        _plannedSegmentsJsonMeta,
        plannedSegmentsJson.isAcceptableOrUnknown(
          data['planned_segments_json']!,
          _plannedSegmentsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_plannedSegmentsJsonMeta);
    }
    if (data.containsKey('segment_results_json')) {
      context.handle(
        _segmentResultsJsonMeta,
        segmentResultsJson.isAcceptableOrUnknown(
          data['segment_results_json']!,
          _segmentResultsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_segmentResultsJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RunRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RunRecordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workoutName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workout_name'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      )!,
      totalElapsedSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_elapsed_seconds'],
      )!,
      totalDistanceMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_distance_meters'],
      )!,
      plannedSegmentsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}planned_segments_json'],
      )!,
      segmentResultsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}segment_results_json'],
      )!,
    );
  }

  @override
  $RunRecordRowsTable createAlias(String alias) {
    return $RunRecordRowsTable(attachedDatabase, alias);
  }
}

class RunRecordRow extends DataClass implements Insertable<RunRecordRow> {
  final String id;
  final String workoutName;
  final DateTime startedAt;
  final DateTime completedAt;
  final int totalElapsedSeconds;
  final double totalDistanceMeters;
  final String plannedSegmentsJson;
  final String segmentResultsJson;
  const RunRecordRow({
    required this.id,
    required this.workoutName,
    required this.startedAt,
    required this.completedAt,
    required this.totalElapsedSeconds,
    required this.totalDistanceMeters,
    required this.plannedSegmentsJson,
    required this.segmentResultsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workout_name'] = Variable<String>(workoutName);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['completed_at'] = Variable<DateTime>(completedAt);
    map['total_elapsed_seconds'] = Variable<int>(totalElapsedSeconds);
    map['total_distance_meters'] = Variable<double>(totalDistanceMeters);
    map['planned_segments_json'] = Variable<String>(plannedSegmentsJson);
    map['segment_results_json'] = Variable<String>(segmentResultsJson);
    return map;
  }

  RunRecordRowsCompanion toCompanion(bool nullToAbsent) {
    return RunRecordRowsCompanion(
      id: Value(id),
      workoutName: Value(workoutName),
      startedAt: Value(startedAt),
      completedAt: Value(completedAt),
      totalElapsedSeconds: Value(totalElapsedSeconds),
      totalDistanceMeters: Value(totalDistanceMeters),
      plannedSegmentsJson: Value(plannedSegmentsJson),
      segmentResultsJson: Value(segmentResultsJson),
    );
  }

  factory RunRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RunRecordRow(
      id: serializer.fromJson<String>(json['id']),
      workoutName: serializer.fromJson<String>(json['workoutName']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime>(json['completedAt']),
      totalElapsedSeconds: serializer.fromJson<int>(
        json['totalElapsedSeconds'],
      ),
      totalDistanceMeters: serializer.fromJson<double>(
        json['totalDistanceMeters'],
      ),
      plannedSegmentsJson: serializer.fromJson<String>(
        json['plannedSegmentsJson'],
      ),
      segmentResultsJson: serializer.fromJson<String>(
        json['segmentResultsJson'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workoutName': serializer.toJson<String>(workoutName),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'completedAt': serializer.toJson<DateTime>(completedAt),
      'totalElapsedSeconds': serializer.toJson<int>(totalElapsedSeconds),
      'totalDistanceMeters': serializer.toJson<double>(totalDistanceMeters),
      'plannedSegmentsJson': serializer.toJson<String>(plannedSegmentsJson),
      'segmentResultsJson': serializer.toJson<String>(segmentResultsJson),
    };
  }

  RunRecordRow copyWith({
    String? id,
    String? workoutName,
    DateTime? startedAt,
    DateTime? completedAt,
    int? totalElapsedSeconds,
    double? totalDistanceMeters,
    String? plannedSegmentsJson,
    String? segmentResultsJson,
  }) => RunRecordRow(
    id: id ?? this.id,
    workoutName: workoutName ?? this.workoutName,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt ?? this.completedAt,
    totalElapsedSeconds: totalElapsedSeconds ?? this.totalElapsedSeconds,
    totalDistanceMeters: totalDistanceMeters ?? this.totalDistanceMeters,
    plannedSegmentsJson: plannedSegmentsJson ?? this.plannedSegmentsJson,
    segmentResultsJson: segmentResultsJson ?? this.segmentResultsJson,
  );
  RunRecordRow copyWithCompanion(RunRecordRowsCompanion data) {
    return RunRecordRow(
      id: data.id.present ? data.id.value : this.id,
      workoutName: data.workoutName.present
          ? data.workoutName.value
          : this.workoutName,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      totalElapsedSeconds: data.totalElapsedSeconds.present
          ? data.totalElapsedSeconds.value
          : this.totalElapsedSeconds,
      totalDistanceMeters: data.totalDistanceMeters.present
          ? data.totalDistanceMeters.value
          : this.totalDistanceMeters,
      plannedSegmentsJson: data.plannedSegmentsJson.present
          ? data.plannedSegmentsJson.value
          : this.plannedSegmentsJson,
      segmentResultsJson: data.segmentResultsJson.present
          ? data.segmentResultsJson.value
          : this.segmentResultsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RunRecordRow(')
          ..write('id: $id, ')
          ..write('workoutName: $workoutName, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('totalElapsedSeconds: $totalElapsedSeconds, ')
          ..write('totalDistanceMeters: $totalDistanceMeters, ')
          ..write('plannedSegmentsJson: $plannedSegmentsJson, ')
          ..write('segmentResultsJson: $segmentResultsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workoutName,
    startedAt,
    completedAt,
    totalElapsedSeconds,
    totalDistanceMeters,
    plannedSegmentsJson,
    segmentResultsJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RunRecordRow &&
          other.id == this.id &&
          other.workoutName == this.workoutName &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt &&
          other.totalElapsedSeconds == this.totalElapsedSeconds &&
          other.totalDistanceMeters == this.totalDistanceMeters &&
          other.plannedSegmentsJson == this.plannedSegmentsJson &&
          other.segmentResultsJson == this.segmentResultsJson);
}

class RunRecordRowsCompanion extends UpdateCompanion<RunRecordRow> {
  final Value<String> id;
  final Value<String> workoutName;
  final Value<DateTime> startedAt;
  final Value<DateTime> completedAt;
  final Value<int> totalElapsedSeconds;
  final Value<double> totalDistanceMeters;
  final Value<String> plannedSegmentsJson;
  final Value<String> segmentResultsJson;
  final Value<int> rowid;
  const RunRecordRowsCompanion({
    this.id = const Value.absent(),
    this.workoutName = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.totalElapsedSeconds = const Value.absent(),
    this.totalDistanceMeters = const Value.absent(),
    this.plannedSegmentsJson = const Value.absent(),
    this.segmentResultsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RunRecordRowsCompanion.insert({
    required String id,
    required String workoutName,
    required DateTime startedAt,
    required DateTime completedAt,
    required int totalElapsedSeconds,
    required double totalDistanceMeters,
    required String plannedSegmentsJson,
    required String segmentResultsJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workoutName = Value(workoutName),
       startedAt = Value(startedAt),
       completedAt = Value(completedAt),
       totalElapsedSeconds = Value(totalElapsedSeconds),
       totalDistanceMeters = Value(totalDistanceMeters),
       plannedSegmentsJson = Value(plannedSegmentsJson),
       segmentResultsJson = Value(segmentResultsJson);
  static Insertable<RunRecordRow> custom({
    Expression<String>? id,
    Expression<String>? workoutName,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<int>? totalElapsedSeconds,
    Expression<double>? totalDistanceMeters,
    Expression<String>? plannedSegmentsJson,
    Expression<String>? segmentResultsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workoutName != null) 'workout_name': workoutName,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (totalElapsedSeconds != null)
        'total_elapsed_seconds': totalElapsedSeconds,
      if (totalDistanceMeters != null)
        'total_distance_meters': totalDistanceMeters,
      if (plannedSegmentsJson != null)
        'planned_segments_json': plannedSegmentsJson,
      if (segmentResultsJson != null)
        'segment_results_json': segmentResultsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RunRecordRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? workoutName,
    Value<DateTime>? startedAt,
    Value<DateTime>? completedAt,
    Value<int>? totalElapsedSeconds,
    Value<double>? totalDistanceMeters,
    Value<String>? plannedSegmentsJson,
    Value<String>? segmentResultsJson,
    Value<int>? rowid,
  }) {
    return RunRecordRowsCompanion(
      id: id ?? this.id,
      workoutName: workoutName ?? this.workoutName,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      totalElapsedSeconds: totalElapsedSeconds ?? this.totalElapsedSeconds,
      totalDistanceMeters: totalDistanceMeters ?? this.totalDistanceMeters,
      plannedSegmentsJson: plannedSegmentsJson ?? this.plannedSegmentsJson,
      segmentResultsJson: segmentResultsJson ?? this.segmentResultsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workoutName.present) {
      map['workout_name'] = Variable<String>(workoutName.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (totalElapsedSeconds.present) {
      map['total_elapsed_seconds'] = Variable<int>(totalElapsedSeconds.value);
    }
    if (totalDistanceMeters.present) {
      map['total_distance_meters'] = Variable<double>(
        totalDistanceMeters.value,
      );
    }
    if (plannedSegmentsJson.present) {
      map['planned_segments_json'] = Variable<String>(
        plannedSegmentsJson.value,
      );
    }
    if (segmentResultsJson.present) {
      map['segment_results_json'] = Variable<String>(segmentResultsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RunRecordRowsCompanion(')
          ..write('id: $id, ')
          ..write('workoutName: $workoutName, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('totalElapsedSeconds: $totalElapsedSeconds, ')
          ..write('totalDistanceMeters: $totalDistanceMeters, ')
          ..write('plannedSegmentsJson: $plannedSegmentsJson, ')
          ..write('segmentResultsJson: $segmentResultsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WorkoutTemplateRowsTable workoutTemplateRows =
      $WorkoutTemplateRowsTable(this);
  late final $RunRecordRowsTable runRecordRows = $RunRecordRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    workoutTemplateRows,
    runRecordRows,
  ];
}

typedef $$WorkoutTemplateRowsTableCreateCompanionBuilder =
    WorkoutTemplateRowsCompanion Function({
      required String id,
      required String name,
      required DateTime createdAt,
      required DateTime updatedAt,
      required String segmentsJson,
      Value<bool> archived,
      Value<int> rowid,
    });
typedef $$WorkoutTemplateRowsTableUpdateCompanionBuilder =
    WorkoutTemplateRowsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String> segmentsJson,
      Value<bool> archived,
      Value<int> rowid,
    });

class $$WorkoutTemplateRowsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutTemplateRowsTable> {
  $$WorkoutTemplateRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get segmentsJson => $composableBuilder(
    column: $table.segmentsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorkoutTemplateRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutTemplateRowsTable> {
  $$WorkoutTemplateRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get segmentsJson => $composableBuilder(
    column: $table.segmentsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkoutTemplateRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutTemplateRowsTable> {
  $$WorkoutTemplateRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get segmentsJson => $composableBuilder(
    column: $table.segmentsJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);
}

class $$WorkoutTemplateRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutTemplateRowsTable,
          WorkoutTemplateRow,
          $$WorkoutTemplateRowsTableFilterComposer,
          $$WorkoutTemplateRowsTableOrderingComposer,
          $$WorkoutTemplateRowsTableAnnotationComposer,
          $$WorkoutTemplateRowsTableCreateCompanionBuilder,
          $$WorkoutTemplateRowsTableUpdateCompanionBuilder,
          (
            WorkoutTemplateRow,
            BaseReferences<
              _$AppDatabase,
              $WorkoutTemplateRowsTable,
              WorkoutTemplateRow
            >,
          ),
          WorkoutTemplateRow,
          PrefetchHooks Function()
        > {
  $$WorkoutTemplateRowsTableTableManager(
    _$AppDatabase db,
    $WorkoutTemplateRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutTemplateRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutTemplateRowsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$WorkoutTemplateRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> segmentsJson = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkoutTemplateRowsCompanion(
                id: id,
                name: name,
                createdAt: createdAt,
                updatedAt: updatedAt,
                segmentsJson: segmentsJson,
                archived: archived,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required DateTime createdAt,
                required DateTime updatedAt,
                required String segmentsJson,
                Value<bool> archived = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkoutTemplateRowsCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
                updatedAt: updatedAt,
                segmentsJson: segmentsJson,
                archived: archived,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorkoutTemplateRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutTemplateRowsTable,
      WorkoutTemplateRow,
      $$WorkoutTemplateRowsTableFilterComposer,
      $$WorkoutTemplateRowsTableOrderingComposer,
      $$WorkoutTemplateRowsTableAnnotationComposer,
      $$WorkoutTemplateRowsTableCreateCompanionBuilder,
      $$WorkoutTemplateRowsTableUpdateCompanionBuilder,
      (
        WorkoutTemplateRow,
        BaseReferences<
          _$AppDatabase,
          $WorkoutTemplateRowsTable,
          WorkoutTemplateRow
        >,
      ),
      WorkoutTemplateRow,
      PrefetchHooks Function()
    >;
typedef $$RunRecordRowsTableCreateCompanionBuilder =
    RunRecordRowsCompanion Function({
      required String id,
      required String workoutName,
      required DateTime startedAt,
      required DateTime completedAt,
      required int totalElapsedSeconds,
      required double totalDistanceMeters,
      required String plannedSegmentsJson,
      required String segmentResultsJson,
      Value<int> rowid,
    });
typedef $$RunRecordRowsTableUpdateCompanionBuilder =
    RunRecordRowsCompanion Function({
      Value<String> id,
      Value<String> workoutName,
      Value<DateTime> startedAt,
      Value<DateTime> completedAt,
      Value<int> totalElapsedSeconds,
      Value<double> totalDistanceMeters,
      Value<String> plannedSegmentsJson,
      Value<String> segmentResultsJson,
      Value<int> rowid,
    });

class $$RunRecordRowsTableFilterComposer
    extends Composer<_$AppDatabase, $RunRecordRowsTable> {
  $$RunRecordRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workoutName => $composableBuilder(
    column: $table.workoutName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalElapsedSeconds => $composableBuilder(
    column: $table.totalElapsedSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalDistanceMeters => $composableBuilder(
    column: $table.totalDistanceMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plannedSegmentsJson => $composableBuilder(
    column: $table.plannedSegmentsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get segmentResultsJson => $composableBuilder(
    column: $table.segmentResultsJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RunRecordRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $RunRecordRowsTable> {
  $$RunRecordRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workoutName => $composableBuilder(
    column: $table.workoutName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalElapsedSeconds => $composableBuilder(
    column: $table.totalElapsedSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalDistanceMeters => $composableBuilder(
    column: $table.totalDistanceMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plannedSegmentsJson => $composableBuilder(
    column: $table.plannedSegmentsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get segmentResultsJson => $composableBuilder(
    column: $table.segmentResultsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RunRecordRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RunRecordRowsTable> {
  $$RunRecordRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get workoutName => $composableBuilder(
    column: $table.workoutName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalElapsedSeconds => $composableBuilder(
    column: $table.totalElapsedSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalDistanceMeters => $composableBuilder(
    column: $table.totalDistanceMeters,
    builder: (column) => column,
  );

  GeneratedColumn<String> get plannedSegmentsJson => $composableBuilder(
    column: $table.plannedSegmentsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get segmentResultsJson => $composableBuilder(
    column: $table.segmentResultsJson,
    builder: (column) => column,
  );
}

class $$RunRecordRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RunRecordRowsTable,
          RunRecordRow,
          $$RunRecordRowsTableFilterComposer,
          $$RunRecordRowsTableOrderingComposer,
          $$RunRecordRowsTableAnnotationComposer,
          $$RunRecordRowsTableCreateCompanionBuilder,
          $$RunRecordRowsTableUpdateCompanionBuilder,
          (
            RunRecordRow,
            BaseReferences<_$AppDatabase, $RunRecordRowsTable, RunRecordRow>,
          ),
          RunRecordRow,
          PrefetchHooks Function()
        > {
  $$RunRecordRowsTableTableManager(_$AppDatabase db, $RunRecordRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RunRecordRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RunRecordRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RunRecordRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workoutName = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime> completedAt = const Value.absent(),
                Value<int> totalElapsedSeconds = const Value.absent(),
                Value<double> totalDistanceMeters = const Value.absent(),
                Value<String> plannedSegmentsJson = const Value.absent(),
                Value<String> segmentResultsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RunRecordRowsCompanion(
                id: id,
                workoutName: workoutName,
                startedAt: startedAt,
                completedAt: completedAt,
                totalElapsedSeconds: totalElapsedSeconds,
                totalDistanceMeters: totalDistanceMeters,
                plannedSegmentsJson: plannedSegmentsJson,
                segmentResultsJson: segmentResultsJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workoutName,
                required DateTime startedAt,
                required DateTime completedAt,
                required int totalElapsedSeconds,
                required double totalDistanceMeters,
                required String plannedSegmentsJson,
                required String segmentResultsJson,
                Value<int> rowid = const Value.absent(),
              }) => RunRecordRowsCompanion.insert(
                id: id,
                workoutName: workoutName,
                startedAt: startedAt,
                completedAt: completedAt,
                totalElapsedSeconds: totalElapsedSeconds,
                totalDistanceMeters: totalDistanceMeters,
                plannedSegmentsJson: plannedSegmentsJson,
                segmentResultsJson: segmentResultsJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RunRecordRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RunRecordRowsTable,
      RunRecordRow,
      $$RunRecordRowsTableFilterComposer,
      $$RunRecordRowsTableOrderingComposer,
      $$RunRecordRowsTableAnnotationComposer,
      $$RunRecordRowsTableCreateCompanionBuilder,
      $$RunRecordRowsTableUpdateCompanionBuilder,
      (
        RunRecordRow,
        BaseReferences<_$AppDatabase, $RunRecordRowsTable, RunRecordRow>,
      ),
      RunRecordRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WorkoutTemplateRowsTableTableManager get workoutTemplateRows =>
      $$WorkoutTemplateRowsTableTableManager(_db, _db.workoutTemplateRows);
  $$RunRecordRowsTableTableManager get runRecordRows =>
      $$RunRecordRowsTableTableManager(_db, _db.runRecordRows);
}
