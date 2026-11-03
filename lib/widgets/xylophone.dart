import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../app/style.dart';
import '../app/theme.dart';
import '../game/game_controller.dart';
import '../game/notes.dart';
import 'instrument.dart';

/// Where the parts of the xylophone are, in a space of a given size.
class XylophoneGeometry {
  XylophoneGeometry(this.size, this.count);

  final Size size;
  final int count;

  /// The strip over the bars that shows the state and starts a game.
  late final double strip = (size.height * 0.18).clamp(64.0, 110.0);

  /// The button in the middle of the strip.
  late final Rect button = Rect.fromCenter(
    center: Offset(size.width / 2, strip / 2),
    width: math.min(size.width * 0.45, 200.0),
    height: strip * 0.8,
  );

  /// Where the bars begin, under the strip.
  late final double top = strip + 16;

  late final double gap = math.max(4.0, size.width * 0.015);
  late final double barWidth = (size.width - gap * (count - 1)) / count;

  /// The longest bar (the low C) fills the height; each one after is a
  /// little shorter, down to 70 % for the last, as on a real xylophone.
  static const shortest = 0.7;

  /// Bar [i], [grow] times longer than at rest, centred on its column.
  Rect bar(int i, {double grow = 1}) {
    final room = size.height - top;
    final f = count < 2 ? 1.0 : 1 - (1 - shortest) * i / (count - 1);
    final h = room * f * grow;
    final x = i * (barWidth + gap);
    return Rect.fromLTWH(x, top + (room - h) / 2, barWidth, h);
  }

  /// What is under [point]: a bar, the button (-1), or nothing (null). A
  /// touch anywhere in a bar's column counts, above or below it too.
  int? hit(Offset point) {
    if (button.contains(point)) return -1;
    if (point.dy < top || point.dy > size.height) return null;
    if (point.dx < 0 || point.dx > size.width) return null;
    return (point.dx / (barWidth + gap)).floor().clamp(0, count - 1);
  }
}

/// The xylophone: seven bars from C to B, low on the left and high on
/// the right, under a strip that shows the state. Every finger counts at
/// once, so several bars make a chord.
class Xylophone extends InstrumentView {
  const Xylophone({
    super.key,
    required super.game,
    required super.labels,
    required super.spokenLabels,
  });

  @override
  State<Xylophone> createState() => _XylophoneState();
}

class _XylophoneState extends InstrumentViewState<Xylophone> {
  @override
  int? hitAt(Offset point, Size size) =>
      XylophoneGeometry(size, widget.game.noteCount).hit(point);

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final colors = RoundColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final geometry = XylophoneGeometry(size, game.noteCount);
        return touches(
          size,
          Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(
                child: CustomPaint(
                  painter: _XylophonePainter(
                    geometry: geometry,
                    fills: [
                      for (var i = 0; i < game.noteCount; i++)
                        noteColor(i, colors),
                    ],
                    middle: middleColor(context),
                    text: Theme.of(context).textTheme.headlineSmall!
                        .copyWith(fontWeight: FontWeight.w700),
                    textScaler: MediaQuery.textScalerOf(context),
                    game: game,
                    activeCount: game.activeCount,
                    labels: widget.labels,
                    spokenLabels: widget.spokenLabels,
                  ),
                ),
              ),
              Positioned.fromRect(
                rect: geometry.button,
                child: Center(
                  child: stateIcon(context, geometry.button.height * 0.62),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _XylophonePainter extends CustomPainter {
  _XylophonePainter({
    required this.geometry,
    required this.fills,
    required this.middle,
    required this.text,
    required this.textScaler,
    required this.game,
    required this.activeCount,
    required this.labels,
    required this.spokenLabels,
  });

  final XylophoneGeometry geometry;
  final List<Color> fills;

  /// The colour of the button of the state now.
  final Color middle;
  final TextStyle text;
  final TextScaler textScaler;
  final GameController game;
  final int activeCount;
  final NoteLabels labels;
  final NoteLabels spokenLabels;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(
      math.min(RoundShape.radius, geometry.barWidth * 0.3),
    );

    // The button of the state.
    final button = RRect.fromRectAndRadius(
      geometry.button,
      Radius.circular(geometry.button.height / 2),
    );
    canvas.drawRRect(button, Paint()..color = middle);

    for (var i = 0; i < geometry.count; i++) {
      final active = game.isActive(i);
      final on = active && game.lit.contains(i);
      final rect = geometry.bar(i, grow: on ? 1.04 : 1);
      final bar = RRect.fromRectAndRadius(rect, radius);
      canvas.drawRRect(bar, Paint()..color = fills[i]);

      final name = labels.shownName(i);
      if (active && name != null) {
        final painter = TextPainter(
          text: TextSpan(
            text: name,
            style: text.copyWith(color: RoundColors.inkOn(fills[i])),
          ),
          textDirection: TextDirection.ltr,
          textScaler: textScaler,
        )..layout();
        // A name that would not fit the bar shrinks, never past the
        // smallest size of the app.
        final room = geometry.barWidth * 0.7;
        if (painter.width > room) {
          final scale = math.max(room / painter.width, RoundType.small / 24);
          painter.textScaler = TextScaler.linear(textScaler.scale(1) * scale);
          painter.layout();
        }
        painter.paint(
          canvas,
          Offset(
            rect.center.dx - painter.width / 2,
            rect.bottom - rect.height * 0.2 - painter.height / 2,
          ),
        );
      }
    }
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder =>
      (size) => [
        for (var i = 0; i < geometry.count; i++)
          if (game.isActive(i))
            CustomPainterSemantics(
              key: ValueKey('bar$i'),
              rect: geometry.bar(i),
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

  @override
  bool shouldRepaint(_XylophonePainter old) => true;

  @override
  bool shouldRebuildSemantics(_XylophonePainter old) =>
      old.spokenLabels != spokenLabels ||
      old.game != game ||
      old.geometry.size != geometry.size ||
      old.activeCount != activeCount;
}
