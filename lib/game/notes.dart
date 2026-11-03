/// The seven notes of the circle, a C major scale from middle C to the B
/// above it, by their place on the circle (0 is the C, 6 the B).
abstract final class Notes {
  static const count = 7;

  /// MIDI numbers: 60 is middle C.
  static const midi = [60, 62, 64, 65, 67, 69, 71];

  static const solfege = ['Do', 'Re', 'Mi', 'Fa', 'Sol', 'La', 'Si'];
  static const letters = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
}

/// What is written on the slices and in the dots.
enum NoteLabels {
  /// Only the colour.
  none,

  /// Do Re Mi.
  solfege,

  /// C D E.
  letters;

  /// The name of [note] as written on the screen: in capitals, as every
  /// text of the app, for a child who reads only capitals.
  String? shownName(int note) => nameOf(note)?.toUpperCase();

  /// The name of [note] in this naming, or null for [none]: as a screen
  /// reader says it.
  String? nameOf(int note) => switch (this) {
    none => null,
    solfege => Notes.solfege[note],
    letters => Notes.letters[note],
  };
}
