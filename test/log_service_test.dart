import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:runner_boi/src/services/log_service.dart';

void main() {
  test('writes structured session logs and exports retained files', () async {
    final root = await Directory.systemTemp.createTemp('runner_boi_logs_test_');
    addTearDown(() => root.delete(recursive: true));
    final service = AppLogService(
      rootDirectory: root,
      clock: () => DateTime.utc(2026, 9, 14, 7, 0),
    );

    await service.start();
    await service.info(
      'gps',
      'Sample processed',
      data: {
        'accuracyMeters': 8.5,
        'paceSecondsPerKm': 300,
        'sampledAt': DateTime.utc(2026, 9, 14, 7, 1),
      },
    );

    final files = await service.exportFiles();
    expect(files, hasLength(1));
    expect(path.basename(files.single.path), endsWith('.log.jsonl'));

    final entries = (await files.single.readAsLines())
        .map((line) => jsonDecode(line) as Map<String, Object?>)
        .toList();
    expect(entries.first['message'], 'Log session started');
    expect(
      entries.any(
        (entry) =>
            entry['component'] == 'gps' &&
            entry['message'] == 'Sample processed',
      ),
      isTrue,
    );
    expect(
      entries.any(
        (entry) =>
            entry['component'] == 'diagnostics' &&
            entry['message'] == 'Diagnostics log export requested',
      ),
      isTrue,
    );
  });

  test('keeps only the last ten session log files', () async {
    final root = await Directory.systemTemp.createTemp('runner_boi_logs_test_');
    addTearDown(() => root.delete(recursive: true));

    late AppLogService service;
    for (var index = 0; index < 12; index++) {
      service = AppLogService(
        rootDirectory: root,
        clock: () => DateTime.utc(2026, 9, 14, 7, index),
      );
      await service.start();
      await service.info('test', 'Session $index');
      await service.dispose();
    }

    final files = await service.retainedFiles();
    expect(files, hasLength(AppLogService.maxRetainedLogs));
    final names = files.map((file) => path.basename(file.path)).toList();
    expect(names.any((name) => name.contains('T07-00-00')), isFalse);
    expect(names.any((name) => name.contains('T07-01-00')), isFalse);
    expect(names.first.contains('T07-11-00'), isTrue);
  });
}
