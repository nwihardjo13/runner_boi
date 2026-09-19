import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/update_service.dart';
import '../../theme/app_theme.dart';
import '../providers.dart';

Future<void> showUpdatePrompt(
  BuildContext context,
  WidgetRef ref,
  UpdateCheckResult result,
) async {
  final release = result.release;
  if (release == null) return;
  final messenger = ScaffoldMessenger.of(context);

  final action = await showDialog<_UpdateAction>(
    context: context,
    builder: (context) {
      final runnerColors = Theme.of(context).extension<RunnerColors>()!;
      return AlertDialog(
        icon: Icon(Icons.system_update_alt, color: runnerColors.success),
        title: Text('Runner Boi ${release.version}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _VersionLine(
              label: 'Installed',
              value: result.currentVersion.display,
            ),
            const SizedBox(height: 8),
            _VersionLine(label: 'Latest', value: release.version),
            const SizedBox(height: 14),
            Text(
              'Download opens the GitHub release APK in your browser.',
              style: TextStyle(color: runnerColors.muted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_UpdateAction.later),
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_UpdateAction.skipVersion),
            child: const Text('Skip'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_UpdateAction.download),
            child: const Text('Download'),
          ),
        ],
      );
    },
  );
  if (!context.mounted || action == null || action == _UpdateAction.later) {
    return;
  }

  final service = await ref.read(selfUpdateServiceProvider.future);
  switch (action) {
    case _UpdateAction.skipVersion:
      await service.dismissVersion(release.version);
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Skipped Runner Boi ${release.version}')),
      );
    case _UpdateAction.download:
      final opened = await service.openUpdate(release);
      if (!context.mounted) return;
      if (!opened) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not open update download')),
        );
      }
    case _UpdateAction.later:
      break;
  }
}

enum _UpdateAction { later, skipVersion, download }

class _VersionLine extends StatelessWidget {
  const _VersionLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final runnerColors = Theme.of(context).extension<RunnerColors>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: runnerColors.panelElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: runnerColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
