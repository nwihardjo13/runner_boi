# Runner Boi

<p align="center">
  <img src="assets/branding/runner-boi-icon.png" alt="Runner Boi app icon" width="128">
</p>

<p align="center">
  <a href="https://github.com/nwihardjo13/runner_boi/actions/workflows/android-emulator.yml"><img alt="Android emulator smoke" src="https://github.com/nwihardjo13/runner_boi/actions/workflows/android-emulator.yml/badge.svg"></a>
  <img alt="Platform Android" src="https://img.shields.io/badge/platform-Android-3DDC84">
  <img alt="Flutter 3.44.7" src="https://img.shields.io/badge/Flutter-3.44.7-02569B">
  <a href="LICENSE"><img alt="License MIT" src="https://img.shields.io/badge/license-MIT-blue.svg"></a>
</p>

Runner Boi is a Flutter Android app for segment-based running workouts. Build run/rest segments by time, distance, or manual advance; add optional target pace; then start into GPS lock, countdown, voice cues, and a live pace cockpit.

## Download

Every push to `main` builds a debug APK in GitHub Actions.

1. Open the latest [Android emulator smoke](https://github.com/nwihardjo13/runner_boi/actions/workflows/android-emulator.yml) run.
2. Download the `runner-boi-debug-apk` artifact.
3. Unzip it and install `app-debug.apk` on the phone.

Local debug APK path:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

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

## Scope

Personal app, built with a public-repo quality bar. MVP is local-first: no accounts, analytics, cloud sync, maps, or import/export.

## Privacy

Data stays on device:

- Workout templates
- Settings
- Run history
- Segment results

The app has no backend, account system, analytics, or cloud upload.

## Android Access

Runner Boi requests location and foreground-service permissions for live GPS pace tracking, screen-off runs, and the active-run notification. Notifications are used for foreground run tracking. Wake lock support keeps active sessions from being interrupted by device sleep.

## Stack

- Flutter + Dart
- Riverpod for app state/controllers
- Drift + SQLite for templates and run history
- shared_preferences for settings
- geolocator for GPS/foreground location
- flutter_tts + audio_session for cues and ducking
- GitHub Actions for APK artifact and emulator smoke test

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

Install with cable:

```sh
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

## Verification

- Local: `flutter analyze`, `flutter test`, `flutter build apk --debug`
- CI: dependency install, analyzer, unit tests, debug APK upload, Android emulator boot/install/smoke test
- Workflow: `.github/workflows/android-emulator.yml`

## Test Backlog

- Run engine: time/distance/manual advancement, pause/resume, skip, end.
- Pace logic: instant pace, noisy GPS, bad accuracy, stationary samples.
- Voice: announcements, countdown order, disabled cues, ducking.
- Persistence: Drift repository tests for templates, runs, deletes, duplicates.
- Widgets/goldens: editor, settings, history, cockpit across phone sizes.
- Field QA: Pixel GPS, screen-off tracking, Bluetooth audio, notification behavior.

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
