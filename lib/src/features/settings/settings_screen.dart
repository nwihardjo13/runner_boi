import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

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
                title: const Text('Pause music during cues'),
              ),
              _Section(
                title: 'Run updates',
                child: SegmentedButton<RunUpdateCueMode>(
                  segments: [
                    const ButtonSegment(
                      value: RunUpdateCueMode.off,
                      label: Text('Off'),
                    ),
                    const ButtonSegment(
                      value: RunUpdateCueMode.everyMinute,
                      label: Text('1 min'),
                    ),
                    ButtonSegment(
                      value: RunUpdateCueMode.everyHalfDistance,
                      label: Text(
                        value.measurementSystem == MeasurementSystem.imperial
                            ? '0.5 mi'
                            : '0.5 km',
                      ),
                    ),
                    ButtonSegment(
                      value: RunUpdateCueMode.everyDistance,
                      label: Text(
                        value.measurementSystem == MeasurementSystem.imperial
                            ? '1 mi'
                            : '1 km',
                      ),
                    ),
                  ],
                  selected: {value.runUpdateCueMode},
                  onSelectionChanged: value.voiceCuesEnabled
                      ? (selected) {
                          ref
                              .read(settingsControllerProvider.notifier)
                              .saveSettings(
                                value.copyWith(
                                  runUpdateCueMode: selected.first,
                                ),
                              );
                        }
                      : null,
                ),
              ),
              _Section(
                title: 'Diagnostics',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Exports the last 10 session logs. Logs include GPS coordinates, pace, distance, settings, and app events.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      key: const Key('exportLogsButton'),
                      onPressed: () => _exportLogs(context, ref),
                      icon: const Icon(Icons.ios_share),
                      label: const Text('Export logs'),
                    ),
                  ],
                ),
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
    unawaited(
      ref.read(logServiceProvider).info('settings', 'Delete all runs tapped'),
    );
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
    unawaited(
      ref
          .read(logServiceProvider)
          .warning('settings', 'Delete all runs confirmed'),
    );
    await ref.read(runHistoryRepositoryProvider).deleteAllRuns();
    unawaited(
      ref.read(logServiceProvider).info('settings', 'All runs deleted'),
    );
  }

  Future<void> _exportLogs(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final log = ref.read(logServiceProvider);
    try {
      final files = await log.exportFiles();
      if (!context.mounted) return;
      if (files.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('No logs available')),
        );
        return;
      }
      final fileDetails = await Future.wait(
        files.map(
          (file) async => {
            'name': file.uri.pathSegments.last,
            'bytes': await file.length(),
          },
        ),
      );
      unawaited(
        log.info(
          'settings',
          'Diagnostics log files prepared',
          data: {'fileCount': files.length, 'files': fileDetails},
        ),
      );
      if (!context.mounted) return;
      final renderObject = context.findRenderObject();
      final shareOrigin = renderObject is RenderBox
          ? renderObject.localToGlobal(Offset.zero) & renderObject.size
          : null;
      final result = await SharePlus.instance.share(
        ShareParams(
          title: 'Runner Boi diagnostics logs',
          subject: 'Runner Boi diagnostics logs',
          text: 'Runner Boi diagnostics logs',
          files: files.map(_xFile).toList(),
          fileNameOverrides: files
              .map((file) => file.uri.pathSegments.last)
              .toList(),
          sharePositionOrigin: shareOrigin,
        ),
      );
      unawaited(
        log.info(
          'settings',
          'Diagnostics log share completed',
          data: {
            'fileCount': files.length,
            'status': result.status.name,
            'raw': result.raw,
          },
        ),
      );
    } catch (error, stackTrace) {
      unawaited(
        log.error(
          'settings',
          'Diagnostics log export failed',
          error: error,
          stackTrace: stackTrace,
        ),
      );
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Could not export logs: $error')),
      );
    }
  }

  XFile _xFile(File file) {
    return XFile(
      file.path,
      mimeType: 'application/jsonl',
      name: file.uri.pathSegments.last,
    );
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
