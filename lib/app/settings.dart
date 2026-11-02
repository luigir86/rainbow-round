import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/notes.dart';

/// What the circle does.
enum GameMode {
  /// The circle plays a sequence and the child repeats it.
  sequence,

  /// The circle is a little piano: every touch plays its note.
  free,
}

/// The shape of the instrument on the screen. Two, to try which one a
/// child plays better.
enum Instrument {
  /// A circle of eight slices, C to high C, going up clockwise from the
  /// top.
  circle,

  /// A row of eight bars, C to high C, low on the left and high on the
  /// right, as on a real xylophone.
  xylophone;

  /// How many notes it has.
  int get notes => 8;
}

/// The grown-up's choices, kept on the phone between launches.
class AppSettings extends ChangeNotifier {
  /// Settings that are not saved anywhere; used in tests.
  AppSettings() : _prefs = null;

  AppSettings._(this._prefs) {
    final prefs = _prefs!;
    // A value of the wrong type or out of range falls back to the default:
    // it must never keep the app from opening.
    _mode =
        GameMode.values.asNameMap()[_read<String>(prefs, _modeKey)] ??
        GameMode.sequence;
    _instrument =
        Instrument.values.asNameMap()[_read<String>(prefs, _instrumentKey)] ??
        Instrument.circle;
    _labels = NoteLabels.values.asNameMap()[_read<String>(prefs, _labelsKey)];
    final active = _read<int>(prefs, _activeKey);
    _activeCount = activeChoices.contains(active) ? active! : Notes.count;
    final start = _read<int>(prefs, _startKey);
    _startLength = startChoices.contains(start) ? start! : 2;
    final longest = _read<int>(prefs, _longestKey);
    _longest = longestChoices.contains(longest) ? longest! : 6;
  }

  static Future<AppSettings> load() async =>
      AppSettings._(await SharedPreferences.getInstance());

  final SharedPreferences? _prefs;

  static const _modeKey = 'mode';
  static const _instrumentKey = 'instrument';
  static const _labelsKey = 'labels';
  static const _activeKey = 'activeSlices';
  static const _startKey = 'startLength';
  static const _longestKey = 'longestSequence';

  static const activeChoices = [3, 4, 5, 6, 7, 8];
  static const startChoices = [1, 2, 3, 4];
  static const longestChoices = [4, 6, 8, 10, 12];

  static T? _read<T>(SharedPreferences prefs, String key) {
    final value = prefs.get(key);
    return value is T ? value : null;
  }

  GameMode _mode = GameMode.sequence;
  Instrument _instrument = Instrument.circle;
  NoteLabels? _labels;
  int _activeCount = Notes.count;
  int _startLength = 2;
  int _longest = 6;

  GameMode get mode => _mode;
  set mode(GameMode value) {
    if (value == _mode) return;
    _mode = value;
    _prefs?.setString(_modeKey, value.name);
    notifyListeners();
  }

  Instrument get instrument => _instrument;
  set instrument(Instrument value) {
    if (value == _instrument) return;
    _instrument = value;
    _prefs?.setString(_instrumentKey, value.name);
    notifyListeners();
  }

  /// What is written on the slices; null until chosen, and then Do Re Mi
  /// in Italian and C D E in English.
  NoteLabels? get labels => _labels;
  set labels(NoteLabels? value) {
    if (value == _labels) return;
    _labels = value;
    if (value == null) {
      _prefs?.remove(_labelsKey);
    } else {
      _prefs?.setString(_labelsKey, value.name);
    }
    notifyListeners();
  }

  /// [labels], or the one that goes with [locale].
  NoteLabels labelsFor(Locale locale) =>
      _labels ??
      (locale.languageCode == 'it' ? NoteLabels.solfege : NoteLabels.letters);

  /// How many notes are lit, from the low C up: a child can start with
  /// three or four and the others stay dark and silent.
  int get activeCount => _activeCount;
  set activeCount(int value) {
    if (value == _activeCount || !activeChoices.contains(value)) return;
    _activeCount = value;
    _prefs?.setInt(_activeKey, value);
    notifyListeners();
  }

  /// How many notes the first sequence has.
  int get startLength => _startLength;
  set startLength(int value) {
    if (value == _startLength || !startChoices.contains(value)) return;
    _startLength = value;
    _prefs?.setInt(_startKey, value);
    notifyListeners();
  }

  /// The longest sequence: once repeated, the game ends and asks for
  /// another one.
  int get longest => _longest;
  set longest(int value) {
    if (value == _longest || !longestChoices.contains(value)) return;
    _longest = value;
    _prefs?.setInt(_longestKey, value);
    notifyListeners();
  }
}
