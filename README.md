# Runner Boi

Flutter Android app for building and running segment-based workouts. Create run/rest segments by time, distance, or manual advance; add optional target pace; then start into GPS lock, countdown, voice cues, and a live pace cockpit.

## Status

Personal app, engineered like a public Android repo. MVP is local-first: no accounts, analytics, cloud sync, maps, or import/export.

## Features

- Quick flow: tap Start, enter a plan, save-and-start directly.
- Saved workout templates with run/rest segments.
- Time, distance, and manual segment targets.
- Optional exact target pace per segment.
- Repeat-last-block editor for intervals.
- GPS lock before run start.
- Live cockpit with current pace, segment average pace, GPS accuracy, segment time, and segment distance.
- Voice segment cues, countdown, pause/resume, skip, and end-run controls.
- Local run history with per-segment planned vs actual stats.
- Persisted settings for units, pace mode, countdown length, voice cues, and audio ducking.

## Stack

- Flutter + Dart
- Riverpod for app state/controllers
- Drift + SQLite for templates and run history
- shared_preferences for settings
- geolocator for GPS/foreground location
- flutter_tts + audio_session for cues and ducking
- GitHub Actions Android emulator smoke test

## Layout

```text
lib/src/core/        formatting and unit helpers
lib/src/domain/      workout, segment, settings, run models
lib/src/data/        Drift database and repositories
lib/src/features/    home, editor, run, history, settings screens
lib/src/services/    location and voice/audio services
lib/src/theme/       dark cockpit theme
test/                fast unit tests
integration_test/    Android smoke test
```

## Development

Prerequisites: Flutter stable, Android SDK, JDK 17.

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Debug APK:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

GitHub Actions uploads the same APK as:

```text
runner-boi-debug-apk
```

Install with cable:

```sh
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

## Verification

Current local checks:

- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`

CI also boots an Android emulator, builds/installs the APK, and opens the plan editor:

```text
.github/workflows/android-emulator.yml
```

## Test Backlog

- Run engine: time/distance/manual advancement, pause/resume, skip, end.
- Pace logic: instant pace, noisy GPS, bad accuracy, stationary samples.
- Voice: announcements, countdown order, disabled cues, ducking.
- Persistence: Drift repository tests for templates, runs, deletes, duplicates.
- Widgets: editor, settings, history, run cockpit states.
- Goldens: editor and cockpit across compact/large phones.
- Android integration: create plan -> start run -> end run -> history saved.
- Field QA: Pixel device GPS, screen-off tracking, Bluetooth audio, notification behavior.

## Privacy

Data stays on device for MVP:

- Workout templates
- Settings
- Run history
- Segment results

The app currently has no backend, account system, analytics, or cloud upload.

## Branding

- App name: Runner Boi
- Launcher icon source: `assets/branding/runner-boi-icon.png`
- Original avatar reference: `assets/branding/github-avatar.jpg`

Regenerate icons after changing the source image:

```sh
dart run flutter_launcher_icons
```

## License

MIT. See `LICENSE`.
