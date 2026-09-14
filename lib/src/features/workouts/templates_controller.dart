import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models.dart';
import '../app_providers.dart';

const _uuid = Uuid();

final templatesProvider =
    AsyncNotifierProvider<TemplatesController, List<WorkoutTemplate>>(
      TemplatesController.new,
    );

class TemplatesController extends AsyncNotifier<List<WorkoutTemplate>> {
  @override
  Future<List<WorkoutTemplate>> build() async {
    final repository = ref.watch(workoutRepositoryProvider);
    final templates = await repository.listTemplates();
    unawaited(
      ref
          .read(logServiceProvider)
          .info(
            'templates',
            'Templates loaded',
            data: {'count': templates.length},
          ),
    );
    if (templates.isNotEmpty) return templates;
    final starter = _starterTemplate();
    await repository.saveTemplate(starter);
    unawaited(
      ref
          .read(logServiceProvider)
          .info(
            'templates',
            'Starter template created',
            data: _workoutLogData(starter),
          ),
    );
    return [starter];
  }

  Future<void> save(WorkoutTemplate template) async {
    final repository = ref.read(workoutRepositoryProvider);
    final now = DateTime.now();
    final next = template.copyWith(updatedAt: now);
    unawaited(
      ref
          .read(logServiceProvider)
          .info(
            'templates',
            'Template save requested',
            data: _workoutLogData(next),
          ),
    );
    await repository.saveTemplate(next);
    state = AsyncData(await repository.listTemplates());
    unawaited(
      ref
          .read(logServiceProvider)
          .info('templates', 'Template saved', data: _workoutLogData(next)),
    );
  }

  Future<void> delete(String id) async {
    unawaited(
      ref
          .read(logServiceProvider)
          .info(
            'templates',
            'Template delete requested',
            data: {'templateId': id},
          ),
    );
    final repository = ref.read(workoutRepositoryProvider);
    await repository.deleteTemplate(id);
    state = AsyncData(await repository.listTemplates());
    unawaited(
      ref
          .read(logServiceProvider)
          .info('templates', 'Template deleted', data: {'templateId': id}),
    );
  }

  Future<void> duplicate(WorkoutTemplate template) async {
    final now = DateTime.now();
    final duplicate = template.copyWith(
      id: _uuid.v4(),
      name: '${template.name} copy',
      createdAt: now,
      updatedAt: now,
      segments: template.segments
          .map((segment) => segment.copyWith(id: _uuid.v4()))
          .toList(),
    );
    unawaited(
      ref
          .read(logServiceProvider)
          .info(
            'templates',
            'Template duplicate requested',
            data: {
              'sourceTemplateId': template.id,
              'duplicateTemplateId': duplicate.id,
              'segmentCount': duplicate.segments.length,
            },
          ),
    );
    await save(duplicate);
  }

  WorkoutTemplate _starterTemplate() {
    final now = DateTime.now();
    return WorkoutTemplate(
      id: _uuid.v4(),
      name: 'Easy intervals',
      createdAt: now,
      updatedAt: now,
      segments: [
        SegmentPlan(
          id: _uuid.v4(),
          kind: SegmentKind.run,
          targetType: SegmentTargetType.time,
          durationSeconds: 5 * 60,
        ),
        SegmentPlan(
          id: _uuid.v4(),
          kind: SegmentKind.rest,
          targetType: SegmentTargetType.time,
          durationSeconds: 90,
        ),
        SegmentPlan(
          id: _uuid.v4(),
          kind: SegmentKind.run,
          targetType: SegmentTargetType.distance,
          distanceMeters: 400,
        ),
      ],
    );
  }

  Map<String, Object?> _workoutLogData(WorkoutTemplate workout) {
    return {
      'workoutId': workout.id,
      'name': workout.name,
      'segmentCount': workout.segments.length,
      'createdAt': workout.createdAt,
      'updatedAt': workout.updatedAt,
      'segments': workout.segments.map(_segmentLogData).toList(),
    };
  }

  Map<String, Object?> _segmentLogData(SegmentPlan segment) {
    return {
      'segmentId': segment.id,
      'kind': segment.kind,
      'targetType': segment.targetType,
      'durationSeconds': segment.durationSeconds,
      'distanceMeters': segment.distanceMeters,
      'targetPaceSecondsPerKm': segment.targetPaceSecondsPerKm,
    };
  }
}
