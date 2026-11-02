import 'dart:math' as math;

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
typedef PhaseLook = ({
  IconData icon,
  String label,
  Color color,
  bool startable,
});

/// The behaviour every shape shares: a note under each finger, the shake
/// of a wrong note, the light of the child's turn.
abstract class InstrumentViewState<T extends InstrumentView> extends State<T>
    with TickerProviderStateMixin {
  /// The note touched by mistake shakes, briefly.
  late final shake = AnimationController(
    vsync: this,
    duration: Durations.long1,
  );

  /// The state lights up with the signal of the child's turn, and fades.
  late final cue = AnimationController(
    vsync: this,
    duration: Durations.medium2,
  );

  /// The note under each finger.
  final _fingers = <int, int>{};

  int _wrongCount = 0;

  /// What is under [point] in an instrument of [size]: a note, the state
  /// (-1), or nothing (null).
  int? hitAt(Offset point, Size size);

  @override
  void initState() {
    super.initState();
    _wrongCount = widget.game.wrongCount;
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

  void _changed() {
    final game = widget.game;
    final still = MediaQuery.disableAnimationsOf(context);
    if (game.wrongCount != _wrongCount) {
      _wrongCount = game.wrongCount;
      // With fewer animations asked for, the note does not shake: the low
      // note and the pause still say it.
      if (!still) shake.forward(from: 0);
    }
    if (game.cue) {
      cue.value = 1;
    } else if (cue.value > 0) {
      if (still) {
        cue.value = 0;
      } else {
        cue.reverse();
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    widget.game.removeListener(_changed);
    shake.dispose();
    cue.dispose();
    super.dispose();
  }

  /// How far the wrong note is moved now, from -1 to 1: a few small swings
  /// that die away.
  double get shakeAmount {
    final t = shake.value;
    if (t == 0 || t == 1) return 0;
    return math.sin(t * math.pi * 6) * (1 - t);
  }

  /// Every finger on its own note, so several make a chord; a touch that
  /// starts and ends on the state starts a game.
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

  PhaseLook look(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final phase = widget.game.phase;
    final (icon, label) = switch (phase) {
      Phase.free => (Icons.music_note_rounded, l10n.stateFree),
      Phase.ready => (Icons.play_arrow_rounded, l10n.stateReady),
      Phase.listen => (Icons.hearing_rounded, l10n.stateListen),
      Phase.yourTurn => (Icons.back_hand_rounded, l10n.stateYourTurn),
      Phase.oops => (Icons.back_hand_rounded, l10n.stateWait),
      Phase.success => (Icons.star_rounded, l10n.stateWellDone),
      Phase.finished => (Icons.replay_rounded, l10n.stateAgain),
    };
    return (
      icon: icon,
      label: label,
      color: switch (phase) {
        Phase.success => scheme.primary,
        Phase.oops || Phase.free => scheme.onSurfaceVariant,
        _ => scheme.onSurface,
      },
      startable: phase == Phase.ready || phase == Phase.finished,
    );
  }

  /// The icon of the state, on the place that lights with the signal of
  /// the child's turn: there the hand turns dark and a little bigger.
  Widget stateIcon(BuildContext context, double size) {
    final look = this.look(context);
    final onLit = Theme.of(context).colorScheme.onPrimary;
    return Semantics(
      button: look.startable,
      label: look.label,
      onTap: look.startable ? widget.game.touchMiddle : null,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: cue,
        builder: (context, _) => Icon(
          look.icon,
          size: size * (1 + 0.15 * cue.value),
          color: Color.lerp(look.color, onLit, cue.value),
        ),
      ),
    );
  }

  /// The colour of note [i] now: off, lit, stepping back while another
  /// sounds, or its own.
  Color noteColor(int i, RoundColors colors) {
    final game = widget.game;
    if (!game.isActive(i)) return colors.sliceOff;
    if (game.lit.contains(i)) return colors.lit(i);
    final receding = game.phase == Phase.listen || game.phase == Phase.success;
    return receding ? colors.receded(i) : colors.notes[i];
  }
}
