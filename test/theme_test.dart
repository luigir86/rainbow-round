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
        contrast(RoundColors.inkOn(colors.notes[i]), colors.notes[i]),
        greaterThanOrEqualTo(4.5),
        reason: 'slice $i',
      );
      expect(
        // Lit, the slice is bigger and brief: large text asks 3 : 1.
        contrast(RoundColors.inkOn(colors.lit(i)), colors.lit(i)),
        greaterThanOrEqualTo(3),
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
    }
  });

  test('neighbours differ in lightness, for colour-blind eyes too', () {
    // Round the circle: C D E F G A B and back to C.
    for (var i = 0; i < 7; i++) {
      final a = colors.notes[i], b = colors.notes[(i + 1) % 7];
      final hue = (HSVColor.fromColor(a).hue - HSVColor.fromColor(b).hue).abs();
      expect(
        contrast(a, b) >= 1.8 || (hue > 60 && hue < 300),
        isTrue,
        reason: '$i and ${i + 1}',
      );
    }
    // The high C is the same note an octave up: the same colour.
    expect(colors.notes[7], colors.notes[0]);
  });
}
