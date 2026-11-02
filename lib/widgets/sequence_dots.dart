import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../game/game_controller.dart';
import '../game/notes.dart';
import '../l10n/app_localizations.dart';

/// The row of dots under the circle: the sequence, written as it is heard,
/// for the child to read and repeat. Only to look at: touching it does
/// nothing.
class SequenceDots extends StatelessWidget {
  const SequenceDots({
    super.key,
    required this.game,
    required this.labels,
    required this.spokenLabels,
  });

  final GameController game;
  final NoteLabels labels;
  final NoteLabels spokenLabels;

  /// The size of a dot, and of the one to touch now.
  static const dot = 36.0;
  static const next = 50.0;
  static const gap = 10.0;

  @override
  Widget build(BuildContext context) {
    final colors = RoundColors.of(context);
    final sequence = game.sequence;
    final phase = game.phase;
    final repeating = phase == Phase.yourTurn || phase == Phase.oops;
    final count = switch (phase) {
      Phase.free || Phase.ready => 0,
      Phase.listen => game.shown,
      _ => sequence.length,
    };
    final l10n = AppLocalizations.of(context);
    final spoken = [
      for (final n in sequence.take(count)) spokenLabels.nameOf(n),
    ].join(', ');
    return Semantics(
      label: count == 0 ? l10n.sequenceEmpty : l10n.sequence(spoken),
      excludeSemantics: true,
      child: IgnorePointer(
        child: SizedBox(
          height: next,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < count; i++) ...[
                  if (i > 0) const SizedBox(width: gap),
                  _Dot(
                    color: colors.notes[sequence[i]],
                    disc: colors.disc,
                    name: labels.nameOf(sequence[i]),
                    // While the child repeats, the dots not yet played
                    // are rings, and fill as they are played; the next one
                    // is bigger.
                    filled: !repeating || i < game.done,
                    size: repeating && i == game.done ? next : dot,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.color,
    required this.disc,
    required this.name,
    required this.filled,
    required this.size,
  });

  final Color color;
  final Color disc;
  final String? name;
  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium!.copyWith(
      fontWeight: FontWeight.w700,
      color: filled ? Palette.inkOnLight : color,
    );
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : Durations.short4,
      curve: Easing.standard,
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? color : disc,
        border: Border.all(color: color, width: 4),
      ),
      child: name == null
          ? null
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Text(name!, style: style),
              ),
            ),
    );
  }
}
