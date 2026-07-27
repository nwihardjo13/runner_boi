import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/formatters.dart';
import '../../domain/models.dart';
import '../providers.dart';
import '../run/run_screen.dart';

const _uuid = Uuid();

class WorkoutEditorScreen extends ConsumerStatefulWidget {
  const WorkoutEditorScreen({
    super.key,
    this.template,
    this.startFocused = false,
  });

  final WorkoutTemplate? template;
  final bool startFocused;

  @override
  ConsumerState<WorkoutEditorScreen> createState() =>
      _WorkoutEditorScreenState();
}

class _WorkoutEditorScreenState extends ConsumerState<WorkoutEditorScreen> {
  late final TextEditingController _nameController;
  late List<SegmentPlan> _segments;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.template?.name ?? 'New plan',
    );
    _segments = [...?widget.template?.segments];
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final units = settings.value?.measurementSystem ?? MeasurementSystem.metric;

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          TextButton(
            onPressed: _canSubmit ? _save : null,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Plan name'),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _addSegment(SegmentKind.run, units),
                    icon: const Icon(Icons.directions_run),
                    label: const Text('Run'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _addSegment(SegmentKind.rest, units),
                    icon: const Icon(Icons.self_improvement),
                    label: const Text('Rest'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _segments.isEmpty ? null : _repeatBlock,
              icon: const Icon(Icons.repeat),
              label: const Text('Repeat last block'),
            ),
            const SizedBox(height: 20),
            Text('Segments', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            if (_segments.isEmpty)
              const _EmptySegments()
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _segments.length,
                onReorderItem: (oldIndex, newIndex) {
                  setState(() {
                    final segment = _segments.removeAt(oldIndex);
                    _segments.insert(newIndex, segment);
                  });
                },
                itemBuilder: (context, index) {
                  final segment = _segments[index];
                  return Padding(
                    key: ValueKey(segment.id),
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SegmentCard(
                      index: index,
                      segment: segment,
                      units: units,
                      onEdit: () => _editSegment(index, units),
                      onDelete: () => setState(() => _segments.removeAt(index)),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: FilledButton.icon(
          key: const Key('startRunButton'),
          onPressed: _canSubmit ? _saveAndStart : null,
          icon: const Icon(Icons.play_arrow),
          label: Text(_isSaving ? 'Saving...' : 'Start run'),
        ),
      ),
    );
  }

  String get _title {
    if (widget.template != null) return 'Edit plan';
    return widget.startFocused ? 'Plan run' : 'New plan';
  }

  bool get _canSubmit => _segments.isNotEmpty && !_isSaving;

  Future<void> _addSegment(SegmentKind kind, MeasurementSystem units) async {
    final segment = SegmentPlan(
      id: _uuid.v4(),
      kind: kind,
      targetType: kind == SegmentKind.rest
          ? SegmentTargetType.time
          : SegmentTargetType.distance,
      durationSeconds: kind == SegmentKind.rest ? 90 : null,
      distanceMeters: kind == SegmentKind.run ? 400 : null,
    );
    final edited = await _showSegmentDialog(segment, units);
    if (edited == null) return;
    setState(() => _segments.add(edited));
  }

  Future<void> _editSegment(int index, MeasurementSystem units) async {
    final edited = await _showSegmentDialog(_segments[index], units);
    if (edited == null) return;
    setState(() => _segments[index] = edited);
  }

  Future<SegmentPlan?> _showSegmentDialog(
    SegmentPlan segment,
    MeasurementSystem units,
  ) {
    return showDialog<SegmentPlan>(
      context: context,
      builder: (_) => _SegmentDialog(segment: segment, units: units),
    );
  }

  Future<void> _repeatBlock() async {
    final result = await showDialog<_RepeatRequest>(
      context: context,
      builder: (_) => _RepeatDialog(maxBlockSize: _segments.length),
    );
    if (result == null) return;
    final block = _segments.sublist(_segments.length - result.blockSize);
    final additions = <SegmentPlan>[];
    for (var round = 0; round < result.additionalRepeats; round++) {
      additions.addAll(
        block.map((segment) => segment.copyWith(id: _uuid.v4())),
      );
    }
    setState(() => _segments.addAll(additions));
  }

  Future<WorkoutTemplate?> _persistTemplate() async {
    if (_isSaving) return null;
    setState(() => _isSaving = true);
    final now = DateTime.now();
    final existing = widget.template;
    final template = WorkoutTemplate(
      id: existing?.id ?? _uuid.v4(),
      name: _nameController.text.trim().isEmpty
          ? 'Untitled plan'
          : _nameController.text.trim(),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      segments: _segments,
    );
    try {
      await ref.read(templatesProvider.notifier).save(template);
      return template;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _save() async {
    final template = await _persistTemplate();
    if (template != null && mounted) Navigator.of(context).pop();
  }

  Future<void> _saveAndStart() async {
    final template = await _persistTemplate();
    if (template == null || !mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => RunScreen(template: template)),
    );
  }
}

class _SegmentCard extends StatelessWidget {
  const _SegmentCard({
    required this.index,
    required this.segment,
    required this.units,
    required this.onEdit,
    required this.onDelete,
  });

  final int index;
  final SegmentPlan segment;
  final MeasurementSystem units;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isRest = segment.kind == SegmentKind.rest;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isRest
              ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.18)
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
          child: Text('${index + 1}'),
        ),
        title: Text(isRest ? 'Rest' : 'Run'),
        subtitle: Text(
          [
            formatSegmentTarget(segment, units),
            if (segment.targetPaceSecondsPerKm != null)
              formatPace(segment.targetPaceSecondsPerKm, units),
          ].join(' · '),
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
            ),
            const Icon(Icons.drag_handle),
          ],
        ),
      ),
    );
  }
}

