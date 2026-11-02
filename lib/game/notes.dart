/// The eight notes of the circle, a C major scale from middle C to the C
/// above it, by their place on the circle (0 is the low C, 7 the high C).
abstract final class Notes {
  static const count = 8;

  /// MIDI numbers: 60 is middle C.
  static const midi = [60, 62, 64, 65, 67, 69, 71, 72];

  static const solfege = ['Do', 'Re', 'Mi', 'Fa', 'Sol', 'La', 'Si', 'Do'];
  static const letters = ['C', 'D', 'E', 'F', 'G', 'A', 'B', 'C'];
}

/// What is written on the slices and in the dots.
enum NoteLabels {
  /// Only the colour.
  none,

  /// Do Re Mi.
  solfege,

  /// C D E.
  letters;

  /// The name of [note] in this naming, or null for [none].
  String? nameOf(int note) => switch (this) {
    none => null,
    solfege => Notes.solfege[note],
    letters => Notes.letters[note],
  };
}
