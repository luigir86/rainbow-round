import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../app/style.dart';
import '../app/theme.dart';
import '../game/game_controller.dart';
import '../game/notes.dart';
import '../l10n/app_localizations.dart';

/// The proportions of the circle, as fractions of its radius.
abstract final class CircleGeometry {
  /// The hub in the middle, which shows the state and starts a game.
  static const hub = 0.34;

  /// Where the slices begin and end.
  static const sliceInner = 0.38;
  static const sliceOuter = 0.93;

  /// A lit slice grows out to the edge.
  static const sliceLit = 1.0;

  /// The border lit with the signal of the child's turn.
  static const cue = 0.965;

  /// The gap between two slices, in radians at each side.
  static const gap = 0.025;

  /// Where the name of a note is written.
  static const label = 0.67;

  /// The angle, in radians from three o'clock, of the middle of slice
  /// [note]: the low C at the top, then clockwise.
  static double angleOf(int note) => -math.pi / 2 + note * 2 * math.pi / 8;

  /// What is under [point], in a circle of [size]: a slice (0 to 7), the
  /// hub (-1), or nothing (null).
  static int? hit(Offset point, Size size) {
    final radius = size.shortestSide / 2;
    final v = point - size.center(Offset.zero);
    final d = v.distance / radius;
    if (d <= hub) return -1;
    if (d < sliceInner - 0.02 || d > sliceLit) return null;
    // From the top, clockwise, half a slice back so the low C's slice
    // is centred on the top.
    var a = math.atan2(v.dy, v.dx) + math.pi / 2 + math.pi / 8;
    a %= 2 * math.pi;
    return (a / (2 * math.pi / 8)).floor() % 8;
  }
}

/// The circle: eight slices from C to high C round a hub that shows the
/// state. Every finger counts at once, so several slices make a chord.
class RainbowCircle extends StatefulWidget {
  const RainbowCircle({
    super.key,
    required this.game,
    required this.labels,
    required this.spokenLabels,
  });

  final GameController game;

  /// What is written on the slices.
  final NoteLabels labels;

  /// How a screen reader names the slices, even with only the colours
  /// shown.
  final NoteLabels spokenLabels;

  @override
  State<RainbowCircle> createState() => _RainbowCircleState();
}

