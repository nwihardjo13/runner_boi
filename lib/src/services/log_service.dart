import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

enum AppLogLevel { debug, info, warning, error }

class AppLogService {
  AppLogService({Directory? rootDirectory, DateTime Function()? clock})
    : _rootDirectoryOverride = rootDirectory,
      _clock = clock ?? DateTime.now {
    sessionStartedAt = _clock().toUtc();
    sessionId = _fileTimestamp(sessionStartedAt);
  }

  static const maxRetainedLogs = 10;
  static const _logsDirectoryName = 'logs';
  static const _filePrefix = 'runner-boi-';
  static const _fileSuffix = '.log.jsonl';

  final Directory? _rootDirectoryOverride;
  final DateTime Function() _clock;
  late final DateTime sessionStartedAt;
  late final String sessionId;
  Future<void>? _startFuture;
  Future<void> _writeChain = Future.value();
  File? _sessionFile;
  var _disposed = false;

  Future<void> start() {
    return _startFuture ??= _start();
  }

  Future<void> debug(
    String component,
    String message, {
    Map<String, Object?> data = const {},
  }) {
    return log(AppLogLevel.debug, component, message, data: data);
  }

  Future<void> info(
    String component,
    String message, {
    Map<String, Object?> data = const {},
  }) {
    return log(AppLogLevel.info, component, message, data: data);
  }

  Future<void> warning(
    String component,
    String message, {
    Map<String, Object?> data = const {},
    Object? error,
    StackTrace? stackTrace,
  }) {
    return log(
      AppLogLevel.warning,
      component,
      message,
      data: data,
      error: error,
      stackTrace: stackTrace,
    );
  }

  Future<void> error(
    String component,
    String message, {
    Map<String, Object?> data = const {},
    Object? error,
    StackTrace? stackTrace,
  }) {
    return log(
      AppLogLevel.error,
      component,
      message,
      data: data,
      error: error,
      stackTrace: stackTrace,
    );
  }

  Future<void> log(
    AppLogLevel level,
    String component,
    String message, {
    Map<String, Object?> data = const {},
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (_disposed) return Future.value();
    final entry = <String, Object?>{
      'timestamp': _clock().toUtc().toIso8601String(),
      'level': level.name,
      'component': component,
      'message': message,
      'sessionId': sessionId,
      if (data.isNotEmpty) 'data': _sanitize(data),
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
    };
    _writeChain = _writeChain
        .catchError((Object error, StackTrace stackTrace) {})
        .then((_) async {
          await start();
          final file = _sessionFile;
          if (file == null) return;
          await _append(file, entry);
        });
    unawaited(
      _writeChain.catchError((Object error, StackTrace stackTrace) {
        developer.log(
          'Failed to write Runner Boi log',
          name: 'runner_boi.log',
          error: error,
          stackTrace: stackTrace,
        );
      }),
    );
    return _writeChain;
  }

  Future<List<File>> exportFiles() async {
    await info('diagnostics', 'Diagnostics log export requested');
    await flush();
    final directory = await _logsDirectory();
    final files = await _logFiles(directory);
    files.sort(
      (a, b) => path.basename(b.path).compareTo(path.basename(a.path)),
    );
    return files;
  }

  Future<List<File>> retainedFiles() async {
    await flush();
    final directory = await _logsDirectory();
    final files = await _logFiles(directory);
    files.sort(
      (a, b) => path.basename(b.path).compareTo(path.basename(a.path)),
    );
    return files;
  }

  Future<void> flush() {
    return _writeChain.catchError((Object error, StackTrace stackTrace) {});
  }

  Future<void> dispose() async {
    if (_disposed) return;
    await info('app', 'Log session disposed');
    _disposed = true;
    await flush();
  }

  Future<void> _start() async {
    final directory = await _logsDirectory();
    await directory.create(recursive: true);
    final file = File(
      path.join(directory.path, '$_filePrefix$sessionId$_fileSuffix'),
    );
    await file.create(recursive: true);
    _sessionFile = file;
    final prunedLogCount = await _pruneLogs(directory);
    await _append(file, {
      'timestamp': sessionStartedAt.toIso8601String(),
      'level': AppLogLevel.info.name,
      'component': 'app',
      'message': 'Log session started',
      'sessionId': sessionId,
      'data': {
        'maxRetainedLogs': maxRetainedLogs,
        'fileName': path.basename(file.path),
        'prunedLogCount': prunedLogCount,
      },
    });
  }

  Future<Directory> _logsDirectory() async {
    final root =
        _rootDirectoryOverride ?? await getApplicationSupportDirectory();
    return Directory(path.join(root.path, _logsDirectoryName));
  }

  Future<void> _append(File file, Map<String, Object?> entry) async {
    await file.writeAsString(
      '${jsonEncode(entry)}\n',
      mode: FileMode.append,
      flush: true,
    );
  }

  Future<List<File>> _logFiles(Directory directory) async {
    if (!await directory.exists()) return [];
    final files = <File>[];
    await for (final entity in directory.list()) {
      if (entity is! File) continue;
      final name = path.basename(entity.path);
      if (name.startsWith(_filePrefix) && name.endsWith(_fileSuffix)) {
        files.add(entity);
      }
    }
    return files;
  }

  Future<int> _pruneLogs(Directory directory) async {
    final files = await _logFiles(directory);
    files.sort(
      (a, b) => path.basename(b.path).compareTo(path.basename(a.path)),
    );
    var deleted = 0;
    for (final file in files.skip(maxRetainedLogs)) {
      try {
        await file.delete();
        deleted++;
      } catch (error, stackTrace) {
        developer.log(
          'Failed to prune Runner Boi log',
          name: 'runner_boi.log',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    return deleted;
  }

  Object? _sanitize(Object? value) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    if (value is DateTime) return value.toUtc().toIso8601String();
    if (value is Duration) return value.inMilliseconds;
    if (value is Enum) return value.name;
    if (value is Iterable) {
      return value.map(_sanitize).toList(growable: false);
    }
    if (value is Map) {
      return value.map(
        (key, mapValue) => MapEntry(key.toString(), _sanitize(mapValue)),
      );
    }
    return value.toString();
  }

  static String _fileTimestamp(DateTime value) {
    return value
        .toUtc()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
  }
}
