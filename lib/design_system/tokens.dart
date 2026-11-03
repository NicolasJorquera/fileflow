import 'package:flutter/painting.dart';

/// Color tokens from the approved design system (gate C). Every color in the
/// app comes from one of these two palettes; no widget uses a literal color.
class AppPalette {
  const AppPalette({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.fg,
    required this.muted,
    required this.line,
    required this.primary,
    required this.onPrimary,
    required this.primarySoft,
    required this.success,
    required this.successSoft,
    required this.warn,
    required this.warnSoft,
    required this.danger,
    required this.dangerSoft,
    required this.ad,
    required this.tools,
  });

  final Color bg, surface, surface2, fg, muted, line;
  final Color primary, onPrimary, primarySoft;
  final Color success, successSoft, warn, warnSoft, danger, dangerSoft;

  /// Background of the ad container.
  final Color ad;

  /// Icon colors per tool: (background, foreground).
  final Map<ToolTint, (Color, Color)> tools;

  static const light = AppPalette(
    bg: Color(0xFFF6F7F9),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFEDF0F5),
    fg: Color(0xFF151A24),
    muted: Color(0xFF566072),
    line: Color(0xFFDCE1E9),
    primary: Color(0xFF2349C9),
    onPrimary: Color(0xFFFFFFFF),
    primarySoft: Color(0xFFE5EBFB),
    success: Color(0xFF1C7447),
    successSoft: Color(0xFFE1F2E8),
    warn: Color(0xFF7D5300),
    warnSoft: Color(0xFFFAEFD8),
    danger: Color(0xFFB0261E),
    dangerSoft: Color(0xFFFBE7E5),
    ad: Color(0xFFE9ECF1),
    tools: {
      ToolTint.scan: (Color(0xFFE5EBFB), Color(0xFF2349C9)),
      ToolTint.reduce: (Color(0xFFFCEBDD), Color(0xFFA2470D)),
      ToolTint.merge: (Color(0xFFEDE6FB), Color(0xFF5B33B6)),
      ToolTint.photos: (Color(0xFFDDF2EF), Color(0xFF0F6B62)),
      ToolTint.organize: (Color(0xFFE3F1DF), Color(0xFF2F6B1F)),
      ToolTint.toImage: (Color(0xFFFBE4EC), Color(0xFFA3204F)),
    },
  );

  static const dark = AppPalette(
    bg: Color(0xFF0E1218),
    surface: Color(0xFF161B23),
    surface2: Color(0xFF202733),
    fg: Color(0xFFE7EBF2),
    muted: Color(0xFF9BA5B6),
    line: Color(0xFF2B3341),
    primary: Color(0xFF93ABFF),
    onPrimary: Color(0xFF0A1433),
    primarySoft: Color(0xFF1C2850),
    success: Color(0xFF72D3A1),
    successSoft: Color(0xFF12301F),
    warn: Color(0xFFF0C26A),
    warnSoft: Color(0xFF382A0E),
    danger: Color(0xFFFF8B82),
    dangerSoft: Color(0xFF3B1A19),
    ad: Color(0xFF1B212B),
    tools: {
      ToolTint.scan: (Color(0xFF1C2850), Color(0xFF93ABFF)),
      ToolTint.reduce: (Color(0xFF3A2414), Color(0xFFFFB27A)),
      ToolTint.merge: (Color(0xFF2A2147), Color(0xFFC6B2FF)),
      ToolTint.photos: (Color(0xFF11302C), Color(0xFF7BD8CB)),
      ToolTint.organize: (Color(0xFF1A2E15), Color(0xFF9FD98A)),
      ToolTint.toImage: (Color(0xFF3A1622), Color(0xFFFF9BBE)),
    },
  );
}

enum ToolTint { scan, reduce, merge, photos, organize, toImage }

/// Spacing scale (dp) and shape radii from the design system board.
abstract final class Space {
  static const xs = 4.0, s = 8.0, m = 12.0, l = 16.0, xl = 24.0, xxl = 32.0;
}

abstract final class Radii {
  static const small = 12.0, card = 16.0, hero = 20.0, sheet = 28.0;
}

/// Minimum touch target and primary button height (dp).
abstract final class Touch {
  static const minTarget = 48.0, primaryButton = 52.0;
}
