# Runner Boi Agent Guide

This repo should stay production-quality even though it is a personal app. Treat changes as user-facing Android app work, not throwaway prototype code.

## Product Standards

- Keep Runner Boi simple, fast, and reliable for real runs.
- Preserve the local-first model unless the user explicitly asks otherwise.
- Do not add analytics, accounts, cloud sync, maps, or backend services casually.
- Any network behavior must be explicit in the feature, README, privacy wording, and tests. The current network use is GitHub Releases self-update checks.
- GPS, pace, run recovery, voice cues, logs, and update flows are user-trust features. Bias toward clear state handling and diagnostic logging.

## Architecture

- Follow the existing Flutter + Riverpod shape:
  - `lib/src/domain/` for models and enums.
  - `lib/src/data/` for repositories and persistence.
  - `lib/src/services/` for platform, network, location, audio, logging, and update services.
  - `lib/src/features/<feature>/` for screens/controllers/prompts.
  - `lib/src/core/` for formatting and small shared helpers.
- Keep feature logic out of widgets when it belongs in a controller, repository, or service.
- Keep widgets focused on UI orchestration and user interaction.
- Prefer dependency injection through Riverpod providers and constructor parameters so behavior can be tested without real GPS, network, audio, or platform state.
- Avoid broad refactors unless they directly reduce risk or improve the feature being changed.
- Do not edit generated files manually, especially `lib/src/data/app_database.g.dart`.

## UX And Design

- Maintain the dark-first running cockpit direction.
- Controls should be obvious while tired and moving: strong hierarchy, large primary actions, low ambiguity.
- Avoid UI that looks selected when it is merely available. Segmented controls, switches, and action buttons should make state clear.
- For settings, use compact controls and plain labels. Settings should be scannable.
- Do not add instructional walls of text in-app unless the user needs it to avoid mistakes.

## Documentation

- Update `README.md` whenever a feature changes user-visible behavior, setup, permissions, release flow, privacy posture, testing scope, or app capabilities.
- Keep README concise and current. Remove stale claims instead of adding caveats around them.
- If adding Android permissions, network calls, storage, background behavior, or release/update mechanics, document why.
- If adding or changing launcher icon or branding assets, document the source and regeneration command.

## Testing

- Add or update tests with every behavior change.
- Prefer focused tests around the risky logic:
  - formatters in `test/formatters_test.dart`
  - settings/prefs in `test/settings_repository_test.dart`
  - logs in `test/log_service_test.dart`
  - active-run recovery in `test/active_run_recovery_test.dart`
  - self-update logic in `test/update_service_test.dart`
- Network-facing code must be tested with fake responses, not live internet.
- Platform-facing code should expose injectable seams so tests do not need a real phone.
- Keep `integration_test/app_smoke_test.dart` aligned with core app navigation. It is smoke coverage, not full e2e coverage.
- Before finishing code changes, run:

```sh
flutter analyze
flutter test
flutter build apk --debug
```

- If a real Android device/emulator is unavailable, say so clearly. Do not imply e2e/device validation happened.

## Releases And Updates

- App version lives in `pubspec.yaml`.
- Self-update checks read the latest GitHub Release for `nwihardjo13/runner_boi`.
- Pushes to `main` publish release tags using app version plus the final arm64 Android `versionCode`, for example `v1.0.2+102123`.
- Keep CI release build numbers above local/manual builds so Android sideloaded updates have a strictly increasing `versionCode`. For split APK releases, tag the release with the final ABI-adjusted `versionCode`; arm64-v8a adds 2000 to the Flutter build number.
- Attach or publish an `.apk` asset to releases so the app can open the APK URL directly.
- Prefer arm64-v8a APK release assets for this personal Pixel-first app to keep download size down.
- Keep the startup update checker once-per-day by default, with manual checks available from Settings.
- Preserve dismissed-version behavior unless the user asks to change it.

## Git And CI

- Keep commits scoped and descriptive.
- Do not revert user changes unless explicitly requested.
- Current CI runs on every `main` push, pull request, and manual workflow dispatch.
- If CI or README behavior changes, update both workflow and docs together.

## Quality Bar

- New code should be readable, modular, and testable.
- Prefer small services/controllers over one large screen doing everything.
- Log enough diagnostic context for GPS, pace, lifecycle, update checks, and persistence failures.
- Handle failure paths explicitly: denied permissions, no GPS, no releases, network errors, malformed data, unavailable browser/install target.
- Keep dependencies justified. If adding one, explain what it replaces and verify Android build still works.
