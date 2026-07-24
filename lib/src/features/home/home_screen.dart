import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../domain/models.dart';
import '../providers.dart';
import '../run/run_screen.dart';
import '../workouts/workout_editor_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(templatesProvider);
    final settings = ref.watch(settingsControllerProvider);
    final units = settings.value?.measurementSystem ?? MeasurementSystem.metric;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Runner Boi',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Build the plan. Lock GPS. Do the segment.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () => _openEditor(context),
                      icon: const Icon(Icons.add),
                      label: const Text('New plan'),
                    ),
                  ],
                ),
              ),
            ),
            templates.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => SliverFillRemaining(
                child: Center(child: Text('Could not load plans: $error')),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('No plans yet')),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  sliver: SliverList.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _WorkoutCard(template: items[index], units: units);
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

  void _openEditor(BuildContext context, {WorkoutTemplate? template}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkoutEditorScreen(template: template),
      ),
    );
  }
}

class _WorkoutCard extends ConsumerWidget {
  const _WorkoutCard({required this.template, required this.units});

  final WorkoutTemplate template;
  final MeasurementSystem units;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    template.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    switch (value) {
                      case 'edit':
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                WorkoutEditorScreen(template: template),
                          ),
                        );
                      case 'copy':
                        await ref
                            .read(templatesProvider.notifier)
                            .duplicate(template);
                      case 'delete':
                        await ref
                            .read(templatesProvider.notifier)
                            .delete(template.id);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'copy', child: Text('Copy')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              plannedSummary(template.segments, units),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _SegmentRail(template: template, units: units),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: template.segments.isEmpty
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => RunScreen(template: template),
                              ),
                            );
                          },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start'),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => WorkoutEditorScreen(template: template),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentRail extends StatelessWidget {
  const _SegmentRail({required this.template, required this.units});

  final WorkoutTemplate template;
  final MeasurementSystem units;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: template.segments.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final segment = template.segments[index];
          final isRest = segment.kind == SegmentKind.rest;
          return Container(
            width: 118,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isRest ? const Color(0xFF14191D) : const Color(0xFF161D11),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF303A30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${index + 1}. ${isRest ? 'REST' : 'RUN'}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const Spacer(),
                Text(
                  formatSegmentTarget(segment, units),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  segment.targetPaceSecondsPerKm == null
                      ? 'no pace'
                      : formatPace(segment.targetPaceSecondsPerKm, units),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
