// Renders the screen in a few states to PNG files, for looking at the
// design without a phone:
//   flutter test test_screenshots --update-goldens
// The images land in test_screenshots/goldens/ (not committed).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_round/app/rainbow_app.dart';
import 'package:rainbow_round/app/settings.dart';
import 'package:rainbow_round/audio/note_player.dart';
import 'package:rainbow_round/game/game_controller.dart';
import 'package:rainbow_round/game/notes.dart';
import 'package:rainbow_round/widgets/rainbow_circle.dart';

Future<void> loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(
      Future.value(ByteData.sublistView(File(f).readAsBytesSync())),
    );
  }
  await loader.load();
}

void main() {
  setUpAll(() async {
    await loadFont('Edwin', [
      'assets/fonts/Edwin-Roman.otf',
      'assets/fonts/Edwin-Bold.otf',
    ]);
    final sdk = File(Platform.resolvedExecutable)
        .parent
        .parent
        .parent
        .parent
        .parent
        .parent;
    await loadFont('MaterialIcons', [
      '${sdk.path}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ]);
  });

  Future<void> shoot(
    WidgetTester tester,
    String name,
    Future<void> Function(SilentNotePlayer player) steps, {
    AppSettings? settings,
    Size size = const Size(412, 915),
  }) async {
    tester.view.physicalSize = size * 2.625;
    tester.view.devicePixelRatio = 2.625;
    tester.platformDispatcher.localesTestValue = [const Locale('it')];
    addTearDown(tester.view.reset);
    final player = SilentNotePlayer();
    await tester.pumpWidget(
      RainbowApp(settings: settings ?? AppSettings(), player: player),
    );
    await tester.pump();
    await steps(player);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  }

  Offset sliceAt(WidgetTester tester, int note) {
    final box = tester.getRect(find.byType(RainbowCircle));
    return box.center +
        Offset.fromDirection(
          CircleGeometry.angleOf(note),
          box.width / 2 * CircleGeometry.label,
        );
  }

  testWidgets('ready', (tester) => shoot(tester, '1_ready', (_) async {}));

  testWidgets(
    'listen',
    (tester) => shoot(tester, '2_listen', (_) async {
      await tester.tapAt(tester.getCenter(find.byType(RainbowCircle)));
      await tester.pump(
        GameController.leadIn + GameController.noteStep + Durations.short1,
      );
    }),
  );

  testWidgets(
    'your turn',
    (tester) => shoot(tester, '3_your_turn', (player) async {
      await tester.tapAt(tester.getCenter(find.byType(RainbowCircle)));
      await tester.pump(const Duration(seconds: 3));
      final first = player.played.first;
      final g = await tester.startGesture(sliceAt(tester, first));
      await tester.pump(const Duration(milliseconds: 50));
      await g.up();
    }),
  );

  testWidgets(
    'oops',
    (tester) => shoot(tester, '4_oops', (player) async {
      await tester.tapAt(tester.getCenter(find.byType(RainbowCircle)));
      await tester.pump(const Duration(seconds: 3));
      final wrong = (player.played.first + 1) % 8;
      await tester.tapAt(sliceAt(tester, wrong));
      await tester.pump(const Duration(milliseconds: 120));
    }),
  );

  testWidgets(
    'success',
    (tester) => shoot(tester, '5_success', (player) async {
      await tester.tapAt(tester.getCenter(find.byType(RainbowCircle)));
      await tester.pump(const Duration(seconds: 3));
      for (final n in List.of(player.played)) {
        await tester.tapAt(sliceAt(tester, n));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(milliseconds: 1200));
    }),
  );

  testWidgets(
    'free with letters and four slices',
    (tester) => shoot(
      tester,
      '6_free',
      (_) async {
        await tester.startGesture(sliceAt(tester, 2));
        await tester.pump(const Duration(milliseconds: 50));
      },
      settings: AppSettings()
        ..mode = GameMode.free
        ..labels = NoteLabels.letters
        ..activeCount = 4,
    ),
  );

  testWidgets(
    'landscape',
    (tester) => shoot(tester, '7_landscape', (player) async {
      await tester.tapAt(tester.getCenter(find.byType(RainbowCircle)));
      await tester.pump(const Duration(seconds: 3));
    }, size: const Size(915, 412)),
  );

  testWidgets(
    'settings',
    (tester) => shoot(tester, '8_settings', (_) async {
      final g = await tester.startGesture(
        tester.getCenter(find.byIcon(Icons.settings_rounded)),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await g.up();
      await tester.pumpAndSettle();
    }),
  );
}
