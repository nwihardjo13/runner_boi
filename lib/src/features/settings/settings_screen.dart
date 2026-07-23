import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models.dart';
import '../providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: settings.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: Text('Could not load settings: $error')),
          data: (value) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              Text(
                'settings',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 20),
              _Section(
                title: 'Units',
                child: SegmentedButton<MeasurementSystem>(
                  segments: const [
                    ButtonSegment(
                      value: MeasurementSystem.metric,
                      label: Text('Metric'),
                    ),
                    ButtonSegment(
                      value: MeasurementSystem.imperial,
                      label: Text('Imperial'),
                    ),
                  ],
                  selected: {value.measurementSystem},
                  onSelectionChanged: (selected) {
                    ref
                        .read(settingsControllerProvider.notifier)
                        .saveSettings(
                          value.copyWith(measurementSystem: selected.first),
                        );
                  },
                ),
              ),
              _Section(
                title: 'Pace display',
                child: SegmentedButton<PaceDisplayMode>(
                  segments: const [
                    ButtonSegment(
                      value: PaceDisplayMode.instant,
                      label: Text('Instant'),
                    ),
                    ButtonSegment(
                      value: PaceDisplayMode.smoothed5,
                      label: Text('5s'),
                    ),
                    ButtonSegment(
                      value: PaceDisplayMode.smoothed10,
                      label: Text('10s'),
                    ),
                  ],
                  selected: {value.paceDisplayMode},
                  onSelectionChanged: (selected) {
                    ref
                        .read(settingsControllerProvider.notifier)
                        .saveSettings(
                          value.copyWith(paceDisplayMode: selected.first),
                        );
                  },
                ),
              ),
              _Section(
                title: 'Countdown',
                child: Row(
                  children: [
                    Expanded(
                      child: Slider(
                        min: 0,
                        max: 10,
                        divisions: 10,
                        value: value.countdownSeconds.toDouble(),
                        label: '${value.countdownSeconds}s',
                        onChanged: (next) {
                          ref
                              .read(settingsControllerProvider.notifier)
                              .saveSettings(
                                value.copyWith(countdownSeconds: next.round()),
                              );
                        },
                      ),
                    ),
                    SizedBox(
                      width: 42,
                      child: Text(
                        '${value.countdownSeconds}s',
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: value.voiceCuesEnabled,
                onChanged: (enabled) {
                  ref
                      .read(settingsControllerProvider.notifier)
                      .saveSettings(value.copyWith(voiceCuesEnabled: enabled));
                },
                title: const Text('Voice cues'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: value.duckAudio,
                onChanged: value.voiceCuesEnabled
                    ? (enabled) {
                        ref
                            .read(settingsControllerProvider.notifier)
                            .saveSettings(value.copyWith(duckAudio: enabled));
                      }
                    : null,
                title: const Text('Duck music during cues'),
              ),
              const SizedBox(height: 28),
              OutlinedButton.icon(
                onPressed: () => _deleteAllRuns(context, ref),
                icon: const Icon(Icons.delete_sweep_outlined),
                label: const Text('Delete all runs'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteAllRuns(BuildContext context, WidgetRef ref) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete all runs?'),
            content: const Text(
              'Templates and settings stay. Run history is removed.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    await ref.read(runHistoryRepositoryProvider).deleteAllRuns();
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
