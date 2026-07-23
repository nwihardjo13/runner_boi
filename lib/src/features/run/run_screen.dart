import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../domain/models.dart';
import '../../theme/app_theme.dart';
import '../providers.dart';

class RunScreen extends ConsumerStatefulWidget {
  const RunScreen({super.key, required this.template});

  final WorkoutTemplate template;

  @override
  ConsumerState<RunScreen> createState() => _RunScreenState();
}

class _RunScreenState extends ConsumerState<RunScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(runControllerProvider.notifier).prepare(widget.template);
    });
  }

  @override
  Widget build(BuildContext context) {
    final run = ref.watch(runControllerProvider);
    final settings = ref.watch(settingsControllerProvider);
    final units = settings.value?.measurementSystem ?? MeasurementSystem.metric;

    return PopScope(
      canPop: !run.isActive,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || !run.isActive) return;
        final end = await _confirmEnd(context);
        if (end && context.mounted) {
          await ref.read(runControllerProvider.notifier).endRun();
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: switch (run.phase) {
              RunPhase.gpsLock ||
              RunPhase.idle => _GpsLock(run: run, units: units),
              RunPhase.countdown => _Countdown(run: run, units: units),
              RunPhase.running ||
              RunPhase.paused => _Cockpit(run: run, units: units),
              RunPhase.complete => _Complete(run: run, units: units),
            },
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmEnd(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('End run?'),
            content: const Text('Current progress will be saved.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('End'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _GpsLock extends ConsumerWidget {
  const _GpsLock({required this.run, required this.units});

  final RunState run;
  final MeasurementSystem units;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fix = run.gpsFix;
    final colors = Theme.of(context).extension<RunnerColors>()!;
    final canStart = fix?.canStart == true || run.allowStartAnyway;
    final color = switch (fix?.quality) {
      GpsQuality.excellent => colors.success,
      GpsQuality.good => colors.success,
      GpsQuality.weak => colors.warning,
      GpsQuality.bad => colors.danger,
      _ => colors.muted,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
          tooltip: 'Close',
        ),
        const Spacer(),
        Text('GPS LOCK', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 12),
        Text(
          fix?.message ?? 'Waiting for GPS',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 10),
        Text(
          'Accuracy ${formatGpsAccuracy(fix?.accuracyMeters)}',
          style: TextStyle(color: color, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 24),
        Text(
          plannedSummary(run.workout?.segments ?? const [], units),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    ref.read(runControllerProvider.notifier).refreshGps(),
                icon: const Icon(Icons.my_location),
                label: const Text('Refresh'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: canStart
                    ? () => ref.read(runControllerProvider.notifier).start()
                    : null,
                icon: const Icon(Icons.play_arrow),
                label: Text(run.allowStartAnyway ? 'Start anyway' : 'Start'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Countdown extends StatelessWidget {
  const _Countdown({required this.run, required this.units});

  final RunState run;
  final MeasurementSystem units;

  @override
  Widget build(BuildContext context) {
    final segment = run.currentSegment;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        Text('NEXT', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 12),
        Text(
          segment == null ? 'Loading segment' : segmentCue(segment, units),
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 16),
        const LinearProgressIndicator(),
        const Spacer(),
      ],
    );
  }
}

class _Cockpit extends ConsumerWidget {
  const _Cockpit({required this.run, required this.units});

  final RunState run;
  final MeasurementSystem units;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segment = run.currentSegment!;
    final segmentTarget = segment.targetType == SegmentTargetType.distance
        ? segment.distanceMeters ?? 0
        : (segment.durationSeconds ?? 0).toDouble();
    final segmentDone = segment.targetType == SegmentTargetType.distance
        ? run.segmentDistanceMeters
        : run.elapsedSegmentSeconds.toDouble();
    final progress =
        segment.targetType == SegmentTargetType.manual || segmentTarget <= 0
        ? null
        : (segmentDone / segmentTarget).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${run.segmentIndex + 1}/${run.workout?.segments.length ?? 0} ${segment.kind.name.toUpperCase()}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
            Text(
              run.phase == RunPhase.paused ? 'PAUSED' : 'LIVE',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('CURRENT PACE', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 6),
        FittedBox(
          alignment: Alignment.centerLeft,
          fit: BoxFit.scaleDown,
          child: Text(
            formatPace(run.currentPaceSecondsPerKm, units),
            style: Theme.of(context).textTheme.displayLarge,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'Segment avg',
                value: formatPace(run.segmentAveragePaceSecondsPerKm, units),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricTile(
                label: 'Segment dist',
                value: formatDistance(run.segmentDistanceMeters, units),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                label: 'Segment time',
                value: formatDurationClock(run.elapsedSegmentSeconds),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricTile(
                label: 'GPS',
                value: formatGpsAccuracy(run.gpsFix?.accuracyMeters),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _SegmentProgress(
          segment: segment,
          run: run,
          units: units,
          progress: progress,
        ),
        const SizedBox(height: 12),
        _PrevNext(run: run, units: units),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    ref.read(runControllerProvider.notifier).skipSegment(),
                icon: const Icon(Icons.skip_next),
                label: const Text('Next'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  final controller = ref.read(runControllerProvider.notifier);
                  if (run.phase == RunPhase.paused) {
                    controller.resume();
                  } else {
                    controller.pause();
                  }
                },
                icon: Icon(
                  run.phase == RunPhase.paused ? Icons.play_arrow : Icons.pause,
                ),
                label: Text(run.phase == RunPhase.paused ? 'Resume' : 'Pause'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              onPressed: () =>
                  ref.read(runControllerProvider.notifier).endRun(),
              icon: const Icon(Icons.stop),
              tooltip: 'End',
            ),
          ],
        ),
      ],
    );
  }
}

class _SegmentProgress extends StatelessWidget {
  const _SegmentProgress({
    required this.segment,
    required this.run,
    required this.units,
    required this.progress,
  });

  final SegmentPlan segment;
  final RunState run;
  final MeasurementSystem units;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final done = segment.targetType == SegmentTargetType.distance
        ? formatDistance(run.segmentDistanceMeters, units)
        : formatDurationClock(run.elapsedSegmentSeconds);
    final target = formatSegmentTarget(segment, units);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    segmentCue(segment, units),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text('$done / $target'),
              ],
            ),
            if (progress != null) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: progress),
            ],
          ],
        ),
      ),
    );
  }
}

