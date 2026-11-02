// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Rainbow Round';

  @override
  String get settings => 'Settings';

  @override
  String get settingsHold => 'Settings, hold to open';

  @override
  String get game => 'Game';

  @override
  String get gameSequence => 'Listen and repeat';

  @override
  String get gameFree => 'Free play';

  @override
  String get labels => 'On the slices';

  @override
  String get labelsNone => 'Colours';

  @override
  String get labelsSolfege => 'Do Re Mi';

  @override
  String get labelsLetters => 'C D E';

  @override
  String get activeSlices => 'Notes on';

  @override
  String get activeSlicesHint =>
      'From the low C up; the others stay dark and silent. The circle has seven notes, the xylophone eight.';

  @override
  String get startLength => 'First sequence';

  @override
  String get longest => 'Longest sequence';

  @override
  String get notesHint =>
      'Notes. When the longest sequence is repeated, the game ends.';

  @override
  String get about => 'About Rainbow Round';

  @override
  String get aboutText =>
      'A circle of eight notes to play, listen to and repeat. Free and open source, with no account, no ads and no internet.';

  @override
  String get stateReady => 'Start';

  @override
  String get stateListen => 'Listen';

  @override
  String get stateYourTurn => 'Your turn';

  @override
  String get stateWait => 'Wait';

  @override
  String get stateWellDone => 'Well done';

  @override
  String get stateAgain => 'Another one?';

  @override
  String get stateFree => 'Play';

  @override
  String sequence(String notes) {
    return 'Sequence: $notes';
  }

  @override
  String get sequenceEmpty => 'No sequence yet';

  @override
  String get instrument => 'Instrument';

  @override
  String get instrumentCircle => 'Circle';

  @override
  String get instrumentXylophone => 'Xylophone';
}
