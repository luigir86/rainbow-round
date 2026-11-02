import 'package:flutter/material.dart';

import '../game/game_controller.dart';
import '../game/notes.dart';
import '../l10n/app_localizations.dart';
import '../widgets/hold_gear.dart';
import '../widgets/rainbow_circle.dart';
import '../widgets/sequence_dots.dart';
import 'settings.dart';
import 'settings_page.dart';

/// The one screen: the circle, the dots under it, and the gear.
class RoundScreen extends StatelessWidget {
  const RoundScreen({super.key, required this.game, required this.settings});

  final GameController game;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([game, settings]),
          builder: (context, _) {
            final locale = Localizations.localeOf(context);
            final labels = settings.labelsFor(locale);
            // A screen reader names the notes even with only the colours.
            final spoken = labels == NoteLabels.none
                ? (locale.languageCode == 'it'
                      ? NoteLabels.solfege
                      : NoteLabels.letters)
                : labels;
            final circle = RainbowCircle(
              game: game,
              labels: labels,
              spokenLabels: spoken,
            );
            final dots = SequenceDots(
              game: game,
              labels: labels,
              spokenLabels: spoken,
            );
            final landscape =
                MediaQuery.sizeOf(context).width >
                MediaQuery.sizeOf(context).height;
            return Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 56, 16, 24),
                  child: landscape
                      ? Row(
                          children: [
                            Expanded(child: Center(child: circle)),
                            const SizedBox(width: 24),
                            Expanded(child: Center(child: dots)),
                          ],
                        )
                      : Column(
                          children: [
                            Expanded(child: Center(child: circle)),
                            const SizedBox(height: 24),
                            dots,
                            const SizedBox(height: 24),
                          ],
                        ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: HoldGear(
                    label: l10n.settingsHold,
                    onOpen: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SettingsPage(settings: settings),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
