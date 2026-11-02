import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../game/notes.dart';

/// What the circle can make heard: its notes and the two signals of the
/// game. Behind an interface so that the tests run with no sound.
abstract class NotePlayer {
  /// Starts the audio engine and loads the sounds, so the first touch is
  /// heard at once. Safe to call more than once.
  Future<void> prepare();

  /// Plays the note of slice [note] (0 to 7).
  void note(int note, {double volume = 1});

  /// The signal that it is the child's turn: always the same, soft.
  void yourTurn();

  /// A mistake: one low, soft note.
  void oops();

  void dispose();
}

/// No sound: for tests.
class SilentNotePlayer implements NotePlayer {
  final played = <int>[];
  var turns = 0;
  var oopses = 0;

  @override
  Future<void> prepare() async {}

  @override
  void note(int note, {double volume = 1}) => played.add(note);

  @override
  void yourTurn() => turns++;

  @override
  void oops() => oopses++;

  @override
  void dispose() {}
}

/// The piano of Low End: the Salamander Grand Piano by Alexander Holm (a
/// Yamaha C5, public domain), one channel of the normal touch of the notes
/// recorded a minor third apart, each pitched up or down a semitone to
/// the notes in between. The files are Low End's, cut to 2.6 s (a note
/// fades out by then) and kept as 16-bit WAV, which the web version can
/// serve and decode as well.
class PianoNotePlayer implements NotePlayer {
  final _soloud = SoLoud.instance;
  Future<void>? _ready;
  final _sources = <int, AudioSource>{};
  AudioSource? _low;

  /// The sound still ringing on each slice, stopped when it is struck again
  /// as the damper of a real key would.
  final _ringing = <int, SoundHandle>{};

  /// The recordings, by MIDI number, and how far each was from equal
  /// temperament in cents (measured for Low End, `PianoSamples.tuning`).
  static const _recorded = <int, ({String asset, double cents})>{
    60: (asset: 'assets/piano/C4v8L.wav', cents: -1.6),
    63: (asset: 'assets/piano/Ds4v8L.wav', cents: 0.2),
    66: (asset: 'assets/piano/Fs4v8L.wav', cents: -2.4),
    69: (asset: 'assets/piano/A4v8L.wav', cents: 1.6),
    72: (asset: 'assets/piano/C5v8L.wav', cents: 4.7),
  };

  /// The soft touch of the low C (C3), for a mistake.
  static const _lowAsset = 'assets/piano/C3v5L.wav';
  static const _lowCents = -6.3;

  /// How long a note rings before it has faded away: a piano left to ring
  /// for ever would pile up under a child's quick touches.
  static const _ring = Duration(milliseconds: 2400);

  /// The fade of a note struck again, quick enough not to be heard as one.
  static const _damp = Duration(milliseconds: 60);

  @override
  Future<void> prepare() => _ready ??= _start().catchError((Object error) {
    _ready = null;
    debugPrint('Sound could not start: $error');
  });

  Future<void> _start() async {
    if (!_soloud.isInitialized) {
      // A shorter buffer than Low End's: here a sound answers a finger, not
      // a beat planned ahead.
      await _soloud.init(sampleRate: 48000, bufferSize: 1024);
      // The same safety net as Low End: a chord of many fingers never goes
      // past full scale.
      final limiter = _soloud.filters.limiterFilter;
      limiter.activate();
      limiter.threshold.value = 0;
      limiter.outputCeiling.value = -0.3;
    }
    for (final e in _recorded.entries) {
      _sources[e.key] = await _soloud.loadAsset(e.value.asset);
    }
    _low = await _soloud.loadAsset(_lowAsset);
  }

  /// The recording nearest to [midi].
  static int _rootFor(int midi) => _recorded.keys.reduce(
    (a, b) => (a - midi).abs() <= (b - midi).abs() ? a : b,
  );

  /// Plays [source], recorded at [cents] from [recorded], as [midi].
  SoundHandle? _strike(
    AudioSource source,
    int recorded,
    double cents,
    int midi,
    double volume,
  ) {
    try {
      final handle = _soloud.play(source, volume: volume, paused: true);
      final semitones = midi - recorded - cents / 100;
      _soloud.setRelativePlaySpeed(handle, math.pow(2, semitones / 12) * 1.0);
      _soloud.setPause(handle, false);
      _soloud.fadeVolume(handle, 0, _ring);
      _soloud.scheduleStop(handle, _ring);
      return handle;
    } catch (error) {
      debugPrint('Note not played: $error');
      return null;
    }
  }

  void _play(int midi, double volume, {int? slice}) {
    if (_sources.isEmpty) {
      // Not loaded yet (in a browser, sound may only start after a first
      // touch): the note comes as soon as it is, a little late.
      unawaited(
        prepare().then((_) {
          if (_sources.isNotEmpty) _play(midi, volume, slice: slice);
        }),
      );
      return;
    }
    final root = _rootFor(midi);
    if (slice != null) {
      final old = _ringing.remove(slice);
      if (old != null && _soloud.getIsValidVoiceHandle(old)) {
        _soloud.fadeVolume(old, 0, _damp);
        _soloud.scheduleStop(old, _damp);
      }
    }
    final handle = _strike(
      _sources[root]!,
      root,
      _recorded[root]!.cents,
      midi,
      volume,
    );
    if (slice != null && handle != null) _ringing[slice] = handle;
  }

  @override
  void note(int note, {double volume = 1}) =>
      _play(Notes.midi[note], volume, slice: note);

  @override
  void yourTurn() {
    // Two high notes together, an octave above the circle and soft: a
    // little bell, never one of the notes of the game.
    _play(79, 0.22);
    _play(84, 0.28);
  }

  @override
  void oops() {
    final low = _low;
    if (low == null) return;
    _strike(low, 48, _lowCents, 48, 0.7);
  }

  @override
  void dispose() {
    if (_soloud.isInitialized) _soloud.deinit();
  }
}
