import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../app/settings.dart';
import '../audio/note_player.dart';
import 'notes.dart';

/// Where the game is. Each phase looks and sounds different, and the
/// middle of the circle says which it is.
enum Phase {
  /// Free play: every touch plays its note.
  free,

  /// Waiting for the grown-up (or the child) to touch the middle.
  ready,

  /// The circle plays the sequence; touches do nothing.
  listen,

  /// The child repeats the sequence.
  yourTurn,

  /// A wrong note: for a moment nothing answers, then the sequence is
  /// heard again.
  oops,

  /// The sequence was right: the circle celebrates.
  success,

  /// The longest sequence was repeated: the middle asks for another game.
  finished,
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

  /// From the last note of the sequence to the signal of the child's turn.
  static const handOver = Duration(milliseconds: 550);

  /// How long the middle stays lit with the signal of the child's turn.
  static const cueLit = Duration(milliseconds: 1000);

  /// A touched slice stays lit at least this long, even for a quick tap.
  static const touchLit = Duration(milliseconds: 220);

  /// After a mistake, nothing answers for this long.
  static const lockout = Duration(milliseconds: 1000);

  /// From the last right note to the celebration.
  static const beforeSuccess = Duration(milliseconds: 400);

  /// From one note of the celebration's arpeggio to the next.
  static const arpeggioStep = Duration(milliseconds: 110);

  /// How long the star stays before the next sequence.
  static const successHold = Duration(milliseconds: 1500);

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
  int _wrongCount = 0;
  bool _cue = false;
  final _timers = <Timer>[];

  Phase get phase => _phase;
  GameMode get mode => _mode;

  /// The shape of the instrument: it sets how many notes there are.
  Instrument get instrument => _instrument;

  /// How many notes the instrument has.
  int get noteCount => _instrument.notes;

  /// The notes that can be played, from the low C up.
  int get activeCount => _active;
  bool isActive(int note) => note < _active;

  /// The sequence of this round, by slice.
  List<int> get sequence => List.unmodifiable(_sequence);

  /// How many notes of the sequence have been heard so far in this
  /// listening: their dots are shown.
  int get shown => _shown;

  /// How many notes the child has repeated right so far.
  int get done => _done;

  /// The slices lit now: the one the circle plays, the ones touched.
  Set<int> get lit => {..._played, ..._held.keys, ..._flashing.keys};

  /// The slice touched by mistake, while it shakes.
  int? get wrong => _wrong;

  /// Grows by one at every mistake, so the screen knows to shake again.
  int get wrongCount => _wrongCount;

  /// The border is lit with the signal of the child's turn.
  bool get cue => _cue;

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
    _cue = false;
    _phase = _mode == GameMode.free ? Phase.free : Phase.ready;
    notifyListeners();
  }

  /// The middle of the circle was touched: it starts a game when one is
  /// waiting, and does nothing otherwise.
  void touchMiddle() {
    if (_phase != Phase.ready && _phase != Phase.finished) return;
    _sequence.clear();
    for (var i = 0; i < settings.startLength; i++) {
      _sequence.add(_nextNote());
    }
    _listen();
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

  void _listen() {
    _cancelTimers();
    _phase = Phase.listen;
    _shown = 0;
    _done = 0;
    _held.clear();
    _flashing.clear();
    _wrong = null;
    notifyListeners();
    for (var i = 0; i < _sequence.length; i++) {
      final at = leadIn + noteStep * i;
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
    final end = leadIn + noteStep * (_sequence.length - 1) + noteLit;
    _after(end + handOver, _yourTurn);
  }

  void _yourTurn() {
    _phase = Phase.yourTurn;
    // A light in the middle, with the hand: no sound, which a child would
    // take for one of the notes.
    _cue = true;
    notifyListeners();
    _after(cueLit, () {
      _cue = false;
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
          Phase.success ||
          Phase.finished:
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
    notifyListeners();
    if (_done == _sequence.length) _after(beforeSuccess, _success);
  }

  void _mistake(int note) {
    _cancelTimers();
    _phase = Phase.oops;
    _held.clear();
    _flashing.clear();
    _cue = false;
    _wrong = note;
    _wrongCount++;
    player.oops();
    notifyListeners();
    _after(lockout, _listen);
  }

  void _success() {
    _phase = Phase.success;
    _held.clear();
    notifyListeners();
    // The notes lit going up, one after another, then the last one left
    // lit: always the same, never as long as a sequence. It ends on a C,
    // so that it sounds finished: the high C of the xylophone, or the low
    // C again.
    final arpeggio = [
      for (var i = 0; i < _active; i++) i,
      if (_active < Notes.count) 0,
    ];
    for (var i = 0; i < arpeggio.length; i++) {
      final note = arpeggio[i];
      _after(arpeggioStep * i, () {
        _played
          ..clear()
          ..add(note);
        player.note(note, volume: 0.7);
        notifyListeners();
      });
    }
    final end = arpeggioStep * arpeggio.length + successHold;
    _after(end, () {
      _played.clear();
      if (_sequence.length >= settings.longest) {
        _phase = Phase.finished;
        notifyListeners();
      } else {
        _sequence.add(_nextNote());
        _listen();
      }
    });
  }

  @override
  void dispose() {
    settings.removeListener(_settingsChanged);
    _cancelTimers();
    super.dispose();
  }
}
