import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../app/settings.dart';
import '../audio/note_player.dart';

/// Where the game is. Only in [yourTurn] (and in free play) can the
/// circle be played, and only then does it have its colours: in every
/// other phase it is grey and touches do nothing.
enum Phase {
  /// Free play: every touch plays its note.
  free,

  /// Waiting for the middle to be touched, which plays the sequence.
  ready,

  /// The circle plays the sequence; touches do nothing.
  listen,

  /// The child repeats the sequence.
  yourTurn,

  /// A wrong note, crossed out in the dots: for a moment nothing answers.
  oops,

  /// After a mistake, waiting for the middle to be touched, which plays
  /// the same sequence again.
  again,

  /// The longest sequence was repeated: the circle celebrates, once, at
  /// the end of the game.
  success,
}

/// The rules of the circle, with no widgets: what is lit, what sounds and
/// what comes next.
class GameController extends ChangeNotifier {
  GameController({
    required this.player,
    required this.settings,
    math.Random? random,
  }) : _random = random ?? math.Random() {
    settings.addListener(_settingsChanged);
    _mode = settings.mode;
    _instrument = settings.instrument;
    _active = _activeFor(settings);
    _phase = _mode == GameMode.free ? Phase.free : Phase.ready;
  }

  final NotePlayer player;
  final AppSettings settings;
  final math.Random _random;

  // The pace of the game. They follow the music, not Material's motion.

  /// Silence before the sequence starts.
  static const leadIn = Duration(milliseconds: 700);

  /// From one note of the sequence to the next.
  static const noteStep = Duration(milliseconds: 750);

  /// How long a slice of the sequence stays lit.
  static const noteLit = Duration(milliseconds: 480);

  /// From the last note of the sequence to the child's turn, when the
  /// colours come back.
  static const handOver = Duration(milliseconds: 550);

  /// A touched slice stays lit at least this long, even for a quick tap.
  static const touchLit = Duration(milliseconds: 220);

  /// After a mistake, the middle does not answer for this long, so that a
  /// hand still touching does not start the sequence by chance.
  static const lockout = Duration(milliseconds: 1000);

  /// From the last right note to the next, longer sequence: the circle
  /// turns grey at once and stays silent for this long.
  static const betweenRounds = Duration(milliseconds: 1200);

  /// How long the star and the lit circle stay at the end of the game.
  static const successHold = Duration(milliseconds: 3000);

  late GameMode _mode;
  late Instrument _instrument;
  late int _active;
  late Phase _phase;
  final _sequence = <int>[];
  int _shown = 0;
  int _done = 0;
  final _played = <int>{};
  final _held = <int, int>{};
  final _flashing = <int, int>{};
  int? _wrong;
  final _timers = <Timer>[];

  Phase get phase => _phase;
  GameMode get mode => _mode;

  /// The shape of the instrument.
  Instrument get instrument => _instrument;

  /// How many notes the instrument has.
  int get noteCount => _instrument.notes;

  /// The notes that can be played, from the C up.
  int get activeCount => _active;
  bool isActive(int note) => note < _active;

  /// The circle can be played now: it has its colours.
  bool get playable => _phase == Phase.yourTurn || _phase == Phase.free;

  /// The middle answers now, and plays the sequence.
  bool get middleStarts => _phase == Phase.ready || _phase == Phase.again;

  /// The sequence of this round, by slice.
  List<int> get sequence => List.unmodifiable(_sequence);

  /// How many notes of the sequence have been heard so far in this
  /// listening: their dots are shown.
  int get shown => _shown;

  /// How many notes the child has repeated right so far. After a mistake,
  /// the wrong note was the one in this place.
  int get done => _done;

  /// The slices lit now: the one the circle plays, the ones touched.
  Set<int> get lit => {..._played, ..._held.keys, ..._flashing.keys};

  /// The slice touched by mistake, crossed out in the dots until the
  /// sequence is heard again.
  int? get wrong => _wrong;

  void _after(Duration delay, void Function() action) {
    late final Timer timer;
    timer = Timer(delay, () {
      _timers.remove(timer);
      action();
    });
    _timers.add(timer);
  }

