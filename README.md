# runner boi

Flutter Android MVP for segment-based running plans.

## MVP

- Saved workout templates with run/rest segments.
- Segment targets by time, distance, or manual advance.
- Optional target pace per segment.
- Repeat-last-block editor UX for intervals.
- GPS lock gate before start.
- Live run cockpit with giant current pace, segment average pace, GPS accuracy,
  segment time, and segment distance.
- Voice cue + countdown before each segment.
- Manual pause/resume, skip segment, and end run.
- Local history with planned vs actual segment stats.
- Settings for units, pace display smoothing, countdown, voice cues, and music
  ducking.

## Stack

- Flutter + Dart
- Riverpod for app state
- Drift + SQLite for local persistence
- shared_preferences for settings
- geolocator for GPS
- flutter_tts + audio_session for voice cues and ducking

## Run

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

Android SDK/JDK must be installed for `flutter run` on Android.
