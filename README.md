# Rainbow Round

A circle of seven coloured notes, from C to B (or, in the settings, a xylophone of the same seven notes), to listen to and repeat. Made first of all for an autistic child, and useful to any child. A sister app of [Low End](https://github.com/luigir86/Low-End): the same Flutter, the same bronze on ebony, the same piano, offline, with no account, no ads and no tracking.

**Status: prototype.**

## How it is meant to feel

1. The less the app moves or makes itself heard, the better.
2. Every action is deliberate, and every answer simple.
3. Never two ways to do the same thing.

## What it does now

- **One screen, one instrument.** A circle of seven slices, C to B, going up clockwise from the top. The colours go round the rainbow without orange (too close to the red) and alternate dark and light (dark red, yellow, dark green, turquoise, dark blue, lavender, dark magenta), so two neighbours differ in lightness too, for colour-blind eyes as well; the note names are on them (Do Re Mi or C D E, or colours only). Under it, the row of dots of the sequence; nothing else, apart from the gear.
- **Listen and repeat**, the game:
  - **The middle does one thing: it plays the sequence.** When it can be touched it is bronze with an ear; at every other moment it is dark and empty, and touching it does nothing.
  - **The circle has its colours only when the child can play.** While it plays the sequence (and before the start, and after a mistake) every slice is grey, and only the note that sounds shows its colour, with its dot appearing underneath. Touches make no sound and are not kept. When the sequence ends the colours come back: that is the child's turn, with no sound and no other sign.
  - It starts with **two notes**. Each sequence repeated right turns the circle grey again at once and comes back with one more note, with no reward in between.
  - **A mistake** makes no sound: the wrong note appears crossed in red in its place among the dots and the circle turns grey. After a second the middle lights up with the ear; touching it plays **the same sequence** again.
  - At **eight notes** (the most; 4 or 6 can be set in the settings) the game ends with the one celebration: every slice lit at once and a star in the middle, in silence. Then the middle waits for a new game.
- **Or a xylophone** (settings → Instrument): seven bars from the C on the left to the B on the right, with the middle as a button above them.
- **Free play** (settings → Game): the circle is a little piano.
- **Settings for the grown-up** behind the gear, which opens only when **held for two seconds**: the game, what is written on the slices, the instrument, how many notes are on (3 to 7, from the C up), the first and the longest sequence.
- **Capitals only**, everywhere (note names, settings), for a child who reads only capitals.
- English and Italian; screen-reader labels on every slice and on the middle. Nothing in the game moves by itself.

The sound is the Salamander Grand Piano of Low End (public domain), four notes pitched by a semitone or two to cover the scale, cut to short WAV files.

## Not yet

The songs mode (about ten real tunes on the seven notes, up to twelve notes each), levels 2 and 3 of the dots (fading, memory), the colours → notes path, the "echo" variant of free play, volume, an icon of its own.

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
