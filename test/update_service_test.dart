import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:runner_boi/src/services/log_service.dart';
import 'package:runner_boi/src/services/update_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory tempDir;
  late AppLogService log;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('runner-boi-update-test-');
    log = AppLogService(rootDirectory: tempDir);
    await log.start();
  });

  tearDown(() async {
    await log.dispose();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('compares semantic versions from release tags', () {
    expect(compareAppVersions('v1.0.1', '1.0.0'), greaterThan(0));
    expect(compareAppVersions('1.2.0', '1.10.0'), lessThan(0));
    expect(compareAppVersions('v1.0.0+3', '1.0.0+2'), greaterThan(0));
    expect(compareAppVersions('v1.0.0+3', '1.0.0+3'), 0);
    expect(compareAppVersions('v1.0.0+3', '1.0.1+1'), lessThan(0));
    expect(compareAppVersions('v1.0.2+100020', '1.0.2+2018'), greaterThan(0));
    expect(compareAppVersions('v1.0.2+102023', '1.0.2+102022'), greaterThan(0));
  });

  test('detects update and opens apk asset URL', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    Uri? openedUrl;
    final service = SelfUpdateService(
      preferences: prefs,
      log: log,
      releaseFetcher: (_) async => _releaseJson(tag: 'v1.0.1'),
      installedVersionLoader: () async =>
          const InstalledAppVersion(version: '1.0.0', buildNumber: '1'),
      urlOpener: (uri) async {
        openedUrl = uri;
        return true;
      },
    );

    final result = await service.checkForUpdate(force: true);

    expect(result.status, UpdateCheckStatus.updateAvailable);
    expect(result.release?.version, '1.0.1');

    final opened = await service.openUpdate(result.release!);

    expect(opened, true);
    expect(openedUrl.toString(), 'https://example.com/runner-boi.apk');
  });

  test('detects newer build number for same app version', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final service = SelfUpdateService(
      preferences: prefs,
      log: log,
      releaseFetcher: (_) async => _releaseJson(tag: 'v1.0.2+9'),
      installedVersionLoader: () async =>
          const InstalledAppVersion(version: '1.0.2', buildNumber: '8'),
    );

    final result = await service.checkForUpdate(force: true);

    expect(result.status, UpdateCheckStatus.updateAvailable);
    expect(result.release?.version, '1.0.2+9');
  });

  test('skips automatic check until daily interval elapses', () async {
    final now = DateTime.utc(2026, 9, 16, 12);
    SharedPreferences.setMockInitialValues({
      'self_update_last_check_at': now
          .subtract(const Duration(hours: 2))
          .toIso8601String(),
    });
    final prefs = await SharedPreferences.getInstance();
    var fetchCount = 0;
    final service = SelfUpdateService(
      preferences: prefs,
      log: log,
      clock: () => now,
      releaseFetcher: (_) async {
        fetchCount += 1;
        return _releaseJson(tag: 'v1.0.1');
      },
      installedVersionLoader: () async =>
          const InstalledAppVersion(version: '1.0.0', buildNumber: '1'),
    );

    final result = await service.checkForUpdate();

    expect(result.status, UpdateCheckStatus.skipped);
    expect(fetchCount, 0);
  });

  test('suppresses dismissed version for automatic checks only', () async {
    SharedPreferences.setMockInitialValues({
      'self_update_dismissed_version': '1.0.1',
    });
    final prefs = await SharedPreferences.getInstance();
    final service = SelfUpdateService(
      preferences: prefs,
      log: log,
      releaseFetcher: (_) async => _releaseJson(tag: 'v1.0.1'),
      installedVersionLoader: () async =>
          const InstalledAppVersion(version: '1.0.0', buildNumber: '1'),
    );

    final automatic = await service.checkForUpdate(force: true);
    final manual = await service.checkForUpdate(
      force: true,
      respectDismissedVersion: false,
    );

    expect(automatic.status, UpdateCheckStatus.dismissed);
    expect(manual.status, UpdateCheckStatus.updateAvailable);
  });
}

Map<String, Object?> _releaseJson({required String tag}) {
  return {
    'tag_name': tag,
    'name': 'Runner Boi $tag',
    'html_url': 'https://github.com/nwihardjo13/runner_boi/releases/tag/$tag',
    'published_at': '2026-09-16T12:00:00Z',
    'body': 'Release notes',
    'assets': [
      {
        'name': 'runner-boi.apk',
        'browser_download_url': 'https://example.com/runner-boi.apk',
      },
    ],
  };
}