  void _cancelTimers() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
  }

  static int _activeFor(AppSettings settings) =>
      math.min(settings.activeCount, settings.instrument.notes);

  void _settingsChanged() {
    if (settings.mode == _mode &&
        settings.instrument == _instrument &&
        _activeFor(settings) == _active) {
      return;
    }
    _mode = settings.mode;
    _instrument = settings.instrument;
    _active = _activeFor(settings);
    _reset();
  }

  /// Back to the start of the mode: nothing lit, nothing playing.
  void _reset() {
    _cancelTimers();
    _sequence.clear();
    _shown = 0;
    _done = 0;
    _played.clear();
    _held.clear();
    _flashing.clear();
    _wrong = null;
    _phase = _mode == GameMode.free ? Phase.free : Phase.ready;
    notifyListeners();
  }

  /// The middle of the circle was touched. It does one thing only: it
  /// plays the sequence, a new one at the start of a game, the same one
  /// after a mistake. At any other moment it does nothing.
  void touchMiddle() {
    switch (_phase) {
      case Phase.ready:
        _sequence.clear();
        for (var i = 0; i < settings.startLength; i++) {
          _sequence.add(_nextNote());
        }
        _listen(leadIn);
      case Phase.again:
        _listen(leadIn);
      case Phase.free ||
          Phase.listen ||
          Phase.yourTurn ||
          Phase.oops ||
          Phase.success:
        return;
    }
  }

  /// A random note of those lit, not the same as the last one, so that two
  /// dots in a row never look like one.
  int _nextNote() {
    if (_active < 2) return 0;
    final last = _sequence.isEmpty ? null : _sequence.last;
    int note;
    do {
      note = _random.nextInt(_active);
    } while (note == last);
    return note;
  }

  void _listen(Duration lead) {
    _cancelTimers();
    _phase = Phase.listen;
    _shown = 0;
    _done = 0;
    _held.clear();
    _flashing.clear();
    _wrong = null;
    notifyListeners();
    for (var i = 0; i < _sequence.length; i++) {
      final at = lead + noteStep * i;
      final note = _sequence[i];
      _after(at, () {
        _played
          ..clear()
          ..add(note);
        _shown = i + 1;
        player.note(note);
        notifyListeners();
      });
      _after(at + noteLit, () {
        _played.remove(note);
        notifyListeners();
      });
    }
    final end = lead + noteStep * (_sequence.length - 1) + noteLit;
    _after(end + handOver, () {
      // No sound and no sign of its own: the colours coming back are the
      // child's turn.
      _phase = Phase.yourTurn;
      notifyListeners();
    });
  }

  /// A finger came down on slice [note].
  void press(int note) {
    if (!isActive(note)) return;
    switch (_phase) {
      case Phase.free:
        _light(note);
        player.note(note);
      case Phase.yourTurn:
        _answer(note);
      case Phase.ready ||
          Phase.listen ||
          Phase.oops ||
          Phase.again ||
          Phase.success:
        // Not the child's turn: no sound, no light, nothing kept for later.
        return;
    }
  }

  /// A finger left slice [note].
  void release(int note) {
    final count = _held[note];
    if (count == null) return;
    if (count > 1) {
      _held[note] = count - 1;
    } else {
      _held.remove(note);
    }
    notifyListeners();
  }

  /// Lights [note] while it is held, and for a moment at least.
  void _light(int note) {
    _held[note] = (_held[note] ?? 0) + 1;
    final flash = (_flashing[note] ?? 0) + 1;
    _flashing[note] = flash;
    notifyListeners();
    _after(touchLit, () {
      if (_flashing[note] != flash) return;
      _flashing.remove(note);
      notifyListeners();
    });
  }

  void _answer(int note) {
    if (note != _sequence[_done]) {
      _mistake(note);
      return;
    }
    _light(note);
    player.note(note);
    _done++;
    if (_done < _sequence.length) {
      notifyListeners();
      return;
    }
    // Right to the end: the circle is grey again at once, with no reward
    // in between; the celebration is kept for the end of the game.
    if (_sequence.length >= settings.longest) {
      _success();
    } else {
      _sequence.add(_nextNote());
      _listen(betweenRounds);
      // The note just touched still shows under the finger.
      _light(note);
    }
  }

  void _mistake(int note) {
    // Silent: the wrong note makes no sound, the dot is crossed out and
    // the circle turns grey.
    _cancelTimers();
    _phase = Phase.oops;
    _held.clear();
    _flashing.clear();
    _wrong = note;
    notifyListeners();
    _after(lockout, () {
      _phase = Phase.again;
      notifyListeners();
    });
  }

  void _success() {
    _cancelTimers();
    _phase = Phase.success;
    _held.clear();
    _flashing.clear();
    // Silent: every note lit at once and the star in the middle. Notes
    // sound only for the sequence and under the child's fingers.
    _played
      ..clear()
      ..addAll([for (var i = 0; i < _active; i++) i]);
    notifyListeners();
    _after(successHold, () {
      _played.clear();
      _sequence.clear();
      _shown = 0;
      _done = 0;
      _phase = Phase.ready;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    settings.removeListener(_settingsChanged);
    _cancelTimers();
    super.dispose();
  }
}
