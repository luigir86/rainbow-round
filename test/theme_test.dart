import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_round/app/theme.dart';

double contrast(Color a, Color b) {
  final l1 = a.computeLuminance(), l2 = b.computeLuminance();
  final hi = l1 > l2 ? l1 : l2, lo = l1 > l2 ? l2 : l1;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  final colors = RoundTheme.dark.extension<RoundColors>()!;

  test('the note names read on every slice (4.5 : 1)', () {
    for (var i = 0; i < 8; i++) {
      expect(
        contrast(Palette.inkOnLight, colors.notes[i]),
        greaterThanOrEqualTo(4.5),
        reason: 'slice $i',
      );
      expect(
        contrast(Palette.inkOnLight, colors.lit(i)),
        greaterThanOrEqualTo(4.5),
        reason: 'slice $i lit',
      );
    }
  });

  test('every slice stands out from the ground (3 : 1)', () {
    for (var i = 0; i < 8; i++) {
      expect(
        contrast(colors.notes[i], Palette.ebony),
        greaterThanOrEqualTo(3),
        reason: 'slice $i',
      );
      // An outlined dot writes its name in the note's colour on the disc.
      expect(
        contrast(colors.notes[i], colors.disc),
        greaterThanOrEqualTo(4.5),
        reason: 'dot $i',
      );
    }
  });

  test('the eight colours are told apart from their neighbours', () {
    for (var i = 1; i < 8; i++) {
      final a = HSVColor.fromColor(colors.notes[i - 1]);
      final b = HSVColor.fromColor(colors.notes[i]);
      final hue = (a.hue - b.hue).abs() % 360;
      expect(hue > 15 || (a.value - b.value).abs() > 0.1, isTrue, reason: '$i');
    }
  });
}
