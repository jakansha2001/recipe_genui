import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Product identity.
abstract final class Brand {
  static const String name = 'Sage';
  static const String tagline = 'Cook with what you have';
}

/// "Masala Chai": deep teal for actions, terracotta for highlights, on a chai
/// beige ground. Every text/background pair passes WCAG AA (4.5:1) in both
/// modes.
///
/// These tokens are the single source of truth: [buildSageTheme] maps them
/// onto Material's theme, which is also what genui's built-in components
/// (chips, text fields, buttons, cards) read — so the components the model
/// picks are drawn in this design system.
@immutable
final class SageColors extends ThemeExtension<SageColors> {
  const SageColors({
    required this.background,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.action,
    required this.onAction,
    required this.actionTint,
    required this.onActionTint,
    required this.accent,
    required this.onAccent,
    required this.tint,
    required this.onTint,
    required this.border,
    required this.code,
    required this.onCode,
  });

  static const SageColors light = SageColors(
    background: Color(0xFFF5ECDF), // chai
    surface: Color(0xFFFFFCF7),
    ink: Color(0xFF2C211A),
    muted: Color(0xFF6A5A4D),
    action: Color(0xFF1F5E5B), // deep teal
    onAction: Color(0xFFFFFFFF),
    actionTint: Color(0xFFD5E8E5),
    onActionTint: Color(0xFF0F3B39),
    accent: Color(0xFFB4532F), // terracotta
    onAccent: Color(0xFFFFFFFF),
    tint: Color(0xFFF3DCCB),
    onTint: Color(0xFF7A3418),
    border: Color(0xFFE6D6C2),
    code: Color(0xFF1F1915),
    onCode: Color(0xFFF3E9DC),
  );

  static const SageColors dark = SageColors(
    background: Color(0xFF1B1613),
    surface: Color(0xFF26201B),
    ink: Color(0xFFF3E9DC),
    muted: Color(0xFFC2B2A1),
    action: Color(0xFF7CC4BE),
    onAction: Color(0xFF0C2A28),
    actionTint: Color(0xFF1E3C3A),
    onActionTint: Color(0xFFBFE6E2),
    accent: Color(0xFFE3906C),
    onAccent: Color(0xFF2A1108),
    tint: Color(0xFF4A2D20),
    onTint: Color(0xFFF7D3BF),
    border: Color(0xFF3A2F27),
    code: Color(0xFF120E0C),
    onCode: Color(0xFFE9DECF),
  );

  final Color background;
  final Color surface;
  final Color ink;
  final Color muted;

  /// Primary actions: send, submit, view recipe.
  final Color action;
  final Color onAction;
  final Color actionTint;
  final Color onActionTint;

  /// Highlights: servings stepper, adaptation notes.
  final Color accent;
  final Color onAccent;

  /// Selected chips and info pills.
  final Color tint;
  final Color onTint;
  final Color border;

  /// The protocol-peek JSON panel.
  final Color code;
  final Color onCode;

  @override
  SageColors copyWith() => this;

  @override
  SageColors lerp(SageColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return SageColors(
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      ink: mix(ink, other.ink),
      muted: mix(muted, other.muted),
      action: mix(action, other.action),
      onAction: mix(onAction, other.onAction),
      actionTint: mix(actionTint, other.actionTint),
      onActionTint: mix(onActionTint, other.onActionTint),
      accent: mix(accent, other.accent),
      onAccent: mix(onAccent, other.onAccent),
      tint: mix(tint, other.tint),
      onTint: mix(onTint, other.onTint),
      border: mix(border, other.border),
      code: mix(code, other.code),
      onCode: mix(onCode, other.onCode),
    );
  }
}

extension SageTheme on BuildContext {
  /// The brand tokens for widgets the Material theme doesn't cover.
  SageColors get sage => Theme.of(this).extension<SageColors>()!;
}

/// Corner radii, so components feel like one family.
abstract final class SageRadii {
  static const double control = 14;
  static const double card = 20;
  static const BorderRadius controlRadius = BorderRadius.all(
    Radius.circular(control),
  );
  static const BorderRadius cardRadius = BorderRadius.all(
    Radius.circular(card),
  );
}

ThemeData buildSageTheme(Brightness brightness) {
  final c = brightness == Brightness.light ? SageColors.light : SageColors.dark;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.action,
    onPrimary: c.onAction,
    primaryContainer: c.actionTint,
    onPrimaryContainer: c.onActionTint,
    secondary: c.accent,
    onSecondary: c.onAccent,
    secondaryContainer: c.tint,
    onSecondaryContainer: c.onTint,
    tertiary: c.accent,
    onTertiary: c.onAccent,
    tertiaryContainer: c.tint,
    onTertiaryContainer: c.onTint,
    error: brightness == Brightness.light
        ? const Color(0xFFB3261E)
        : const Color(0xFFF2B8B5),
    onError: brightness == Brightness.light
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF601410),
    surface: c.surface,
    onSurface: c.ink,
    onSurfaceVariant: c.muted,
    surfaceContainerLowest: c.surface,
    surfaceContainerLow: c.surface,
    surfaceContainer: c.background,
    surfaceContainerHigh: c.tint,
    surfaceContainerHighest: c.tint,
    outline: c.border,
    outlineVariant: c.border,
  );

  final base = ThemeData(brightness: brightness, colorScheme: scheme);
  final text = GoogleFonts.manropeTextTheme(
    base.textTheme,
  ).apply(bodyColor: c.ink, displayColor: c.ink);
  TextStyle? heavy(TextStyle? s) =>
      s?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3);

  return base.copyWith(
    scaffoldBackgroundColor: c.background,
    extensions: [c],
    textTheme: text.copyWith(
      headlineSmall: heavy(text.headlineSmall),
      titleLarge: heavy(text.titleLarge),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.background,
      foregroundColor: c.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: c.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: SageRadii.cardRadius,
        side: BorderSide(color: c.border),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: c.surface,
      selectedColor: c.tint,
      checkmarkColor: c.onTint,
      side: BorderSide(color: c.border),
      shape: const StadiumBorder(),
      labelStyle: text.labelLarge?.copyWith(color: c.ink),
      secondaryLabelStyle: text.labelLarge?.copyWith(
        color: c.onTint,
        fontWeight: FontWeight.w700,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      labelStyle: TextStyle(color: c.muted),
      floatingLabelStyle: TextStyle(color: c.action),
      border: OutlineInputBorder(
        borderRadius: SageRadii.controlRadius,
        borderSide: BorderSide(color: c.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: SageRadii.controlRadius,
        borderSide: BorderSide(color: c.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: SageRadii.controlRadius,
        borderSide: BorderSide(color: c.action, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: const RoundedRectangleBorder(
          borderRadius: SageRadii.controlRadius,
        ),
        textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: const RoundedRectangleBorder(
          borderRadius: SageRadii.controlRadius,
        ),
        textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: c.action),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: c.action,
      thumbColor: c.action,
      inactiveTrackColor: c.border,
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    dividerTheme: DividerThemeData(color: c.border, space: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: c.action),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.ink,
      contentTextStyle: text.bodyMedium?.copyWith(color: c.background),
      shape: const RoundedRectangleBorder(
        borderRadius: SageRadii.controlRadius,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
    ),
  );
}
