import 'package:flutter/material.dart';

/// Colours beyond the Material scheme: the page ground, macro colours and
/// the calories-burned accent. Read with `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.ground,
    required this.card,
    required this.ink,
    required this.muted,
    required this.line,
    required this.accent,
    required this.accentSoft,
    required this.protein,
    required this.proteinSoft,
    required this.carbs,
    required this.carbsSoft,
    required this.fat,
    required this.fatSoft,
    required this.burn,
    required this.burnSoft,
    required this.hero,
    required this.onHero,
    required this.onHeroMuted,
    required this.heroAccent,
  });

  final Color ground;
  final Color card;
  final Color ink;
  final Color muted;
  final Color line;
  final Color accent;
  final Color accentSoft;
  final Color protein;
  final Color proteinSoft;
  final Color carbs;
  final Color carbsSoft;
  final Color fat;
  final Color fatSoft;
  final Color burn;
  final Color burnSoft;

  /// The dark summary card on the log screen.
  final Color hero;
  final Color onHero;
  final Color onHeroMuted;
  final Color heroAccent;

  static const light = AppPalette(
    ground: Color(0xFFF3F5F1),
    card: Color(0xFFFFFFFF),
    ink: Color(0xFF13221B),
    muted: Color(0xFF5A6B62),
    line: Color(0xFFE3E8E2),
    accent: Color(0xFF1E7A4C),
    accentSoft: Color(0xFFE3F1E8),
    protein: Color(0xFF2D5BD3),
    proteinSoft: Color(0xFFE8EDF8),
    carbs: Color(0xFFE3922B),
    carbsSoft: Color(0xFFFBEFDD),
    fat: Color(0xFF9A5BC9),
    fatSoft: Color(0xFFF2E9F8),
    burn: Color(0xFFC2571E),
    burnSoft: Color(0xFFFBE6DC),
    hero: Color(0xFF13221B),
    onHero: Color(0xFFFFFFFF),
    onHeroMuted: Color(0xFFB8C7BE),
    heroAccent: Color(0xFF8FE0B4),
  );

  static const dark = AppPalette(
    ground: Color(0xFF0E1813),
    card: Color(0xFF17241D),
    ink: Color(0xFFE6EEE8),
    muted: Color(0xFF9DB0A5),
    line: Color(0xFF26362D),
    accent: Color(0xFF6FD49D),
    accentSoft: Color(0xFF1E3A2A),
    protein: Color(0xFF7FA2F5),
    proteinSoft: Color(0xFF1F2A44),
    carbs: Color(0xFFF0AE57),
    carbsSoft: Color(0xFF3A2C17),
    fat: Color(0xFFC79AEA),
    fatSoft: Color(0xFF33243F),
    burn: Color(0xFFF08A55),
    burnSoft: Color(0xFF3D2519),
    hero: Color(0xFF1F3328),
    onHero: Color(0xFFFFFFFF),
    onHeroMuted: Color(0xFFB8C7BE),
    heroAccent: Color(0xFF8FE0B4),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) =>
      t < 0.5 || other is! AppPalette ? this : other;
}

extension PaletteContext on BuildContext {
  /// Falls back to the default palette under a theme without one.
  AppPalette get palette {
    final theme = Theme.of(this);
    return theme.extension<AppPalette>() ??
        (theme.brightness == Brightness.dark
            ? AppPalette.dark
            : AppPalette.light);
  }
}

ThemeData buildTheme(Brightness brightness) {
  final p = brightness == Brightness.light ? AppPalette.light : AppPalette.dark;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppPalette.light.accent,
        brightness: brightness,
      ).copyWith(
        primary: p.accent,
        onPrimary: brightness == Brightness.light ? Colors.white : p.ground,
        surface: p.card,
        onSurface: p.ink,
        onSurfaceVariant: p.muted,
        outlineVariant: p.line,
      );
  final base = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    brightness: brightness,
  );
  final text = base.textTheme.apply(bodyColor: p.ink, displayColor: p.ink);
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
  return base.copyWith(
    scaffoldBackgroundColor: p.ground,
    extensions: [p],
    textTheme: text.copyWith(
      headlineMedium: text.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      headlineSmall: text.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.ground,
      surfaceTintColor: Colors.transparent,
      foregroundColor: p.ink,
      centerTitle: false,
      titleTextStyle: text.titleLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardThemeData(
      color: p.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    dividerTheme: DividerThemeData(color: p.line, space: 1, thickness: 1),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: shape,
        textStyle: text.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: shape,
        side: BorderSide(color: p.line, width: 1.5),
        foregroundColor: p.ink,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: p.accent,
        selectedForegroundColor: scheme.onPrimary,
        side: BorderSide(color: p.line),
        textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: p.line, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: p.line, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: p.accent, width: 2),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: p.accentSoft,
      side: BorderSide.none,
      shape: shape,
      labelStyle: text.labelLarge?.copyWith(
        color: p.ink,
        fontWeight: FontWeight.w600,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.card,
      indicatorColor: p.accentSoft,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStatePropertyAll(
        text.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: p.ink),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: p.card,
      indicatorColor: p.accentSoft,
      selectedIconTheme: IconThemeData(color: p.ink),
      unselectedIconTheme: IconThemeData(color: p.muted),
      selectedLabelTextStyle: text.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: p.ink,
      ),
      unselectedLabelTextStyle: text.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: p.muted,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: p.accent,
      foregroundColor: scheme.onPrimary,
      extendedTextStyle: text.labelLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.ground,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    switchTheme: SwitchThemeData(
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
  );
}
