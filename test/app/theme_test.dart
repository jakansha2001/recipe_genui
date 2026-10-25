import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:recipe_genui/app/theme.dart';

/// WCAG 2 contrast ratio between two opaque colours.
double contrast(Color a, Color b) {
  double luminance(Color c) {
    double channel(double v) => v <= 0.03928
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * channel(c.r) +
        0.7152 * channel(c.g) +
        0.0722 * channel(c.b);
  }

  final (hi, lo) = (luminance(a), luminance(b));
  return (math.max(hi, lo) + 0.05) / (math.min(hi, lo) + 0.05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final (name, c) in [
    ('light', SageColors.light),
    ('dark', SageColors.dark),
  ]) {
    test('$name palette keeps text readable (WCAG AA 4.5:1)', () {
      final pairs = {
        'ink on background': (c.ink, c.background),
        'ink on surface': (c.ink, c.surface),
        'muted on surface': (c.muted, c.surface),
        'muted on background': (c.muted, c.background),
        'on action': (c.onAction, c.action),
        'on action tint': (c.onActionTint, c.actionTint),
        'on accent': (c.onAccent, c.accent),
        'on tint': (c.onTint, c.tint),
        'code': (c.onCode, c.code),
      };
      for (final MapEntry(key: label, value: (fg, bg)) in pairs.entries) {
        expect(
          contrast(fg, bg),
          greaterThanOrEqualTo(4.5),
          reason: '$name: $label',
        );
      }
    });
  }

  test('light and dark themes carry the brand tokens', () {
    for (final brightness in Brightness.values) {
      final theme = buildSageTheme(brightness);
      expect(theme.brightness, brightness);
      expect(theme.extension<SageColors>(), isNotNull);
      expect(theme.colorScheme.primary, theme.extension<SageColors>()!.action);
    }
  });
}
