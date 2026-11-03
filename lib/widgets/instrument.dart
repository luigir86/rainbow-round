import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../game/game_controller.dart';
import '../game/notes.dart';
import '../l10n/app_localizations.dart';

/// What the instrument on the screen shares, whatever its shape (the
/// circle or the xylophone): the game it plays and how notes are named.
abstract class InstrumentView extends StatefulWidget {
  const InstrumentView({
    super.key,
    required this.game,
    required this.labels,
    required this.spokenLabels,
  });

  final GameController game;

  /// What is written on the notes.
  final NoteLabels labels;

  /// How a screen reader names the notes, even with only the colours
  /// shown.
  final NoteLabels spokenLabels;
}

/// How the place that shows the state looks in each phase: the middle of
/// the circle, the button over the xylophone.
typedef PhaseLook = ({IconData? icon, String label, bool startable});

/// The behaviour every shape shares: a note under each finger, the
/// middle that plays the sequence, the grey of a circle that cannot be
/// played. Nothing moves by itself.
abstract class InstrumentViewState<T extends InstrumentView> extends State<T> {
  /// The note under each finger.
  final _fingers = <int, int>{};

  /// What is under [point] in an instrument of [size]: a note, the state
  /// (-1), or nothing (null).
  int? hitAt(Offset point, Size size);

  @override
  void initState() {
    super.initState();
    widget.game.addListener(_changed);
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game != widget.game) {
      oldWidget.game.removeListener(_changed);
      widget.game.addListener(_changed);
    }
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    widget.game.removeListener(_changed);
    super.dispose();
  }

  /// Every finger on its own note, so several make a chord; a touch that
  /// starts and ends on the state plays the sequence.
  Widget touches(Size size, Widget child) => Listener(
    behavior: HitTestBehavior.opaque,
    onPointerDown: (event) {
      final hit = hitAt(event.localPosition, size);
      if (hit == null || hit < 0) return;
      _fingers[event.pointer] = hit;
      widget.game.press(hit);
    },
    onPointerUp: (event) => _up(event, size),
    onPointerCancel: (event) => _up(event, size),
    child: child,
  );

  void _up(PointerEvent event, Size size) {
    final note = _fingers.remove(event.pointer);
    if (note != null) {
      widget.game.release(note);
    } else if (event is PointerUpEvent &&
        hitAt(event.localPosition, size) == -1) {
      widget.game.touchMiddle();
    }
  }

  /// The middle shows an icon only when it can be touched (the ear: it
  /// plays the sequence) and for the star at the end. Otherwise it is
  /// empty: the colours of the circle say whose turn it is.
  PhaseLook look(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final phase = widget.game.phase;
    final (icon, label) = switch (phase) {
      Phase.free => (null, l10n.stateFree),
      Phase.ready => (Icons.hearing_rounded, l10n.stateReady),
      Phase.listen => (null, l10n.stateListen),
      Phase.yourTurn => (null, l10n.stateYourTurn),
      Phase.oops => (null, l10n.stateWait),
      Phase.again => (Icons.hearing_rounded, l10n.stateAgain),
      Phase.success => (Icons.star_rounded, l10n.stateWellDone),
    };
    return (icon: icon, label: label, startable: widget.game.middleStarts);
  }

  /// The colour of the middle: bronze when it can be touched or at the
  /// celebration, the dark of the disc otherwise.
  Color middleColor(BuildContext context) {
    final game = widget.game;
    final lit = game.middleStarts || game.phase == Phase.success;
    return lit
        ? Theme.of(context).colorScheme.primary
        : RoundColors.of(context).disc;
  }

  /// The icon of the state, dark on the bronze of the middle.
  Widget stateIcon(BuildContext context, double size) {
    final look = this.look(context);
    return Semantics(
      button: look.startable,
      label: look.label,
      onTap: look.startable ? widget.game.touchMiddle : null,
      excludeSemantics: true,
      child: look.icon == null
          ? SizedBox.square(dimension: size)
          : Icon(
              look.icon,
              size: size,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
    );
  }

  /// The colour of note [i] now. While the circle cannot be played it is
  /// grey, and the note that sounds has its own colour; while it can, the
  /// notes have their colours and the one touched lights up.
  Color noteColor(int i, RoundColors colors) {
    final game = widget.game;
    if (!game.isActive(i)) return colors.sliceOff;
    final lit = game.lit.contains(i);
    if (game.playable) return lit ? colors.lit(i) : colors.notes[i];
    return lit ? colors.notes[i] : colors.asleep(i);
  }
}