class _SegmentDialog extends StatefulWidget {
  const _SegmentDialog({required this.segment, required this.units});

  final SegmentPlan segment;
  final MeasurementSystem units;

  @override
  State<_SegmentDialog> createState() => _SegmentDialogState();
}

class _SegmentDialogState extends State<_SegmentDialog> {
  late SegmentKind _kind;
  late SegmentTargetType _targetType;
  late bool _hasPace;
  late String _metricDistanceUnit;
  late final TextEditingController _distanceController;
  late final TextEditingController _hoursController;
  late final TextEditingController _minutesController;
  late final TextEditingController _secondsController;
  late final TextEditingController _paceMinutesController;
  late final TextEditingController _paceSecondsController;

  @override
  void initState() {
    super.initState();
    final segment = widget.segment;
    _kind = segment.kind;
    _targetType = segment.targetType;
    _hasPace = segment.targetPaceSecondsPerKm != null;
    _metricDistanceUnit = (segment.distanceMeters ?? 0) < 1000 ? 'm' : 'km';
    _distanceController = TextEditingController(text: _distanceValue(segment));
    final duration = segment.durationSeconds ?? 0;
    _hoursController = TextEditingController(text: '${duration ~/ 3600}');
    _minutesController = TextEditingController(
      text: '${(duration % 3600) ~/ 60}',
    );
    _secondsController = TextEditingController(text: '${duration % 60}');
    final pace = _paceForUnits(segment.targetPaceSecondsPerKm, widget.units);
    _paceMinutesController = TextEditingController(
      text: pace == null ? '' : '${pace ~/ 60}',
    );
    _paceSecondsController = TextEditingController(
      text: pace == null ? '' : '${pace % 60}',
    );
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    _paceMinutesController.dispose();
    _paceSecondsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unitLabel = widget.units == MeasurementSystem.imperial
        ? 'mi'
        : _metricDistanceUnit;
    return AlertDialog(
      title: const Text('Segment'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<SegmentKind>(
              segments: const [
                ButtonSegment(value: SegmentKind.run, label: Text('Run')),
                ButtonSegment(value: SegmentKind.rest, label: Text('Rest')),
              ],
              selected: {_kind},
              onSelectionChanged: (value) =>
                  setState(() => _kind = value.first),
            ),
            const SizedBox(height: 14),
            SegmentedButton<SegmentTargetType>(
              segments: const [
                ButtonSegment(
                  value: SegmentTargetType.time,
                  label: Text('Time'),
                ),
                ButtonSegment(
                  value: SegmentTargetType.distance,
                  label: Text('Distance'),
                ),
                ButtonSegment(
                  value: SegmentTargetType.manual,
                  label: Text('Manual'),
                ),
              ],
              selected: {_targetType},
              onSelectionChanged: (value) =>
                  setState(() => _targetType = value.first),
            ),
            const SizedBox(height: 16),
            if (_targetType == SegmentTargetType.time) _timeFields(),
            if (_targetType == SegmentTargetType.distance)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _distanceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Distance ($unitLabel)',
                      ),
                    ),
                  ),
                  if (widget.units == MeasurementSystem.metric) ...[
                    const SizedBox(width: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'm', label: Text('m')),
                        ButtonSegment(value: 'km', label: Text('km')),
                      ],
                      selected: {_metricDistanceUnit},
                      onSelectionChanged: (value) {
                        setState(() => _metricDistanceUnit = value.first);
                      },
                    ),
                  ],
                ],
              ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _hasPace,
              onChanged: (value) => setState(() => _hasPace = value),
              title: const Text('Target pace'),
            ),
            if (_hasPace) _paceFields(),
            if (_targetType == SegmentTargetType.manual)
              Text(
                'Voice cue: fuck about segment',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_buildSegment()),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _timeFields() {
    return Row(
      children: [
        Expanded(child: _numberField(_hoursController, 'Hours')),
        const SizedBox(width: 8),
        Expanded(child: _numberField(_minutesController, 'Minutes')),
        const SizedBox(width: 8),
        Expanded(child: _numberField(_secondsController, 'Seconds')),
      ],
    );
  }

  Widget _paceFields() {
    final suffix = widget.units == MeasurementSystem.imperial
        ? 'per mi'
        : 'per km';
    return Row(
      children: [
        Expanded(child: _numberField(_paceMinutesController, 'Pace min')),
        const SizedBox(width: 8),
        Expanded(child: _numberField(_paceSecondsController, 'sec $suffix')),
      ],
    );
  }

  Widget _numberField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label),
    );
  }

  SegmentPlan _buildSegment() {
    final duration =
        _int(_hoursController) * 3600 +
        _int(_minutesController) * 60 +
        _int(_secondsController);
    final distance = _distanceMeters();
    final pace = _hasPace
        ? paceInputToSecondsPerKm(
            minutes: _int(_paceMinutesController),
            seconds: _int(_paceSecondsController),
            units: widget.units,
          )
        : null;
    return widget.segment.copyWith(
      kind: _kind,
      targetType: _targetType,
      durationSeconds: _targetType == SegmentTargetType.time ? duration : null,
      distanceMeters: _targetType == SegmentTargetType.distance
          ? distance
          : null,
      targetPaceSecondsPerKm: pace,
      clearDuration: _targetType != SegmentTargetType.time,
      clearDistance: _targetType != SegmentTargetType.distance,
      clearPace: !_hasPace || pace == null,
    );
  }

  double? _distanceMeters() {
    final value = double.tryParse(_distanceController.text);
    if (value == null || value <= 0) return null;
    if (widget.units == MeasurementSystem.imperial) {
      return value * metersPerMile;
    }
    return _metricDistanceUnit == 'm' ? value : value * 1000;
  }

  String _distanceValue(SegmentPlan segment) {
    final meters = segment.distanceMeters;
    if (meters == null) return '';
    if (widget.units == MeasurementSystem.imperial) {
      return (meters / metersPerMile).toStringAsFixed(2);
    }
    if (meters < 1000) return meters.round().toString();
    return (meters / 1000).toStringAsFixed(2);
  }

  int? _paceForUnits(double? secondsPerKm, MeasurementSystem units) {
    if (secondsPerKm == null) return null;
    if (units == MeasurementSystem.imperial) {
      return (secondsPerKm * metersPerMile / 1000).round();
    }
    return secondsPerKm.round();
  }

  int _int(TextEditingController controller) =>
      int.tryParse(controller.text) ?? 0;
}

