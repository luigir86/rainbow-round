import 'package:flutter/material.dart';

import '../game/notes.dart';
import '../l10n/app_localizations.dart';
import 'settings.dart';

/// The grown-up's page, behind the gear held down.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _Setting<GameMode>(
              title: l10n.game,
              value: settings.mode,
              choices: {
                GameMode.sequence: l10n.gameSequence,
                GameMode.free: l10n.gameFree,
              },
              onChanged: (v) => settings.mode = v,
            ),
            _Setting<Instrument>(
              title: l10n.instrument,
              value: settings.instrument,
              choices: {
                Instrument.circle: l10n.instrumentCircle,
                Instrument.xylophone: l10n.instrumentXylophone,
              },
              onChanged: (v) => settings.instrument = v,
            ),
            _Setting<NoteLabels>(
              title: l10n.labels,
              value: settings.labelsFor(locale),
              choices: {
                NoteLabels.none: l10n.labelsNone,
                NoteLabels.solfege: l10n.labelsSolfege,
                NoteLabels.letters: l10n.labelsLetters,
              },
              onChanged: (v) => settings.labels = v,
            ),
            _Setting<int>(
              title: l10n.activeSlices,
              hint: l10n.activeSlicesHint,
              value: settings.activeCount,
              choices: {for (final n in AppSettings.activeChoices) n: '$n'},
              onChanged: (v) => settings.activeCount = v,
            ),
            _Setting<int>(
              title: l10n.startLength,
              value: settings.startLength,
              choices: {for (final n in AppSettings.startChoices) n: '$n'},
              onChanged: (v) => settings.startLength = v,
            ),
            _Setting<int>(
              title: l10n.longest,
              hint: l10n.notesHint,
              value: settings.longest,
              choices: {for (final n in AppSettings.longestChoices) n: '$n'},
              onChanged: (v) => settings.longest = v,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.info_outline_rounded),
              title: Text(l10n.about),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: l10n.appTitle,
                applicationLegalese: l10n.aboutText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One choice of the settings: its name, then the options side by side.
class _Setting<T> extends StatelessWidget {
  const _Setting({
    required this.title,
    required this.value,
    required this.choices,
    required this.onChanged,
    this.hint,
  });

  final String title;
  final String? hint;
  final T value;
  final Map<T, String> choices;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: text.titleMedium),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(
              hint!,
              style: text.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 8),
          SegmentedButton<T>(
            showSelectedIcon: false,
            segments: [
              for (final e in choices.entries)
                ButtonSegment(value: e.key, label: Text(e.value)),
            ],
            selected: {value},
            onSelectionChanged: (s) => onChanged(s.first),
          ),
        ],
      ),
    );
  }
}
