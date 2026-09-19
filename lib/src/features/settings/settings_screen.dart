import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/models.dart';
import '../../services/update_service.dart';
import '../../theme/app_theme.dart';
import '../providers.dart';
import '../updates/update_prompt.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final runnerColors = Theme.of(context).extension<RunnerColors>()!;

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
                'Settings',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 20),
              _Section(
                title: 'Units',
                child: SegmentedButton<MeasurementSystem>(
                  expandedInsets: EdgeInsets.zero,
                  showSelectedIcon: false,
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
                  expandedInsets: EdgeInsets.zero,
                  showSelectedIcon: false,
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
              _Section(
                title: 'Audio',
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: value.voiceCuesEnabled,
                      onChanged: (enabled) {
                        ref
                            .read(settingsControllerProvider.notifier)
                            .saveSettings(
                              value.copyWith(voiceCuesEnabled: enabled),
                            );
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
                                  .saveSettings(
                                    value.copyWith(duckAudio: enabled),
                                  );
                            }
                          : null,
                      title: const Text('Pause music during cues'),
                    ),
                  ],
                ),
              ),
              _Section(
                title: 'Run updates',
                child: _RunUpdateSection(
                  settings: value,
                  onChanged: (next) {
                    ref
                        .read(settingsControllerProvider.notifier)
                        .saveSettings(next);
                  },
                ),
              ),
              _Section(
                title: 'Updates',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AppVersionRow(version: ref.watch(packageInfoProvider)),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      key: const Key('checkForUpdatesButton'),
                      onPressed: () => _checkForUpdates(context, ref),
                      icon: const Icon(Icons.system_update_alt),
                      label: const Text('Check for updates'),
                    ),
                  ],
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
                style: OutlinedButton.styleFrom(
                  foregroundColor: runnerColors.danger,
                  side: BorderSide(
                    color: runnerColors.danger.withValues(alpha: 0.52),
                  ),
                ),
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

  Future<void> _checkForUpdates(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final log = ref.read(logServiceProvider);
    unawaited(log.info('updates', 'Manual self-update check tapped'));
    try {
      final service = await ref.read(selfUpdateServiceProvider.future);
      final result = await service.checkForUpdate(
        force: true,
        respectDismissedVersion: false,
      );
      if (!context.mounted) return;
      if (result.hasUpdate) {
        await showUpdatePrompt(context, ref, result);
        return;
      }
      if (result.status == UpdateCheckStatus.upToDate) {
        await _showUpToDateDialog(context, result);
        return;
      }
      final message = switch (result.status) {
        UpdateCheckStatus.upToDate => 'Runner Boi is up to date',
        UpdateCheckStatus.unavailable =>
          'Could not check updates: ${result.message ?? 'unknown error'}',
        UpdateCheckStatus.dismissed => 'Latest update is skipped for now',
        UpdateCheckStatus.skipped => 'Update check skipped',
        UpdateCheckStatus.updateAvailable => 'Update available',
      };
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (error, stackTrace) {
      unawaited(
        log.error(
          'updates',
          'Manual self-update check failed',
          error: error,
          stackTrace: stackTrace,
        ),
      );
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Could not check updates: $error')),
      );
    }
  }

  Future<void> _showUpToDateDialog(
    BuildContext context,
    UpdateCheckResult result,
  ) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.check_circle_outline,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Runner Boi is up to date'),
        content: Text(
          'You are running version ${result.currentVersion.display}.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  XFile _xFile(File file) {
    return XFile(
      file.path,
      mimeType: 'application/jsonl',
      name: file.uri.pathSegments.last,
    );
  }
}

class _AppVersionRow extends StatelessWidget {
  const _AppVersionRow({required this.version});

  final AsyncValue<PackageInfo> version;

