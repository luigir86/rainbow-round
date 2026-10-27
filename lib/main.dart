import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/rainbow_app.dart';
import 'app/settings.dart';
import 'audio/note_player.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppSettings settings;
  try {
    settings = await AppSettings.load();
  } catch (error) {
    // Unreadable settings must never keep the app from opening.
    debugPrint('Settings could not be read: $error');
    settings = AppSettings();
  }
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Edwin',
    ], await rootBundle.loadString('assets/fonts/OFL-Edwin.txt'));
    yield const LicenseEntryWithLineBreaks(
      ['Salamander Grand Piano V3'],
      'Piano recordings by Alexander Holm, released into the public domain '
      'on 4 March 2022. No licence is needed to use them.',
    );
  });
  runApp(RainbowApp(settings: settings, player: PianoNotePlayer()));
}
