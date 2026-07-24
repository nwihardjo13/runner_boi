# Runner Boi

Runner Boi is a Flutter Android app for building and executing segment-based running plans. It is designed for interval workouts where each segment can target time, distance, or manual advancement, with optional target pace, live pace feedback, and voice cues.

The repo is production-oriented: app state is separated from persistence and platform services, run data stays local, Android permissions are explicit, and CI includes static analysis, unit tests, and an Android emulator smoke test.

## Current Scope

Runner Boi currently supports:

- Saved workout templates with run and rest segments.
- Segment targets by time, distance, or manual next.
- Optional exact target pace per segment.
- Repeat-last-block editing for interval sets.
- GPS lock gate before starting a run.
- Live run cockpit with current pace, segment average pace, GPS accuracy, segment elapsed time, and segment distance.
- Voice cue and countdown before each segment.
- Manual pause/resume, skip segment, and end run controls.
- Local run history with per-segment planned vs actual stats.
- Settings for units, pace display mode, countdown length, voice cues, and music ducking.

Maps, cloud sync, import/export, account auth, and Play Store release packaging are intentionally out of MVP scope.

## Product Principles

- **Run-first UI:** during a workout, the most important information is current pace, then segment average pace, then remaining/current segment context.
- **Local-first data:** workout templates, settings, and run history are stored on device.
- **Explicit permissions:** GPS is requested for pace/distance tracking; foreground location is used while a run is active.
- **Low-interruption audio:** segment announcements and countdowns are short, with optional audio ducking.
- **Predictable workouts:** segments advance from clear time, distance, or manual rules.

## Tech Stack

- Flutter + Dart
- Riverpod for application state and controllers
- Drift + SQLite for local persistence
- shared_preferences for persisted settings
- geolocator / geolocator_android for GPS and Android foreground location
- flutter_tts + audio_session for voice cues and audio ducking
- GitHub Actions for Android emulator verification

## Branding

- Product name: Runner Boi
- Android/iOS launcher icon source: `assets/branding/github-avatar.jpg`
- Launcher icons are generated with `flutter_launcher_icons`.

Regenerate launcher icons after changing the source image:

```sh
dart run flutter_launcher_icons
```

## Architecture

```text
lib/
  main.dart                         App entry point
  src/app.dart                      Material app shell and navigation
  src/core/                         Formatting and unit conversion helpers
  src/domain/                       Workout, segment, settings, and run models
  src/data/                         Drift database and repositories
  src/features/                     Home, workout editor, run, history, settings
  src/services/                     Location and voice/audio integrations
  src/theme/                        Dark cockpit visual system
integration_test/
  app_smoke_test.dart               Android emulator boot/install UI smoke test
test/
  formatters_test.dart              Fast unit coverage for formatting behavior
```

Stateful workout behavior lives in Riverpod controllers. Platform-specific services are isolated behind service classes so run logic can be tested without requiring GPS, TTS, or Android framework access.

## Data And Privacy

Runner Boi stores data locally for the MVP:

- Workout templates
- Run history
- Segment results
- User settings

No account system, analytics, cloud sync, or server upload exists in the current app.

## Android Permissions

The Android app declares:

- `ACCESS_COARSE_LOCATION`
- `ACCESS_FINE_LOCATION`
- `ACCESS_BACKGROUND_LOCATION`
- `FOREGROUND_SERVICE`
- `FOREGROUND_SERVICE_LOCATION`
- `POST_NOTIFICATIONS`
- `WAKE_LOCK`

These support live GPS pace tracking, foreground tracking notification, and keeping a run active while the screen is off.

## Development

Prerequisites:

- Flutter 3.44.7 or compatible stable Flutter
- Android SDK with platform/build tools installed
- JDK 17

Install dependencies:

```sh
flutter pub get
```

Run local checks:

```sh
flutter analyze
flutter test
flutter build apk --debug
```

Run on a connected Android device:

```sh
flutter run
```

Install the debug APK manually:

```sh
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

## CI

GitHub Actions runs:

- Flutter dependency install
- `flutter analyze`
- `flutter test`
- Android API 35 emulator boot
- Debug APK build/install
- Integration smoke test against the emulator

Current workflow:

```text
.github/workflows/android-emulator.yml
```

Latest verified run:

```text
https://github.com/nwihardjo13/runner_boi/actions/workflows/android-emulator.yml
```

## Testing Strategy

Current coverage:

- Unit tests for distance/pace formatting and the manual segment cue phrase.
- Android emulator smoke test proving the app boots, installs, and opens the plan editor.

Next coverage to add:

- Run engine unit tests for segment advancement by time, distance, manual next, pause/resume, skip, and end.
- Pace calculation tests for instant pace, smoothed pace windows, invalid GPS accuracy, and stationary/noisy GPS samples.
- Voice cue tests for segment announcements, countdown order, disabled voice mode, and audio ducking settings.
- Drift repository tests using an isolated test database for templates, history, deletes, and duplicate plans.
- Widget tests for the workout editor, settings persistence, history rendering, and run cockpit states.
- Golden tests for the run cockpit and editor at small/large phone sizes.
- Android integration tests for create plan -> start run -> permissions mocked/granted -> end run -> history saved.
- Manual field tests on a physical phone for GPS accuracy, background tracking, screen-off behavior, Bluetooth audio, and notification behavior.

## Release Readiness

Before public Play Store release, add:

- Signed release build configuration.
- App icon and adaptive icon pass.
- Privacy policy and store data-safety declarations.
- Background location review materials, if background tracking remains enabled.
- Crash reporting decision and policy.
- Release build smoke test.
- Physical device QA matrix.
- Accessibility pass for large text, contrast, TalkBack labels, and touch targets.

## Useful Commands

```sh
flutter pub get
flutter analyze
flutter test
flutter test integration_test/app_smoke_test.dart -d emulator-5554
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```
