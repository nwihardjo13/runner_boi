import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'log_service.dart';

typedef ReleaseJsonFetcher = Future<Map<String, Object?>?> Function(Uri uri);
typedef UpdateUrlOpener = Future<bool> Function(Uri uri);
typedef InstalledVersionLoader = Future<InstalledAppVersion> Function();

enum UpdateCheckStatus {
  skipped,
  updateAvailable,
  upToDate,
  dismissed,
  unavailable,
}

class InstalledAppVersion {
  const InstalledAppVersion({required this.version, required this.buildNumber});

  final String version;
  final String buildNumber;

  String get display {
    if (buildNumber.isEmpty) return version;
    return '$version+$buildNumber';
  }
}

class UpdateRelease {
  const UpdateRelease({
    required this.version,
    required this.name,
    required this.releaseUrl,
    required this.publishedAt,
    this.apkUrl,
    this.body,
  });

  final String version;
  final String name;
  final Uri releaseUrl;
  final Uri? apkUrl;
  final DateTime? publishedAt;
  final String? body;

  Uri get downloadUrl => apkUrl ?? releaseUrl;
}

class UpdateCheckResult {
  const UpdateCheckResult({
    required this.status,
    required this.currentVersion,
    this.release,
    this.message,
  });

  final UpdateCheckStatus status;
  final InstalledAppVersion currentVersion;
  final UpdateRelease? release;
  final String? message;

  bool get hasUpdate => status == UpdateCheckStatus.updateAvailable;
}

class SelfUpdateService {
  SelfUpdateService({
    required this.preferences,
    required this.log,
    DateTime Function()? clock,
    ReleaseJsonFetcher? releaseFetcher,
    InstalledVersionLoader? installedVersionLoader,
    UpdateUrlOpener? urlOpener,
  }) : _clock = clock ?? DateTime.now,
       _releaseFetcher = releaseFetcher ?? _fetchLatestRelease,
       _installedVersionLoader =
           installedVersionLoader ?? _loadInstalledVersion,
       _urlOpener = urlOpener ?? _openExternalUrl;

  static final latestReleaseUri = Uri.https(
    'api.github.com',
    '/repos/nwihardjo13/runner_boi/releases/latest',
  );
  static const checkInterval = Duration(days: 1);
  static const _lastCheckAtKey = 'self_update_last_check_at';
  static const _dismissedVersionKey = 'self_update_dismissed_version';

  final SharedPreferences preferences;
  final AppLogService log;
  final DateTime Function() _clock;
  final ReleaseJsonFetcher _releaseFetcher;
  final InstalledVersionLoader _installedVersionLoader;
  final UpdateUrlOpener _urlOpener;

  Future<UpdateCheckResult> checkForUpdate({
    bool force = false,
    bool respectDismissedVersion = true,
  }) async {
    final now = _clock().toUtc();
    final currentVersion = await _installedVersionLoader();
    if (!force && !_shouldCheck(now)) {
      unawaited(
        log.debug(
          'updates',
          'Self-update check skipped because interval has not elapsed',
          data: {
            'currentVersion': currentVersion.display,
            'lastCheckAt': preferences.getString(_lastCheckAtKey),
          },
        ),
      );
      return UpdateCheckResult(
        status: UpdateCheckStatus.skipped,
        currentVersion: currentVersion,
      );
    }

    unawaited(
      log.info(
        'updates',
        'Self-update check started',
        data: {
          'force': force,
          'respectDismissedVersion': respectDismissedVersion,
          'currentVersion': currentVersion.display,
        },
      ),
    );

    try {
      final releaseJson = await _releaseFetcher(latestReleaseUri);
      await preferences.setString(_lastCheckAtKey, now.toIso8601String());
      if (releaseJson == null) {
        unawaited(
          log.info(
            'updates',
            'No GitHub release available for self-update',
            data: {'currentVersion': currentVersion.display},
          ),
        );
        return UpdateCheckResult(
          status: UpdateCheckStatus.upToDate,
          currentVersion: currentVersion,
          message: 'No release is available yet.',
        );
      }

      final release = parseGitHubRelease(releaseJson);
      final comparison = compareAppVersions(
        release.version,
        currentVersion.version,
      );
      if (comparison <= 0) {
        unawaited(
          log.info(
            'updates',
            'Installed app is up to date',
            data: {
              'currentVersion': currentVersion.display,
              'latestVersion': release.version,
            },
          ),
        );
        return UpdateCheckResult(
          status: UpdateCheckStatus.upToDate,
          currentVersion: currentVersion,
          release: release,
        );
      }

      final dismissedVersion = preferences.getString(_dismissedVersionKey);
      if (respectDismissedVersion && dismissedVersion == release.version) {
        unawaited(
          log.info(
            'updates',
            'Self-update suppressed for dismissed version',
            data: {
              'currentVersion': currentVersion.display,
              'latestVersion': release.version,
            },
          ),
        );
        return UpdateCheckResult(
          status: UpdateCheckStatus.dismissed,
          currentVersion: currentVersion,
          release: release,
        );
      }

      unawaited(
        log.info(
          'updates',
          'Self-update available',
          data: {
            'currentVersion': currentVersion.display,
            'latestVersion': release.version,
            'releaseUrl': release.releaseUrl.toString(),
            'apkUrl': release.apkUrl?.toString(),
          },
        ),
      );
      return UpdateCheckResult(
        status: UpdateCheckStatus.updateAvailable,
        currentVersion: currentVersion,
        release: release,
      );
    } catch (error, stackTrace) {
      await preferences.setString(_lastCheckAtKey, now.toIso8601String());
      unawaited(
        log.error(
          'updates',
          'Self-update check failed',
          data: {'currentVersion': currentVersion.display},
          error: error,
          stackTrace: stackTrace,
        ),
      );
      return UpdateCheckResult(
        status: UpdateCheckStatus.unavailable,
        currentVersion: currentVersion,
        message: error.toString(),
      );
    }
  }

