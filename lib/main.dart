import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';
import 'src/features/providers.dart';
import 'src/services/log_service.dart';

Future<void> main() async {
  AppLogService? logService;
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      logService = AppLogService();
      await logService!.start();
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        unawaited(
          logService!.error(
            'flutter',
            'Uncaught Flutter framework error',
            data: {
              'library': details.library,
              'context': details.context?.toString(),
            },
            error: details.exception,
            stackTrace: details.stack,
          ),
        );
      };
      ui.PlatformDispatcher.instance.onError = (error, stackTrace) {
        unawaited(
          logService!.error(
            'platform',
            'Uncaught platform dispatcher error',
            error: error,
            stackTrace: stackTrace,
          ),
        );
        return false;
      };
      unawaited(
        logService!.info(
          'app',
          'Runner Boi app started',
          data: {
            'mode': kReleaseMode
                ? 'release'
                : kProfileMode
                ? 'profile'
                : 'debug',
            'targetPlatform': defaultTargetPlatform.name,
            'operatingSystem': Platform.operatingSystem,
            'operatingSystemVersion': Platform.operatingSystemVersion,
            'localeName': Platform.localeName,
            'localTimeZoneName': DateTime.now().timeZoneName,
            'timeZoneOffsetMinutes': DateTime.now().timeZoneOffset.inMinutes,
            'numberOfProcessors': Platform.numberOfProcessors,
          },
        ),
      );
      runApp(
        ProviderScope(
          overrides: [logServiceProvider.overrideWithValue(logService!)],
          child: const RunnerBoiApp(),
        ),
      );
    },
    (error, stackTrace) {
      final logger = logService;
      if (logger == null) {
        developer.log(
          'Uncaught Dart zone error before log service startup',
          name: 'runner_boi',
          error: error,
          stackTrace: stackTrace,
        );
        return;
      }
      unawaited(
        logger.error(
          'zone',
          'Uncaught Dart zone error',
          error: error,
          stackTrace: stackTrace,
        ),
      );
    },
  );
}
