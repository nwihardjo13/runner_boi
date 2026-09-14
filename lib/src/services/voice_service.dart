import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../core/formatters.dart';
import '../domain/models.dart';
import 'log_service.dart';

class VoiceService {
  VoiceService([this._log]) : _tts = FlutterTts();

  final FlutterTts _tts;
  final AppLogService? _log;

  Future<void> configure() async {
    _debug('Configuring text to speech');
    await _tts.awaitSpeakCompletion(true);
    await _tts.setSpeechRate(0.48);
    await _tts.setVolume(1);
    _info('Text to speech configured');
  }

  Future<void> announceSegment({
    required SegmentPlan segment,
    required MeasurementSystem units,
    required bool duckAudio,
  }) async {
    _info(
      'Announcing segment',
      data: {
        'segmentId': segment.id,
        'kind': segment.kind,
        'targetType': segment.targetType,
        'durationSeconds': segment.durationSeconds,
        'distanceMeters': segment.distanceMeters,
        'targetPaceSecondsPerKm': segment.targetPaceSecondsPerKm,
        'units': units,
        'duckAudio': duckAudio,
      },
    );
    await _activateAudio(duckAudio);
    await _tts.setPitch(1);
    await _tts.speak('Next. ${segmentCue(segment, units)}');
  }

  Future<void> countdown(int seconds, {required bool duckAudio}) async {
    _info(
      'Starting voice countdown',
      data: {'seconds': seconds, 'duckAudio': duckAudio},
    );
    await _activateAudio(duckAudio);
    final safeSeconds = seconds.clamp(0, 10);
    for (var number = safeSeconds; number >= 1; number--) {
      final pitch = 0.9 + (number / safeSeconds.clamp(1, 10)) * 0.45;
      _debug(
        'Speaking countdown number',
        data: {'number': number, 'pitch': pitch},
      );
      await _tts.setPitch(pitch);
      await _tts.speak('$number');
    }
    await _tts.setPitch(1.2);
    await _tts.speak('Go');
    await _deactivateAudio(duckAudio);
    _info('Voice countdown finished');
  }

  Future<void> stop() async {
    _info('Stopping text to speech');
    await _tts.stop();
    await _deactivateAudio(true);
  }

  Future<void> _activateAudio(bool duckAudio) async {
    if (!duckAudio) return;
    _debug('Activating ducked audio session');
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    await session.setActive(true);
  }

  Future<void> _deactivateAudio(bool duckAudio) async {
    if (!duckAudio) return;
    _debug('Deactivating ducked audio session');
    final session = await AudioSession.instance;
    await session.setActive(false);
  }

  void _debug(String message, {Map<String, Object?> data = const {}}) {
    final log = _log;
    if (log == null) return;
    unawaited(log.debug('voice', message, data: data));
  }

  void _info(String message, {Map<String, Object?> data = const {}}) {
    final log = _log;
    if (log == null) return;
    unawaited(log.info('voice', message, data: data));
  }
}