  Future<void> dismissVersion(String version) async {
    await preferences.setString(_dismissedVersionKey, version);
    unawaited(
      log.info(
        'updates',
        'Self-update version dismissed',
        data: {'version': version},
      ),
    );
  }

  Future<bool> openUpdate(UpdateRelease release) async {
    final opened = await _urlOpener(release.downloadUrl);
    unawaited(
      log.info(
        'updates',
        'Self-update download URL opened',
        data: {
          'version': release.version,
          'url': release.downloadUrl.toString(),
          'opened': opened,
        },
      ),
    );
    return opened;
  }

  bool _shouldCheck(DateTime now) {
    final lastCheckAt = DateTime.tryParse(
      preferences.getString(_lastCheckAtKey) ?? '',
    );
    if (lastCheckAt == null) return true;
    return now.difference(lastCheckAt.toUtc()) >= checkInterval;
  }
}

UpdateRelease parseGitHubRelease(Map<String, Object?> json) {
  final tagName = json['tag_name'] as String? ?? '';
  final releaseUrl = Uri.parse(json['html_url'] as String? ?? '');
  final publishedAt = DateTime.tryParse(json['published_at'] as String? ?? '');
  final assets = (json['assets'] as List<Object?>? ?? const [])
      .whereType<Map<String, Object?>>()
      .toList();
  final apkAsset = assets.cast<Map<String, Object?>?>().firstWhere((asset) {
    final name = asset?['name'] as String? ?? '';
    final url = asset?['browser_download_url'] as String?;
    return url != null && name.toLowerCase().endsWith('.apk');
  }, orElse: () => null);
  final apkUrl = apkAsset == null
      ? null
      : Uri.tryParse(apkAsset['browser_download_url'] as String? ?? '');

  return UpdateRelease(
    version: normalizeAppVersion(tagName),
    name: json['name'] as String? ?? tagName,
    releaseUrl: releaseUrl,
    apkUrl: apkUrl,
    publishedAt: publishedAt,
    body: json['body'] as String?,
  );
}

String normalizeAppVersion(String value) {
  return value.trim().replaceFirst(RegExp(r'^[vV]'), '').split('-').first;
}

int compareAppVersions(String latest, String current) {
  final latestVersion = _ParsedVersion.parse(latest);
  final currentVersion = _ParsedVersion.parse(current);
  return latestVersion.compareTo(currentVersion);
}

class _ParsedVersion implements Comparable<_ParsedVersion> {
  const _ParsedVersion(this.parts);

  factory _ParsedVersion.parse(String raw) {
    final normalized = normalizeAppVersion(raw);
    final base = normalized.split('+').first;
    return _ParsedVersion(
      base
          .split('.')
          .map(
            (part) =>
                int.tryParse(RegExp(r'^\d+').stringMatch(part) ?? '0') ?? 0,
          )
          .toList(),
    );
  }

  final List<int> parts;

  @override
  int compareTo(_ParsedVersion other) {
    final length = parts.length > other.parts.length
        ? parts.length
        : other.parts.length;
    for (var index = 0; index < length; index += 1) {
      final left = index < parts.length ? parts[index] : 0;
      final right = index < other.parts.length ? other.parts[index] : 0;
      if (left != right) return left.compareTo(right);
    }
    return 0;
  }
}

Future<InstalledAppVersion> _loadInstalledVersion() async {
  final packageInfo = await PackageInfo.fromPlatform();
  return InstalledAppVersion(
    version: packageInfo.version,
    buildNumber: packageInfo.buildNumber,
  );
}

Future<Map<String, Object?>?> _fetchLatestRelease(Uri uri) async {
  final client = HttpClient();
  try {
    final request = await client
        .getUrl(uri)
        .timeout(const Duration(seconds: 8));
    request.headers.set(
      HttpHeaders.acceptHeader,
      'application/vnd.github+json',
    );
    request.headers.set(HttpHeaders.userAgentHeader, 'RunnerBoi');
    final response = await request.close().timeout(const Duration(seconds: 8));
    final body = await utf8.decoder.bind(response).join();
    if (response.statusCode == HttpStatus.notFound) return null;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'GitHub release request failed with HTTP ${response.statusCode}',
        uri: uri,
      );
    }
    return jsonDecode(body) as Map<String, Object?>;
  } finally {
    client.close(force: true);
  }
}

Future<bool> _openExternalUrl(Uri uri) {
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
