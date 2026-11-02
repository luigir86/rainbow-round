// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Rainbow Round';

  @override
  String get settings => 'Impostazioni';

  @override
  String get settingsHold => 'Impostazioni, tieni premuto per aprire';

  @override
  String get game => 'Gioco';

  @override
  String get gameSequence => 'Ascolta e ripeti';

  @override
  String get gameFree => 'Gioco libero';

  @override
  String get labels => 'Sugli spicchi';

  @override
  String get labelsNone => 'Colori';

  @override
  String get labelsSolfege => 'Do Re Mi';

  @override
  String get labelsLetters => 'C D E';

  @override
  String get activeSlices => 'Note accese';

  @override
  String get activeSlicesHint =>
      'Dal do basso in su; le altre restano spente e mute.';

  @override
  String get startLength => 'Prima sequenza';

  @override
  String get longest => 'Sequenza più lunga';

  @override
  String get notesHint =>
      'Note. Ripetuta la sequenza più lunga, il gioco finisce.';

  @override
  String get about => 'Informazioni su Rainbow Round';

  @override
  String get aboutText =>
      'Un cerchio di otto note da suonare, ascoltare e ripetere. Gratuito e open source, senza account, senza pubblicità e senza internet.';

  @override
  String get stateReady => 'Inizia';

  @override
  String get stateListen => 'Ascolta';

  @override
  String get stateYourTurn => 'Tocca a te';

  @override
  String get stateWait => 'Aspetta';

  @override
  String get stateWellDone => 'Ottimo!';

  @override
  String get stateAgain => 'Ancora una?';

  @override
  String get stateFree => 'Suona';

  @override
  String sequence(String notes) {
    return 'Sequenza: $notes';
  }

  @override
  String get sequenceEmpty => 'Ancora nessuna sequenza';

  @override
  String get instrument => 'Strumento';

  @override
  String get instrumentCircle => 'Cerchio';

  @override
  String get instrumentXylophone => 'Xilofono';
}
