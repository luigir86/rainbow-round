import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Rainbow Round'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Screen-reader label of the gear, which opens only when held, so that a child does not open it by chance.
  ///
  /// In en, this message translates to:
  /// **'Settings, hold to open'**
  String get settingsHold;

  /// No description provided for @game.
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get game;

  /// No description provided for @gameSequence.
  ///
  /// In en, this message translates to:
  /// **'Listen and repeat'**
  String get gameSequence;

  /// No description provided for @gameFree.
  ///
  /// In en, this message translates to:
  /// **'Free play'**
  String get gameFree;

  /// No description provided for @labels.
  ///
  /// In en, this message translates to:
  /// **'On the slices'**
  String get labels;

  /// No description provided for @labelsNone.
  ///
  /// In en, this message translates to:
  /// **'Colours'**
  String get labelsNone;

  /// No description provided for @labelsSolfege.
  ///
  /// In en, this message translates to:
  /// **'Do Re Mi'**
  String get labelsSolfege;

  /// No description provided for @labelsLetters.
  ///
  /// In en, this message translates to:
  /// **'C D E'**
  String get labelsLetters;

  /// No description provided for @activeSlices.
  ///
  /// In en, this message translates to:
  /// **'Slices on'**
  String get activeSlices;

  /// No description provided for @activeSlicesHint.
  ///
  /// In en, this message translates to:
  /// **'From the low C up; the others stay dark and silent.'**
  String get activeSlicesHint;

  /// No description provided for @startLength.
  ///
  /// In en, this message translates to:
  /// **'First sequence'**
  String get startLength;

  /// No description provided for @longest.
  ///
  /// In en, this message translates to:
  /// **'Longest sequence'**
  String get longest;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'Notes. When the longest sequence is repeated, the game ends.'**
  String get notesHint;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About Rainbow Round'**
  String get about;

  /// No description provided for @aboutText.
  ///
  /// In en, this message translates to:
  /// **'A circle of eight notes to play, listen to and repeat. Free and open source, with no account, no ads and no internet.'**
  String get aboutText;

  /// No description provided for @stateReady.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get stateReady;

  /// No description provided for @stateListen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get stateListen;

  /// No description provided for @stateYourTurn.
  ///
  /// In en, this message translates to:
  /// **'Your turn'**
  String get stateYourTurn;

  /// No description provided for @stateWait.
  ///
  /// In en, this message translates to:
  /// **'Wait'**
  String get stateWait;

  /// No description provided for @stateWellDone.
  ///
  /// In en, this message translates to:
  /// **'Well done'**
  String get stateWellDone;

  /// No description provided for @stateAgain.
  ///
  /// In en, this message translates to:
  /// **'Another one?'**
  String get stateAgain;

  /// No description provided for @stateFree.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get stateFree;

  /// No description provided for @sequence.
  ///
  /// In en, this message translates to:
  /// **'Sequence: {notes}'**
  String sequence(String notes);

  /// No description provided for @sequenceEmpty.
  ///
  /// In en, this message translates to:
  /// **'No sequence yet'**
  String get sequenceEmpty;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
