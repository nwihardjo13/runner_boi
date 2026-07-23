import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData dark() {
    const bg = Color(0xFF070807);
    const surface = Color(0xFF101310);
    const panel = Color(0xFF171C18);
    const text = Color(0xFFF2F5EE);
    const muted = Color(0xFF9EA89C);
    const accent = Color(0xFFB7FF3C);
    const cyan = Color(0xFF20D6C7);

    final scheme = ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: accent,
      surface: surface,
      primary: accent,
      secondary: cyan,
      onSurface: text,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: scheme,
      fontFamily: 'Roboto',
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
          side: const BorderSide(color: Color(0xFF293029)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: accent.withValues(alpha: 0.18),
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
          side: const BorderSide(color: Color(0xFF3A443A)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0D100D),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2E382E)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF2E382E)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
      ),
      extensions: const [
        RunnerColors(
          success: accent,
          info: cyan,
          warning: Color(0xFFFFB020),
          danger: Color(0xFFFF5C39),
          muted: muted,
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
  });

  final Color success;
  final Color info;
  final Color warning;
  final Color danger;
  final Color muted;

  @override
  RunnerColors copyWith({
    Color? success,
    Color? info,
    Color? warning,
    Color? danger,
    Color? muted,
  }) {
    return RunnerColors(
      success: success ?? this.success,
      info: info ?? this.info,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      muted: muted ?? this.muted,
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
    );
  }
}
