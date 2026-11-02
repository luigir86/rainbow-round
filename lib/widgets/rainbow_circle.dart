import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../app/style.dart';
import '../app/theme.dart';
import '../game/game_controller.dart';
import '../game/notes.dart';
import 'instrument.dart';

/// The proportions of the circle, as fractions of its radius.
abstract final class CircleGeometry {
  /// The hub in the middle, which shows the state and starts a game.
  static const hub = 0.34;

  /// Where the slices begin and end.
  static const sliceInner = 0.38;
  static const sliceOuter = 0.93;

  /// A lit slice grows out to the edge.
  static const sliceLit = 1.0;

  /// The halo round the hub when it lights with the signal of the child's
  /// turn.
  static const cueHalo = 0.37;

  /// The gap between two slices, in radians at each side.
  static const gap = 0.025;

  /// Where the name of a note is written.
  static const label = 0.67;

  /// The angle, in radians from three o'clock, of the middle of slice
  /// [note] of [count]: the low C at the top, then clockwise.
  static double angleOf(int note, int count) =>
      -math.pi / 2 + note * 2 * math.pi / count;

  /// What is under [point], in a circle of [count] slices and [size]: a
  /// slice, the hub (-1), or nothing (null).
  static int? hit(Offset point, Size size, int count) {
    final radius = size.shortestSide / 2;
    final v = point - size.center(Offset.zero);
    final d = v.distance / radius;
    if (d <= hub) return -1;
    if (d < sliceInner - 0.02 || d > sliceLit) return null;
    // From the top, clockwise, half a slice back so the low C's slice
    // is centred on the top.
    final step = 2 * math.pi / count;
    var a = math.atan2(v.dy, v.dx) + math.pi / 2 + step / 2;
    a %= 2 * math.pi;
    return (a / step).floor() % count;
  }
}

/// The circle: seven slices from C to B round a hub that shows the state.
/// Going round is going up the scale, and after the B the C comes again.
/// Every finger counts at once, so several slices make a chord.
class RainbowCircle extends InstrumentView {
  const RainbowCircle({
    super.key,
    required super.game,
    required super.labels,
    required super.spokenLabels,
  });

  @override
  State<RainbowCircle> createState() => _RainbowCircleState();
}

class _RainbowCircleState extends InstrumentViewState<RainbowCircle> {
  @override
  int? hitAt(Offset point, Size size) =>
      CircleGeometry.hit(point, size, widget.game.noteCount);

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final scheme = Theme.of(context).colorScheme;
    final colors = RoundColors.of(context);
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final radius = size.shortestSide / 2;
          return touches(
            size,
            Stack(
              fit: StackFit.expand,
              children: [
                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([shake, cue]),
                    builder: (context, _) => CustomPaint(
                      painter: _CirclePainter(
                        colors: colors,
                        fills: [
                          for (var i = 0; i < game.noteCount; i++)
                            noteColor(i, colors),
                        ],
                        cueColor: scheme.primary,
                        text: Theme.of(context).textTheme.headlineSmall!
                            .copyWith(fontWeight: FontWeight.w700),
                        textScaler: MediaQuery.textScalerOf(context),
                        game: game,
                        count: game.noteCount,
                        activeCount: game.activeCount,
                        labels: widget.labels,
                        spokenLabels: widget.spokenLabels,
                        shake: shakeAmount * 0.06,
                        cue: cue.value,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: stateIcon(context, radius * CircleGeometry.hub * 1.1),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  _CirclePainter({
    required this.colors,
    required this.fills,
    required this.cueColor,
    required this.text,
    required this.textScaler,
    required this.game,
    required this.count,
    required this.activeCount,
    required this.labels,
    required this.spokenLabels,
    required this.shake,
    required this.cue,
  });

  final RoundColors colors;

  /// The colour of each slice now.
  final List<Color> fills;
  final Color cueColor;
  final TextStyle text;
  final TextScaler textScaler;
  final GameController game;
  final int count;
  final int activeCount;
  final NoteLabels labels;
  final NoteLabels spokenLabels;

  /// How far the wrong slice is turned, in radians.
  final double shake;
  final double cue;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final paint = Paint()..isAntiAlias = true;
    final half = math.pi / count - CircleGeometry.gap;

    for (var i = 0; i < count; i++) {
      final active = game.isActive(i);
      final on = active && game.lit.contains(i);
      final outer = on ? CircleGeometry.sliceLit : CircleGeometry.sliceOuter;
      final turn = game.wrong == i ? shake : 0.0;
      final mid = CircleGeometry.angleOf(i, count) + turn;
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
      paint.color = fills[i];
      canvas.drawPath(path, paint);

      final name = labels.nameOf(i);
      if (active && name != null) {
        final painter = TextPainter(
          text: TextSpan(
            text: name,
            style: text.copyWith(color: RoundColors.inkOn(fills[i])),
          ),
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

    // The hub lights up with the signal of the child's turn, with a halo
    // in the gap before the slices.
    if (cue > 0) {
      canvas.drawCircle(
        center,
        radius * CircleGeometry.cueHalo,
        Paint()..color = cueColor.withValues(alpha: cue * 0.5),
      );
    }
    canvas.drawCircle(
      center,
      radius * CircleGeometry.hub,
      Paint()..color = Color.lerp(colors.disc, cueColor, cue)!,
    );
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder => (size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    return [
      for (var i = 0; i < count; i++)
        if (game.isActive(i))
          CustomPainterSemantics(
            key: ValueKey('slice$i'),
            rect: Rect.fromCircle(
              center:
                  center +
                  Offset.fromDirection(
                    CircleGeometry.angleOf(i, count),
                    radius * CircleGeometry.label,
                  ),
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
      old.count != count ||
      old.activeCount != activeCount;
}
