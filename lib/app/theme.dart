import 'package:flutter/material.dart';

import 'style.dart';

/// Rainbow Round's look, in one place: the bronze on ebony of Low End, and
/// the eight colours of the circle.
///
/// Always dark, flat, one accent (the bronze) for everything that is not a
/// note. The notes have the colours of a children's xylophone or of
/// Boomwhackers, in soft tints that keep dark text readable on them.
abstract final class Palette {
  /// The accent: the honey bronze of Low End.
  static const bronze = Color(0xFFD4A373);

  // The ground, from the darkest up.
  static const ebony = Color(0xFF141312);
  static const ebonyShade1 = Color(0xFF1C1B19);
  static const ebonyShade2 = Color(0xFF262422);
  static const ebonyShade3 = Color(0xFF312F2C);
  static const walnutDeep = Color(0xFF2B1D16);

  // Text.
  static const inkOnLight = Color(0xFF1E1C1A);
  static const inkOnDark = Color(0xFFEFEDEA);
  static const inkOnDarkMuted = Color(0xFFC9C5BF);

  /// The notes from C to high C, round the rainbow with no orange (too
  /// close to the red of the C): red, yellow, green, turquoise, blue,
  /// lavender, magenta, and red again for the high C, light where the
  /// low C is dark, the same note an octave up. Dark and light take
  /// turns, all the way round the circle, so that two neighbours differ
  /// in lightness as well as in hue: that is what tells them apart for a
  /// colour-blind child.
  static const rainbow = [
    Color(0xFFC62828), // C, dark red
    Color(0xFFFFD54F), // D, light yellow
    Color(0xFF237A35), // E, dark green
    Color(0xFF6FD3E0), // F, light turquoise
    Color(0xFF2563C8), // G, dark blue
    Color(0xFFC3B1FF), // A, light lavender
    Color(0xFFA8327F), // B, dark magenta
    Color(0xFFFF8A80), // high C, light red
  ];
}

/// Colours the Material scheme has no name for.
@immutable
class RoundColors extends ThemeExtension<RoundColors> {
  const RoundColors({
    required this.disc,
    required this.sliceOff,
    required this.notes,
  });

  /// The disc under the slices, and the hub in the middle.
  final Color disc;

  /// A slice that is switched off in the settings.
  final Color sliceOff;

  /// The colour of each of the eight notes, from C to high C.
  final List<Color> notes;

  static RoundColors of(BuildContext context) =>
      Theme.of(context).extension<RoundColors>()!;

  /// [note] lit: lighter, as if a light came on under it.
  Color lit(int note) => Color.lerp(notes[note], Colors.white, 0.5)!;

  /// The ink that reads best on [background]: the name of a note on its
  /// colour, light on the dark notes and dark on the light ones.
  static Color inkOn(Color background) => _readableOn(background);

  /// [note] while another one sounds: it steps back into the disc, so the
  /// one that sounds stands out.
  Color receded(int note) => Color.lerp(notes[note], disc, 0.55)!;

  @override
  RoundColors copyWith({Color? disc, Color? sliceOff, List<Color>? notes}) =>
      RoundColors(
        disc: disc ?? this.disc,
        sliceOff: sliceOff ?? this.sliceOff,
        notes: notes ?? this.notes,
      );

  @override
  RoundColors lerp(RoundColors? other, double t) {
    if (other == null) return this;
    return RoundColors(
      disc: Color.lerp(disc, other.disc, t)!,
      sliceOff: Color.lerp(sliceOff, other.sliceOff, t)!,
      notes: [
        for (var i = 0; i < notes.length; i++)
          Color.lerp(notes[i], other.notes[i], t)!,
      ],
    );
  }
}

abstract final class RoundTheme {
  static const radius = RoundShape.radius;

  /// The bronze mixed into the ebony: the more of it, the stronger.
  static Color tint(double amount) =>
      Color.lerp(Palette.ebony, Palette.bronze, amount)!;

  /// The one theme: dark, bronze on ebony, as Low End.
  static final dark = () {
    final container = tint(0.2);
    final secondary = tint(0.58);
    final disc = tint(0.1);
    return _build(
      ColorScheme(
        brightness: Brightness.dark,
        primary: Palette.bronze,
        onPrimary: Palette.walnutDeep,
        primaryContainer: container,
        onPrimaryContainer: Palette.inkOnDark,
        secondary: secondary,
        onSecondary: Palette.inkOnLight,
        secondaryContainer: container,
        onSecondaryContainer: Palette.inkOnDark,
        error: const Color(0xFFFF5F56),
        onError: Palette.walnutDeep,
        surface: Palette.ebony,
        onSurface: Palette.inkOnDark,
        onSurfaceVariant: Color.lerp(
          Palette.inkOnDarkMuted,
          Palette.bronze,
          0.25,
        )!,
        surfaceContainerLowest: Colors.black,
        surfaceContainerLow: Palette.ebonyShade1,
        surfaceContainer: Palette.ebonyShade1,
        surfaceContainerHigh: Palette.ebonyShade2,
        surfaceContainerHighest: Palette.ebonyShade3,
        outline: tint(0.75),
        outlineVariant: tint(0.26),
      ),
      RoundColors(disc: disc, sliceOff: tint(0.2), notes: Palette.rainbow),
    );
  }();

  static ThemeData _build(ColorScheme scheme, RoundColors colors) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    return ThemeData(
      // Edwin (SIL OFL), the font of Low End, bundled in assets/fonts.
      fontFamily: 'Edwin',
      colorScheme: scheme,
      textTheme: RoundType.textTheme,
      scaffoldBackgroundColor: scheme.surface,
      extensions: [colors],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Edwin',
          fontSize: RoundType.title,
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(shape: shape),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          minimumSize: const Size(0, 48),
          selectedBackgroundColor: scheme.primaryContainer,
          selectedForegroundColor: scheme.onPrimaryContainer,
          foregroundColor: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// The dark or the light ink, whichever reads better on [background].
Color _readableOn(Color background) {
  double ratio(Color a, Color b) {
    final l1 = a.computeLuminance(), l2 = b.computeLuminance();
    final hi = l1 > l2 ? l1 : l2, lo = l1 > l2 ? l2 : l1;
    return (hi + 0.05) / (lo + 0.05);
  }

  return ratio(background, Palette.inkOnLight) >=
          ratio(background, Palette.inkOnDark)
      ? Palette.inkOnLight
      : Palette.inkOnDark;
}