  @override
  Widget build(BuildContext context) {
    final text = version.when(
      data: (packageInfo) =>
          '${packageInfo.version}+${packageInfo.buildNumber}',
      loading: () => 'Loading...',
      error: (_, _) => 'Unavailable',
    );
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('App version'),
      trailing: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _RunUpdateSection extends StatefulWidget {
  const _RunUpdateSection({required this.settings, required this.onChanged});

  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;

  @override
  State<_RunUpdateSection> createState() => _RunUpdateSectionState();
}

class _RunUpdateSectionState extends State<_RunUpdateSection> {
  late final TextEditingController _minutesController;
  late final TextEditingController _distanceController;

  @override
  void initState() {
    super.initState();
    _minutesController = TextEditingController(
      text: widget.settings.runUpdateMinutes.toString(),
    );
    _distanceController = TextEditingController(
      text: _formatDistanceInput(widget.settings.runUpdateDistance),
    );
  }

  @override
  void didUpdateWidget(covariant _RunUpdateSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings.runUpdateMinutes !=
        widget.settings.runUpdateMinutes) {
      _minutesController.text = widget.settings.runUpdateMinutes.toString();
    }
    if (oldWidget.settings.runUpdateDistance !=
        widget.settings.runUpdateDistance) {
      _distanceController.text = _formatDistanceInput(
        widget.settings.runUpdateDistance,
      );
    }
  }

  @override
  void dispose() {
    _minutesController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final enabled = settings.voiceCuesEnabled;
    final distanceUnit =
        settings.measurementSystem == MeasurementSystem.imperial ? 'mi' : 'km';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<RunUpdateCueMode>(
          expandedInsets: EdgeInsets.zero,
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: RunUpdateCueMode.off, label: Text('Off')),
            ButtonSegment(value: RunUpdateCueMode.time, label: Text('Time')),
            ButtonSegment(
              value: RunUpdateCueMode.distance,
              label: Text('Distance'),
            ),
          ],
          selected: {settings.runUpdateCueMode},
          onSelectionChanged: enabled
              ? (selected) {
                  widget.onChanged(
                    settings.copyWith(runUpdateCueMode: selected.first),
                  );
                }
              : null,
        ),
        if (!enabled) ...[
          const SizedBox(height: 10),
          Text(
            'Enable voice cues to use run updates.',
            style: TextStyle(color: Theme.of(context).disabledColor),
          ),
        ],
        if (enabled && settings.runUpdateCueMode == RunUpdateCueMode.time) ...[
          const SizedBox(height: 12),
          _IntervalInput(
            controller: _minutesController,
            label: 'Every',
            suffix: 'min',
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            keyboardType: TextInputType.number,
            onApply: _saveMinutes,
          ),
        ],
        if (enabled &&
            settings.runUpdateCueMode == RunUpdateCueMode.distance) ...[
          const SizedBox(height: 12),
          _IntervalInput(
            controller: _distanceController,
            label: 'Every',
            suffix: distanceUnit,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onApply: _saveDistance,
          ),
        ],
      ],
    );
  }

  void _saveMinutes() {
    final parsed = int.tryParse(_minutesController.text);
    final minutes = (parsed ?? widget.settings.runUpdateMinutes)
        .clamp(1, 240)
        .toInt();
    _minutesController.text = minutes.toString();
    widget.onChanged(widget.settings.copyWith(runUpdateMinutes: minutes));
  }

  void _saveDistance() {
    final parsed = double.tryParse(_distanceController.text);
    final distance = (parsed ?? widget.settings.runUpdateDistance)
        .clamp(0.1, 100)
        .toDouble();
    _distanceController.text = _formatDistanceInput(distance);
    widget.onChanged(widget.settings.copyWith(runUpdateDistance: distance));
  }

  String _formatDistanceInput(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}

class _IntervalInput extends StatelessWidget {
  const _IntervalInput({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.inputFormatters,
    required this.keyboardType,
    required this.onApply,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;
  final List<TextInputFormatter> inputFormatters;
  final TextInputType keyboardType;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: label, suffixText: suffix),
            inputFormatters: inputFormatters,
            keyboardType: keyboardType,
            onEditingComplete: onApply,
            onSubmitted: (_) => onApply(),
          ),
        ),
        const SizedBox(width: 10),
        IconButton.filledTonal(
          onPressed: onApply,
          icon: const Icon(Icons.check),
          tooltip: 'Apply',
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final runnerColors = Theme.of(context).extension<RunnerColors>()!;
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: runnerColors.panelElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: runnerColors.border),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
