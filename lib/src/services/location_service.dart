import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:geolocator/geolocator.dart';

import '../domain/models.dart';

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
  Future<bool> ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<GpsFix> currentFix() async {
    final allowed = await ensurePermission();
    if (!allowed) {
      return const GpsFix(
        quality: GpsQuality.unavailable,
        accuracyMeters: null,
        canStart: false,
        message: 'Location permission needed',
      );
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        timeLimit: Duration(seconds: 10),
      ),
    );
    return GpsFix.fromAccuracy(position.accuracy);
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
}
