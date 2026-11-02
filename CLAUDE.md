# Rainbow Round (Flutter, Android)

A circle of eight notes (C to high C), or a xylophone of the same eight bars chosen in the settings, for a child: listen-and-repeat and free play. Sister app of Low End (github.com/luigir86/Low-End): same theme, font, piano samples and conventions. Spec: the "Rainbow Round" design doc in the Claude project.

## Commands

```
flutter pub get
flutter gen-l10n          # after editing lib/l10n/*.arb (generated Dart files are committed)
dart format lib test      # always before committing
flutter analyze
flutter test
flutter test test_screenshots --update-goldens   # look at the screens without a phone
```

## Product rules (keep them true)

- One screen: the instrument (circle or xylophone), the dots, the gear. Only the slices/bars are played; the dots never react to touch.
- While the circle plays (listen, mistake lock, celebration) touches make no sound and are not queued.
- The child's turn is shown by the lit hub and the hand, never by a sound: any sound there is taken for a note.
- A mistake is quiet and boring (low soft note, small shake, ~1 s lock, replay); success is more rewarding (arpeggio + star). No timers, no score.
- The settings open only with the gear held down.
- No "Simon" in names, texts or store keywords (Hasbro trademark), and not its look.

## Conventions

- Neighbouring notes alternate light and dark colours (colour-blind safe); text on a note uses `RoundColors.inkOn`.
- Every user-visible text in both `.arb` files; colours from `lib/app/theme.dart`, sizes from `lib/app/style.dart`.
- Game timings live in `GameController`; UI motion uses `Durations.*` and is zero with fewer animations.
- Sound goes through `NotePlayer`; tests use `SilentNotePlayer`.
