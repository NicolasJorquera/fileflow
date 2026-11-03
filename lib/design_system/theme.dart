import 'package:flutter/material.dart';

import 'tokens.dart';

/// Gives widgets the full palette (tool tints, ad background…) that has no
/// slot in Material's ColorScheme: `context.palette.muted`.
class PaletteTheme extends ThemeExtension<PaletteTheme> {
  const PaletteTheme(this.palette);

  final AppPalette palette;

  @override
  PaletteTheme copyWith({AppPalette? palette}) => PaletteTheme(palette ?? this.palette);

  @override
  PaletteTheme lerp(PaletteTheme? other, double t) => t < 0.5 || other == null ? this : other;
}

extension PaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<PaletteTheme>()!.palette;
}

/// Builds the light or dark theme from the design tokens. Text uses the
/// platform font so every script renders (UX v1.0, «Idiomas»).
ThemeData buildTheme(Brightness brightness) {
  final p = brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: p.primary,
    onPrimary: p.onPrimary,
    primaryContainer: p.primarySoft,
    onPrimaryContainer: p.primary,
    secondary: p.primary,
    onSecondary: p.onPrimary,
    error: p.danger,
    onError: p.onPrimary,
    errorContainer: p.dangerSoft,
    onErrorContainer: p.danger,
    surface: p.surface,
    onSurface: p.fg,
    onSurfaceVariant: p.muted,
    surfaceContainerHighest: p.surface2,
    outline: p.line,
    outlineVariant: p.line,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, scaffoldBackgroundColor: p.bg);
  return base.copyWith(
    extensions: [PaletteTheme(p)],
    appBarTheme: AppBarTheme(backgroundColor: p.bg, foregroundColor: p.fg, elevation: 0, scrolledUnderElevation: 0),
    dividerTheme: DividerThemeData(color: p.line, space: 1, thickness: 1),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(Touch.primaryButton),
        shape: const StadiumBorder(),
        textStyle: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: p.primarySoft,
        selectedForegroundColor: p.primary,
        side: BorderSide(color: p.line),
      ),
    ),
  );
}