class _RepeatRequest {
  const _RepeatRequest({
    required this.blockSize,
    required this.additionalRepeats,
  });

  final int blockSize;
  final int additionalRepeats;
}

class _RepeatDialog extends StatefulWidget {
  const _RepeatDialog({required this.maxBlockSize});

  final int maxBlockSize;

  @override
  State<_RepeatDialog> createState() => _RepeatDialogState();
}

class _RepeatDialogState extends State<_RepeatDialog> {
  late final TextEditingController _blockController;
  late final TextEditingController _repeatController;

  @override
  void initState() {
    super.initState();
    _blockController = TextEditingController(
      text: widget.maxBlockSize >= 2 ? '2' : '1',
    );
    _repeatController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _blockController.dispose();
    _repeatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Repeat block'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _blockController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Last segments in block',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _repeatController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Additional repeats'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final block = (int.tryParse(_blockController.text) ?? 1).clamp(
              1,
              widget.maxBlockSize,
            );
            final repeats = (int.tryParse(_repeatController.text) ?? 1).clamp(
              1,
              20,
            );
            Navigator.of(
              context,
            ).pop(_RepeatRequest(blockSize: block, additionalRepeats: repeats));
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _EmptySegments extends StatelessWidget {
  const _EmptySegments();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF303A30)),
      ),
      child: const Text('Add a run or rest segment to start.'),
    );
  }
}
