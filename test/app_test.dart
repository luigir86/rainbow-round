import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_round/app/rainbow_app.dart';
import 'package:rainbow_round/app/settings.dart';
import 'package:rainbow_round/app/settings_page.dart';
import 'package:rainbow_round/audio/note_player.dart';
import 'package:rainbow_round/game/game_controller.dart';
import 'package:rainbow_round/widgets/rainbow_circle.dart';
import 'package:rainbow_round/widgets/xylophone.dart';

void main() {
  Future<SilentNotePlayer> pumpApp(
    WidgetTester tester, {
    AppSettings? settings,
    Locale locale = const Locale('it'),
  }) async {
    tester.platformDispatcher.localesTestValue = [locale];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final player = SilentNotePlayer();
    await tester.pumpWidget(
      RainbowApp(settings: settings ?? AppSettings(), player: player),
    );
    await tester.pump();
    return player;
  }

  /// The middle of slice [note] on screen.
  Offset sliceAt(WidgetTester tester, int note) {
    final box = tester.getRect(find.byType(RainbowCircle));
    final a = CircleGeometry.angleOf(note, 7);
    final r = box.width / 2 * CircleGeometry.label;
    return box.center + Offset.fromDirection(a, r);
  }

  testWidgets('every slice is found where it is drawn', (tester) async {
    const size = Size(300, 300);
    for (final count in const [7, 8]) {
      for (var i = 0; i < count; i++) {
        final a = CircleGeometry.angleOf(i, count);
        final p = size.center(Offset.zero) + Offset.fromDirection(a, 100);
        expect(CircleGeometry.hit(p, size, count), i);
      }
    }
    expect(CircleGeometry.hit(size.center(Offset.zero), size, 7), -1);
    expect(CircleGeometry.hit(Offset.zero, size, 7), isNull);
  });

  testWidgets('every bar of the xylophone is found where it is drawn', (
    tester,
  ) async {
    final geometry = XylophoneGeometry(const Size(400, 300), 8);
    for (var i = 0; i < 8; i++) {
      expect(geometry.hit(geometry.bar(i).center), i);
    }
    expect(geometry.hit(geometry.button.center), -1);
    // The high C is the shortest bar.
    expect(geometry.bar(7).height, lessThan(geometry.bar(0).height));
  });

  testWidgets('shows the note names in Italian', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(tester);
    expect(find.semantics.byLabel('Sol'), findsOne);
    expect(find.semantics.byLabel('Inizia'), findsOne);
    semantics.dispose();
  });

  testWidgets('free play: a touch on a slice plays its note', (tester) async {
    final settings = AppSettings()..mode = GameMode.free;
    final player = await pumpApp(tester, settings: settings);
    await tester.tapAt(sliceAt(tester, 4));
    await tester.tapAt(sliceAt(tester, 6));
    expect(player.played, [4, 6]);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('the circle has seven slices, the xylophone eight bars', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final settings = AppSettings()
      ..mode = GameMode.free
      ..activeCount = 8;
    await pumpApp(tester, settings: settings);
    expect(find.semantics.byLabel('Si'), findsOne);
    expect(find.semantics.byLabel('Do'), findsOne);
    settings.instrument = Instrument.xylophone;
    await tester.pump();
    expect(find.byType(Xylophone), findsOneWidget);
    expect(find.semantics.byLabel('Do'), findsNWidgets(2));
    semantics.dispose();
  });

  testWidgets('xylophone: a touch on a bar plays its note', (tester) async {
    final settings = AppSettings()
      ..mode = GameMode.free
      ..instrument = Instrument.xylophone
      ..activeCount = 8;
    final player = await pumpApp(tester, settings: settings);
    final box = tester.getRect(find.byType(Xylophone));
    final geometry = XylophoneGeometry(box.size, 8);
    await tester.tapAt(box.topLeft + geometry.bar(0).center);
    await tester.tapAt(box.topLeft + geometry.bar(7).center);
    expect(player.played, [0, 7]);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a game: listen, repeat, well done', (tester) async {
    final player = await pumpApp(tester);
    final circle = tester.getRect(find.byType(RainbowCircle));
    await tester.tapAt(circle.center);
    await tester.pump(const Duration(seconds: 3));
    expect(find.byIcon(Icons.back_hand_rounded), findsOneWidget);
    final sequence = List.of(player.played);
    expect(sequence, hasLength(2));
    for (final n in sequence) {
      await tester.tapAt(sliceAt(tester, n));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(GameController.beforeSuccess);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('the gear opens the settings only when held', (tester) async {
    await pumpApp(tester);
    final gear = find.byIcon(Icons.settings_rounded);
    await tester.tap(gear);
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsNothing);
    final gesture = await tester.startGesture(tester.getCenter(gear));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2100));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
    await tester.tap(find.text('Gioco libero'));
    await tester.pumpAndSettle();
    expect(find.text('Gioco libero'), findsOneWidget);
  });

  testWidgets('fits a small phone, in both orientations, with large text', (
    tester,
  ) async {
    for (final instrument in Instrument.values) {
      for (final size in const [Size(360, 640), Size(640, 360)]) {
        tester.view.physicalSize = size * 3;
        tester.view.devicePixelRatio = 3;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        await pumpApp(tester, settings: AppSettings()..instrument = instrument);
        expect(tester.takeException(), isNull);
      }
    }
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  });
}