class _PrevNext extends StatelessWidget {
  const _PrevNext({required this.run, required this.units});

  final RunState run;
  final MeasurementSystem units;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SmallSegment(
            label: 'Prev',
            segment: run.previousSegment,
            units: units,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SmallSegment(
            label: 'Next',
            segment: run.nextSegment,
            units: units,
          ),
        ),
      ],
    );
  }
}

class _SmallSegment extends StatelessWidget {
  const _SmallSegment({
    required this.label,
    required this.segment,
    required this.units,
  });

  final String label;
  final SegmentPlan? segment;
  final MeasurementSystem units;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF303A30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 4),
          Text(
            segment == null ? '--' : segmentCue(segment!, units),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _Complete extends ConsumerWidget {
  const _Complete({required this.run, required this.units});

  final RunState run;
  final MeasurementSystem units;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        Text('SAVED', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 12),
        Text('Run done', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 18),
        _MetricTile(
          label: 'Total time',
          value: formatDurationClock(run.elapsedTotalSeconds),
        ),
        const SizedBox(height: 8),
        _MetricTile(
          label: 'Total distance',
          value: formatDistance(run.totalDistanceMeters, units),
        ),
        const Spacer(),
        FilledButton.icon(
          onPressed: () {
            ref.read(runControllerProvider.notifier).reset();
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.check),
          label: const Text('Done'),
        ),
      ],
    );
  }
}
