# Rainbow Round (Flutter, Android)

A circle of seven notes (C to B), or a xylophone of the same seven bars chosen in the settings, for an autistic child: listen-and-repeat (the focus) and free play. Sister app of Low End (github.com/luigir86/Low-End): same theme, font, piano samples and conventions. Spec: the "Rainbow Round" design doc in the Claude project.

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

- Luigi's three principles: the less the app moves or makes sound, the better; every action deliberate and every answer simple; never two ways to do the same thing.
- One screen: the instrument (circle or xylophone), the dots, the gear. Only the slices/bars are played; the dots never react to touch.
- The middle does one thing: it plays the sequence (to start, and after a mistake). Bronze with an ear when it can be touched, dark and empty otherwise.
- The circle has its colours only when the child can play; otherwise it is grey and only the note that sounds shows its colour. Touches then make no sound and are not queued.
- The child's turn is the colours coming back, never a sound: any sound there is taken for a note.
- A mistake is silent: the wrong note crossed in red in the dots, grey circle, ~1 s lock, then the middle replays the same sequence. A round repeated right gets no reward; the only celebration (every slice lit + star, silent) is at the end of the game, twelve notes by default. Nothing moves by itself. Notes sound only for the sequence and under the child's fingers. No timers, no score.
- The settings open only with the gear held down.
- No "Simon" in names, texts or store keywords (Hasbro trademark), and not its look.

## Conventions

- Neighbouring notes alternate light and dark colours (colour-blind safe; B and C, both dark, are the one exception of an odd circle); text on a note uses `RoundColors.inkOn`.
- Every user-visible text in both `.arb` files; colours from `lib/app/theme.dart`, sizes from `lib/app/style.dart`.
- Game timings live in `GameController`; UI motion uses `Durations.*` and is zero with fewer animations.
- Sound goes through `NotePlayer`; tests use `SilentNotePlayer`.
