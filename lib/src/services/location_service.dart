import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:geolocator/geolocator.dart';

import '../domain/models.dart';
import 'log_service.dart';

class LocationSample {
  const LocationSample({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.speedMetersPerSecond,
    required this.timestamp,
  });

  factory LocationSample.fromPosition(Position position) {
    return LocationSample(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
      speedMetersPerSecond: position.speed,
      timestamp: position.timestamp,
    );
  }

  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final double speedMetersPerSecond;
  final DateTime timestamp;
}

class GpsFix {
  const GpsFix({
    required this.quality,
    required this.accuracyMeters,
    required this.canStart,
    required this.message,
  });

  factory GpsFix.fromAccuracy(double? accuracyMeters) {
    if (accuracyMeters == null) {
      return const GpsFix(
        quality: GpsQuality.unavailable,
        accuracyMeters: null,
        canStart: false,
        message: 'Waiting for GPS',
      );
    }
    if (accuracyMeters <= 10) {
      return GpsFix(
        quality: GpsQuality.excellent,
        accuracyMeters: accuracyMeters,
        canStart: true,
        message: 'Excellent GPS',
      );
    }
    if (accuracyMeters <= 20) {
      return GpsFix(
        quality: GpsQuality.good,
        accuracyMeters: accuracyMeters,
        canStart: true,
        message: 'Good GPS',
      );
    }
    if (accuracyMeters <= 30) {
      return GpsFix(
        quality: GpsQuality.weak,
        accuracyMeters: accuracyMeters,
        canStart: false,
        message: 'Weak GPS',
      );
    }
    return GpsFix(
      quality: GpsQuality.bad,
      accuracyMeters: accuracyMeters,
      canStart: false,
      message: 'Bad GPS',
    );
  }

  final GpsQuality quality;
  final double? accuracyMeters;
  final bool canStart;
  final String message;
}

class LocationService {
  LocationService([this._log]);

  final AppLogService? _log;

  Future<bool> ensurePermission() async {
    _debug('Checking location service and permission');
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _warning('Location service disabled');
      return false;
    }

    var permission = await Geolocator.checkPermission();
    _debug('Location permission state read', data: {'permission': permission});
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      _info('Location permission requested', data: {'permission': permission});
    }

    final allowed =
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
    _info(
      'Location permission resolved',
      data: {'permission': permission, 'allowed': allowed},
    );
    return allowed;
  }

  Future<GpsFix> currentFix() async {
    _debug('Requesting current GPS fix');
    final allowed = await ensurePermission();
    if (!allowed) {
      _warning('Current GPS fix unavailable because permission is missing');
      return const GpsFix(
        quality: GpsQuality.unavailable,
        accuracyMeters: null,
        canStart: false,
        message: 'Location permission needed',
      );
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          timeLimit: Duration(seconds: 10),
        ),
      );
      final fix = GpsFix.fromAccuracy(position.accuracy);
      _info(
        'Current GPS fix received',
        data: {
          'quality': fix.quality,
          'accuracyMeters': fix.accuracyMeters,
          'canStart': fix.canStart,
          'message': fix.message,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'speedMetersPerSecond': position.speed,
          'timestamp': position.timestamp,
        },
      );
      return fix;
    } catch (error, stackTrace) {
      _error('Current GPS fix failed', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  Stream<LocationSample> samples() {
    final settings = Platform.isAndroid
        ? AndroidSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 1,
            intervalDuration: const Duration(seconds: 1),
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationTitle: 'Runner Boi is tracking',
              notificationText: 'GPS pace and segment progress are active.',
              notificationChannelName: 'Runner Boi tracking',
              enableWakeLock: true,
              setOngoing: true,
              color: Color(0xFFB7FF3C),
            ),
          )
        : const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 1,
          );
    _info(
      'Location stream created',
      data: {
        'platform': Platform.operatingSystem,
        'accuracy': LocationAccuracy.bestForNavigation.name,
        'distanceFilterMeters': 1,
        if (Platform.isAndroid) 'intervalSeconds': 1,
      },
    );
    return Geolocator.getPositionStream(
      locationSettings: settings,
    ).map(LocationSample.fromPosition);
  }

  double distanceBetween(LocationSample a, LocationSample b) {
    return Geolocator.distanceBetween(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
  }

  void _debug(String message, {Map<String, Object?> data = const {}}) {
    final log = _log;
    if (log == null) return;
    unawaited(log.debug('location', message, data: data));
  }

  void _info(String message, {Map<String, Object?> data = const {}}) {
    final log = _log;
    if (log == null) return;
    unawaited(log.info('location', message, data: data));
  }

  void _warning(String message, {Map<String, Object?> data = const {}}) {
    final log = _log;
    if (log == null) return;
    unawaited(log.warning('location', message, data: data));
  }

  void _error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> data = const {},
  }) {
    final log = _log;
    if (log == null) return;
    unawaited(
      log.error(
        'location',
        message,
        data: data,
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }
}
