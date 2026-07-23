import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/formatters.dart';
import '../../domain/models.dart';
import '../providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runs = ref.watch(runHistoryProvider);
    final settings = ref.watch(settingsControllerProvider);
    final units = settings.value?.measurementSystem ?? MeasurementSystem.metric;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'history',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
            ),
            runs.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => SliverFillRemaining(
                child: Center(child: Text('Could not load history: $error')),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('No runs saved yet')),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  sliver: SliverList.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _RunCard(run: items[index], units: units);
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RunCard extends ConsumerWidget {
  const _RunCard({required this.run, required this.units});

  final RunRecord run;
  final MeasurementSystem units;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          run.workoutName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(DateFormat('EEE, d MMM · HH:mm').format(run.startedAt)),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'delete') {
              await ref.read(runHistoryRepositoryProvider).deleteRun(run.id);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Row(
            children: [
              Expanded(
                child: _HistoryMetric(
                  label: 'Distance',
                  value: formatDistance(run.totalDistanceMeters, units),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HistoryMetric(
                  label: 'Time',
                  value: formatDurationClock(run.totalElapsedSeconds),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HistoryMetric(
                  label: 'Avg',
                  value: formatPace(run.averagePaceSecondsPerKm, units),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final result in run.segmentResults)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SegmentResultRow(result: result, units: units),
            ),
        ],
      ),
    );
  }
}

class _HistoryMetric extends StatelessWidget {
  const _HistoryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
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
          const SizedBox(height: 6),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _SegmentResultRow extends StatelessWidget {
  const _SegmentResultRow({required this.result, required this.units});

  final SegmentResult result;
  final MeasurementSystem units;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0F0C),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 14, child: Text('${result.segmentIndex + 1}')),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.plannedLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${formatDistance(result.distanceMeters, units)} · ${formatDurationClock(result.elapsedSeconds)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(formatPace(result.averagePaceSecondsPerKm, units)),
        ],
      ),
    );
  }
}
