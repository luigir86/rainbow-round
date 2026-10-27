import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../audio/note_player.dart';
import '../game/game_controller.dart';
import '../l10n/app_localizations.dart';
import 'round_screen.dart';
import 'settings.dart';
import 'theme.dart';

class RainbowApp extends StatefulWidget {
  const RainbowApp({super.key, required this.settings, required this.player});

  final AppSettings settings;
  final NotePlayer player;

  @override
  State<RainbowApp> createState() => _RainbowAppState();
}

class _RainbowAppState extends State<RainbowApp> {
  late final _game = GameController(
    player: widget.player,
    settings: widget.settings,
  );

  @override
  void initState() {
    super.initState();
    // The sounds load after the first frame, so the circle shows at once
    // and the first touch is already heard.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.player.prepare();
    });
  }

  @override
  void dispose() {
    _game.dispose();
    widget.player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    debugShowCheckedModeBanner: false,
    theme: RoundTheme.dark,
    darkTheme: RoundTheme.dark,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: RoundScreen(game: _game, settings: widget.settings),
  );
}