class _RainbowCircleState extends State<RainbowCircle>
    with TickerProviderStateMixin {
  /// The slice touched by mistake shakes, briefly.
  late final _shake = AnimationController(
    vsync: this,
    duration: Durations.long1,
  );

  /// The border lights with the signal of the child's turn, and fades.
  late final _cue = AnimationController(
    vsync: this,
    duration: Durations.medium2,
  );

  /// The slice under each finger.
  final _fingers = <int, int>{};

  int _wrongCount = 0;

  @override
  void initState() {
    super.initState();
    _wrongCount = widget.game.wrongCount;
    widget.game.addListener(_changed);
  }

  @override
  void didUpdateWidget(RainbowCircle oldWidget) {
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
      // With fewer animations asked for, the slice does not shake: the
      // low note and the pause still say it.
      if (!still) _shake.forward(from: 0);
    }
    if (game.cue) {
      _cue.value = 1;
    } else if (_cue.value > 0) {
      if (still) {
        _cue.value = 0;
      } else {
        _cue.reverse();
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    widget.game.removeListener(_changed);
    _shake.dispose();
    _cue.dispose();
    super.dispose();
  }

  void _down(PointerDownEvent event, Size size) {
    final hit = CircleGeometry.hit(event.localPosition, size);
    if (hit == null || hit < 0) return;
    _fingers[event.pointer] = hit;
    widget.game.press(hit);
  }

  void _up(PointerEvent event, Size size) {
    final note = _fingers.remove(event.pointer);
    if (note != null) {
      widget.game.release(note);
    } else if (event is PointerUpEvent &&
        CircleGeometry.hit(event.localPosition, size) == -1) {
      widget.game.touchMiddle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final (icon, state) = switch (game.phase) {
      Phase.free => (Icons.music_note_rounded, l10n.stateFree),
      Phase.ready => (Icons.play_arrow_rounded, l10n.stateReady),
      Phase.listen => (Icons.hearing_rounded, l10n.stateListen),
      Phase.yourTurn => (Icons.back_hand_rounded, l10n.stateYourTurn),
      Phase.oops => (Icons.back_hand_rounded, l10n.stateWait),
      Phase.success => (Icons.star_rounded, l10n.stateWellDone),
      Phase.finished => (Icons.replay_rounded, l10n.stateAgain),
    };
    final iconColor = switch (game.phase) {
      Phase.success => scheme.primary,
      Phase.oops || Phase.free => scheme.onSurfaceVariant,
      _ => scheme.onSurface,
    };
    final startable = game.phase == Phase.ready || game.phase == Phase.finished;
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final radius = size.shortestSide / 2;
          return Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (e) => _down(e, size),
            onPointerUp: (e) => _up(e, size),
            onPointerCancel: (e) => _up(e, size),
            child: Stack(
              fit: StackFit.expand,
              children: [
                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_shake, _cue]),
                    builder: (context, _) => CustomPaint(
                      painter: _CirclePainter(
                        colors: RoundColors.of(context),
                        cueColor: scheme.primary,
                        text: Theme.of(context).textTheme.headlineSmall!
                            .copyWith(
                              fontWeight: FontWeight.w700,
                              color: Palette.inkOnLight,
                            ),
                        textScaler: MediaQuery.textScalerOf(context),
                        game: game,
                        activeCount: game.activeCount,
                        labels: widget.labels,
                        spokenLabels: widget.spokenLabels,
                        lit: game.lit,
                        receding:
                            game.phase == Phase.listen ||
                            game.phase == Phase.success,
                        shake: _shakeAngle(),
                        cue: _cue.value,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Semantics(
                    button: startable,
                    label: state,
                    onTap: startable ? game.touchMiddle : null,
                    excludeSemantics: true,
                    child: Icon(
                      icon,
                      size: radius * CircleGeometry.hub * 1.1,
                      color: iconColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// How far the wrong slice is turned now: a few small swings that die
  /// away.
  double _shakeAngle() {
    final t = _shake.value;
    if (t == 0 || t == 1) return 0;
    return math.sin(t * math.pi * 6) * (1 - t) * 0.06;
  }
}

class _CirclePainter extends CustomPainter {
  _CirclePainter({
    required this.colors,
    required this.cueColor,
    required this.text,
    required this.textScaler,
    required this.game,
    required this.activeCount,
    required this.labels,
    required this.spokenLabels,
    required this.lit,
    required this.receding,
    required this.shake,
    required this.cue,
  });

  final RoundColors colors;
  final Color cueColor;
  final TextStyle text;
  final TextScaler textScaler;
  final GameController game;
  final int activeCount;
  final NoteLabels labels;
  final NoteLabels spokenLabels;
  final Set<int> lit;

  /// The slices not lit step back, so that the one sounding stands out.
  final bool receding;
  final double shake;
  final double cue;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final paint = Paint()..isAntiAlias = true;

    if (cue > 0) {
      canvas.drawCircle(
        center,
        radius * CircleGeometry.cue,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.05
          ..color = cueColor.withValues(alpha: cue),
      );
    }

    for (var i = 0; i < Notes.count; i++) {
      final active = game.isActive(i);
      final on = active && lit.contains(i);
      final outer = on ? CircleGeometry.sliceLit : CircleGeometry.sliceOuter;
      final turn = game.wrong == i ? shake : 0.0;
      final mid = CircleGeometry.angleOf(i) + turn;
      const half = math.pi / 8 - CircleGeometry.gap;
      final path = Path()
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius * outer),
          mid - half,
          half * 2,
          true,
        )
        ..arcTo(
          Rect.fromCircle(
            center: center,
            radius: radius * CircleGeometry.sliceInner,
          ),
          mid + half,
          -half * 2,
          false,
        )
        ..close();
      paint.color = !active
          ? colors.sliceOff
          : on
          ? colors.lit(i)
          : receding
          ? colors.receded(i)
          : colors.notes[i];
      canvas.drawPath(path, paint);

      final name = labels.nameOf(i);
      if (active && name != null) {
        final painter = TextPainter(
          text: TextSpan(text: name, style: text),
          textDirection: TextDirection.ltr,
          textScaler: textScaler,
        )..layout();
        // A name that would not fit the slice shrinks, never past the
        // smallest size of the app.
        final room = radius * 0.34;
        if (painter.width > room) {
          final scale = math.max(room / painter.width, RoundType.small / 24);
          painter.textScaler = TextScaler.linear(textScaler.scale(1) * scale);
          painter.layout();
        }
        final at =
            center +
            Offset(math.cos(mid), math.sin(mid)) *
                radius *
                CircleGeometry.label;
        painter.paint(
          canvas,
          at - Offset(painter.width / 2, painter.height / 2),
        );
      }
    }

    canvas.drawCircle(
      center,
      radius * CircleGeometry.hub,
      Paint()..color = colors.disc,
    );
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder => (size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    return [
      for (var i = 0; i < Notes.count; i++)
        if (game.isActive(i))
          CustomPainterSemantics(
            key: ValueKey('slice$i'),
            rect: Rect.fromCircle(
              center:
                  center +
                  Offset(
                        math.cos(CircleGeometry.angleOf(i)),
                        math.sin(CircleGeometry.angleOf(i)),
                      ) *
                      radius *
                      CircleGeometry.label,
              radius: radius * 0.18,
            ),
            properties: SemanticsProperties(
              label: spokenLabels.nameOf(i),
              textDirection: TextDirection.ltr,
              button: true,
              onTap: () {
                game.press(i);
                game.release(i);
              },
            ),
          ),
    ];
  };

  @override
  bool shouldRepaint(_CirclePainter old) => true;

  @override
  bool shouldRebuildSemantics(_CirclePainter old) =>
      old.spokenLabels != spokenLabels ||
      old.game != game ||
      old.activeCount != activeCount;
}
