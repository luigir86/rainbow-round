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

  /// The eight slices, from C to high C: red, orange, yellow, green, azure,
  /// blue-violet, pink and a light red for the high C, a lighter shade of
  /// the low one's colour.
  static const rainbow = [
    Color(0xFFEF6F6C),
    Color(0xFFF4A259),
    Color(0xFFF2D45C),
    Color(0xFF8CCB7E),
    Color(0xFF6EC3E8),
    Color(0xFF9A98EE),
    Color(0xFFE98BC4),
    Color(0xFFF7AFAD),
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
