# Rainbow Round

A circle of eight coloured notes, from C to high C (or, in the settings, a xylophone of the same eight notes), to play, listen to and repeat. Made for a child who loves music, and useful to any child. A sister app of [Low End](https://github.com/luigir86/Low-End): the same Flutter, the same bronze on ebony, the same piano, offline, with no account, no ads and no tracking.

**Status: first prototype.**

## What it does now

- **One screen, one instrument.** A circle of eight slices, C to high C, going up clockwise from the top. The colours go round the rainbow without orange (too close to the red) and alternate dark and light all the way round (dark red, yellow, dark green, turquoise, dark blue, lavender, dark magenta, light red for the high C), so two neighbours differ in lightness too, for colour-blind eyes as well; the note names are on them (Do Re Mi or C D E, or colours only). Under it, the row of dots of the sequence; nothing else, apart from the gear.
- **Or a xylophone** (settings → Instrument): eight bars from the low C on the left to the high C on the right, each a little shorter, with the state and the start in a strip above them.
- **Listen and repeat** (level 1, "reading"): touch the middle to start. The circle plays a short sequence by itself: each slice sounds and lights up, and its dot appears under the circle at the same moment. While it plays, touches do nothing. Then the middle of the circle lights up in bronze with a hand: it is the child's turn. There is no sound for it, so that it is never taken for one of the notes. The dots stay visible: the one to touch now is bigger, and each fills as it is played.
  - **Right**: the whole circle lights up at once with a star in the middle, in silence (notes sound only when the circle plays the sequence and under the child's fingers, so it is always clear who is playing); then the same sequence comes back with one more note.
  - **Wrong**: a low, soft note and a small shake of the slice touched; the circle then ignores every touch for one second and plays the sequence again, calmly.
  - After the longest sequence the middle shows "Another one?".
- **Free play**: the circle is a little piano. Every touch plays its note, several fingers make a chord.
- **Settings for the grown-up** behind the gear, which opens only when **held for two seconds** (a ring fills round it): the game, what is written on the slices, the instrument (circle or xylophone), how many notes are on (3 to 8, from the low C up; the others stay dark and silent), the first and the longest sequence.
- English and Italian; screen-reader labels on every slice and on the middle; no shaking when the phone asks for fewer animations.

The sound is the Salamander Grand Piano of Low End (public domain), five notes pitched by a semitone to cover the scale, cut to short WAV files. The timbre is still to be decided.

## Not yet

Levels 2 and 3 of the dots (fading, memory) and replay, melody mode, the colours → notes path, the "echo" variant of free play, feedback intensity, volume and vibration, an icon of its own.

## Web version

The same app runs in a browser, to try it without installing anything: `tool/build_webapp.sh` builds it into `build/webapp`, a folder any static host can serve from any path (no `<base href>`, no service worker). In a browser the sound starts at the first touch, as browsers require, so that very first note comes a moment late.

## Development

```
flutter pub get
flutter gen-l10n          # after editing lib/l10n/*.arb
dart format lib test
flutter analyze
flutter test
flutter test test_screenshots --update-goldens   # PNGs of the screen in test_screenshots/goldens/
```

`lib/game/game_controller.dart` holds the rules and timings with no widgets; `lib/widgets/rainbow_circle.dart` and `lib/widgets/xylophone.dart` draw the two instruments and find the note under each finger (what they share is in `lib/widgets/instrument.dart`); `lib/audio/note_player.dart` plays the piano with flutter_soloud (and a silent twin for tests).

## Licence

MIT. Fonts: Edwin (SIL OFL). Piano: Salamander Grand Piano V3 by Alexander Holm, public domain.
