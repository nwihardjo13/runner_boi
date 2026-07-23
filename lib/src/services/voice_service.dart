import 'package:audio_session/audio_session.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../core/formatters.dart';
import '../domain/models.dart';

class VoiceService {
  VoiceService() : _tts = FlutterTts();

  final FlutterTts _tts;

  Future<void> configure() async {
    await _tts.awaitSpeakCompletion(true);
    await _tts.setSpeechRate(0.48);
    await _tts.setVolume(1);
  }

  Future<void> announceSegment({
    required SegmentPlan segment,
    required MeasurementSystem units,
    required bool duckAudio,
  }) async {
    await _activateAudio(duckAudio);
    await _tts.setPitch(1);
    await _tts.speak('Next. ${segmentCue(segment, units)}');
  }

  Future<void> countdown(int seconds, {required bool duckAudio}) async {
    await _activateAudio(duckAudio);
    final safeSeconds = seconds.clamp(0, 10);
    for (var number = safeSeconds; number >= 1; number--) {
      final pitch = 0.9 + (number / safeSeconds.clamp(1, 10)) * 0.45;
      await _tts.setPitch(pitch);
      await _tts.speak('$number');
    }
    await _tts.setPitch(1.2);
    await _tts.speak('Go');
    await _deactivateAudio(duckAudio);
  }

  Future<void> stop() async {
    await _tts.stop();
    await _deactivateAudio(true);
  }

  Future<void> _activateAudio(bool duckAudio) async {
    if (!duckAudio) return;
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    await session.setActive(true);
  }

  Future<void> _deactivateAudio(bool duckAudio) async {
    if (!duckAudio) return;
    final session = await AudioSession.instance;
    await session.setActive(false);
  }
}
