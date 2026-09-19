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

Runner Boi is a Flutter Android app for segment-based running workouts. Build run/rest segments by time, distance, or manual advance; add optional target pace; then start into GPS lock, countdown, voice cues, configurable mid-run updates, and a live pace cockpit.

## Download

Every push to `main` builds, verifies, and publishes a GitHub Release with an arm64 Android APK. Manual workflow runs and pull requests still run verification.

1. Open the latest [release](https://github.com/nwihardjo13/runner_boi/releases/latest).
2. Download the `runner-boi-...-arm64-v8a.apk` asset.
3. Install it on the phone.

Local debug APK path:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

After installing, Runner Boi can check GitHub Releases once per day and prompt when a newer APK is available.

## Features

- Quick flow: tap Start, enter a plan, save-and-start directly.
- Saved workout templates with run/rest segments.
- Time, distance, and manual segment targets.
- Optional exact target pace per segment.
- Repeat-last-block editor for intervals.
- GPS lock before run start.
- Live cockpit with current pace, segment average pace, GPS accuracy, segment time, and segment distance.
- Voice segment cues, countdown, pause/resume, skip, and end-run controls.
- Configurable mid-run voice updates by time or distance.
- Recoverable active run snapshot if the app process is closed mid-run.
- Local run history with per-segment planned vs actual stats.
- Persisted settings for units, pace mode, countdown length, voice cues, music pause/ducking, and run updates.
- Exportable diagnostics logs for GPS, pace, distance, lifecycle, and app actions.
- Self-update checks through GitHub Releases with daily prompts and manual Settings checks.

## Scope

Personal app, built with a public-repo quality bar. MVP is local-first: no accounts, analytics, cloud sync, maps, or import/export.

## Privacy

Data stays on device:

- Workout templates
- Settings
- Run history
- Segment results
- Diagnostics logs

The app has no custom backend, account system, analytics, or cloud upload. It can contact GitHub Releases to check for app updates. Exported diagnostics logs can include GPS coordinates and should be treated as sensitive.

## Android Access

Runner Boi requests location and foreground-service permissions for live GPS pace tracking, screen-off runs, and the active-run notification. Notifications are used for foreground run tracking. Wake lock support keeps active sessions from being interrupted by device sleep. Internet access is used only for GitHub Release update checks.

## Stack

- Flutter + Dart
- Riverpod for app state/controllers
- Drift + SQLite for templates and run history
- shared_preferences for settings
- geolocator for GPS/foreground location
- flutter_tts + audio_session for cues and ducking
- package_info_plus + url_launcher for release update checks
- GitHub Actions for APK artifact and emulator smoke test

## Layout

```text
lib/src/core/        formatting and unit helpers
lib/src/domain/      workout, segment, settings, run models
lib/src/data/        Drift database and repositories
lib/src/features/    home, editor, run, history, settings screens
lib/src/services/    location, voice/audio, logs, and update services
lib/src/theme/       dark cockpit theme
test/                fast unit and persistence tests
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

## Releases

Self-update checks read the latest GitHub Release for `nwihardjo13/runner_boi`.

Release checklist:

1. Bump `version:` in `pubspec.yaml`.
2. Build the APK.
3. Create a GitHub Release tagged with the app version, for example `v1.0.1`.
4. Attach an `.apk` asset.

On each `main` push, CI builds an arm64 APK, tags it with the app version plus the actual arm64 Android `versionCode`, and publishes a release such as `v1.0.2+102123`. The offset keeps CI `versionCode` values above local/manual builds, which Android requires for sideloaded updates. The app checks at most once per day on startup, compares both version and build number, lets the user skip a version, and has a manual check in Settings. Android still requires the user to approve sideloaded APK installation.

## Verification

- Local: `flutter analyze`, `flutter test`, `flutter build apk --debug`
- CI: dependency install, analyzer, unit tests, debug APK upload, Android emulator boot/install/smoke test
- Workflow: `.github/workflows/android-emulator.yml`
- E2E status: smoke coverage only. It boots the app, opens the plan editor, and verifies the diagnostics export surface.
- Update coverage: self-update logic is tested with fake GitHub responses, not live network calls.
- Release artifact: CI publishes an arm64-v8a APK to reduce APK size for modern Android phones.

## Test Backlog

- Run engine: time/distance/manual advancement, pause/resume, skip, end.
- Pace logic: instant pace, noisy GPS, bad accuracy, stationary samples.
- Voice: announcements, countdown order, disabled cues, ducking.
- Updates: widget coverage for startup/manual update prompts.
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

## Agent Notes

Future agent guidance lives in `AGENTS.md`.
