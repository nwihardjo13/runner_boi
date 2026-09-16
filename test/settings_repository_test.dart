import 'package:flutter_test/flutter_test.dart';
import 'package:runner_boi/src/data/repositories.dart';
import 'package:runner_boi/src/domain/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('persists configurable run update settings', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repository = SettingsRepository(prefs, const LocaleLike('US'));

    await repository.save(
      AppSettings.defaults(const LocaleLike('US')).copyWith(
        runUpdateCueMode: RunUpdateCueMode.distance,
        runUpdateMinutes: 3,
        runUpdateDistance: 0.75,
      ),
    );

    final settings = repository.load();

    expect(settings.runUpdateCueMode, RunUpdateCueMode.distance);
    expect(settings.runUpdateMinutes, 3);
    expect(settings.runUpdateDistance, 0.75);
  });

  test('falls back to off for removed fixed update modes', () async {
    SharedPreferences.setMockInitialValues({
      'run_update_cue_mode': 'everyHalfDistance',
    });
    final prefs = await SharedPreferences.getInstance();
    final repository = SettingsRepository(prefs, const LocaleLike('GB'));

    final settings = repository.load();

    expect(settings.runUpdateCueMode, RunUpdateCueMode.off);
    expect(settings.runUpdateMinutes, 1);
    expect(settings.runUpdateDistance, 1);
  });
}
