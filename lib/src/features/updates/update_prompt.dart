import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/update_service.dart';
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
    builder: (context) => AlertDialog(
      title: Text('Runner Boi ${release.version} is available'),
      content: Text(
        'Installed: ${result.currentVersion.display}\n'
        'Latest: ${release.version}\n\n'
        'Download opens the GitHub release APK in your browser.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(_UpdateAction.later),
          child: const Text('Later'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_UpdateAction.skipVersion),
          child: const Text('Skip version'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_UpdateAction.download),
          child: const Text('Download'),
        ),
      ],
    ),
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
