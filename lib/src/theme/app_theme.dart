import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData dark() {
    const bg = Color(0xFF070907);
    const surface = Color(0xFF10140F);
    const panel = Color(0xFF171D16);
    const panelElevated = Color(0xFF1D251B);
    const border = Color(0xFF334030);
    const text = Color(0xFFF4F7EF);
    const muted = Color(0xFFA4B09F);
    const accent = Color(0xFFB8FF3D);
    const cyan = Color(0xFF24D6C8);
    const rest = Color(0xFFFFB84D);
    const danger = Color(0xFFFF5C39);

    final scheme = ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: accent,
      surface: surface,
      primary: accent,
      secondary: cyan,
      tertiary: rest,
      error: danger,
      onSurface: text,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: scheme,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: bg,
        foregroundColor: text,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 72,
          height: 0.86,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
        headlineLarge: TextStyle(
          fontSize: 34,
          height: 1,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          height: 1.08,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        bodyMedium: TextStyle(fontSize: 14, height: 1.25, letterSpacing: 0),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ).apply(bodyColor: text, displayColor: text),
      cardTheme: CardThemeData(
        color: panel,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: accent.withValues(alpha: 0.16),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? accent : muted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.black,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          minimumSize: const Size(48, 48),
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: text,
          disabledForegroundColor: muted.withValues(alpha: 0.45),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? accent.withValues(alpha: 0.18)
                : surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? accent : text,
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.selected) ? accent : border,
            ),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: border,
        thumbColor: accent,
        overlayColor: accent.withValues(alpha: 0.14),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? accent : muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? accent.withValues(alpha: 0.24)
              : border.withValues(alpha: 0.72),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: border),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: panelElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: border),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: panelElevated,
        contentTextStyle: const TextStyle(color: text),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: border,
      ),
      extensions: const [
        RunnerColors(
          success: accent,
          info: cyan,
          warning: rest,
          danger: danger,
          muted: muted,
          panel: panel,
          panelElevated: panelElevated,
          border: border,
          runSurface: Color(0xFF182211),
          restSurface: Color(0xFF211B12),
        ),
      ],
    );
  }
}

class RunnerColors extends ThemeExtension<RunnerColors> {
  const RunnerColors({
    required this.success,
    required this.info,
    required this.warning,
    required this.danger,
    required this.muted,
    required this.panel,
    required this.panelElevated,
    required this.border,
    required this.runSurface,
    required this.restSurface,
  });

  final Color success;
  final Color info;
  final Color warning;
  final Color danger;
  final Color muted;
  final Color panel;
  final Color panelElevated;
  final Color border;
  final Color runSurface;
  final Color restSurface;

  @override
  RunnerColors copyWith({
    Color? success,
    Color? info,
    Color? warning,
    Color? danger,
    Color? muted,
    Color? panel,
    Color? panelElevated,
    Color? border,
    Color? runSurface,
    Color? restSurface,
  }) {
    return RunnerColors(
      success: success ?? this.success,
      info: info ?? this.info,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      muted: muted ?? this.muted,
      panel: panel ?? this.panel,
      panelElevated: panelElevated ?? this.panelElevated,
      border: border ?? this.border,
      runSurface: runSurface ?? this.runSurface,
      restSurface: restSurface ?? this.restSurface,
    );
  }

  @override
  RunnerColors lerp(ThemeExtension<RunnerColors>? other, double t) {
    if (other is! RunnerColors) return this;
    return RunnerColors(
      success: Color.lerp(success, other.success, t)!,
      info: Color.lerp(info, other.info, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      panelElevated: Color.lerp(panelElevated, other.panelElevated, t)!,
      border: Color.lerp(border, other.border, t)!,
      runSurface: Color.lerp(runSurface, other.runSurface, t)!,
      restSurface: Color.lerp(restSurface, other.restSurface, t)!,
    );
  }
}
