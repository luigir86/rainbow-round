import 'dart:math' as math;

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_round/app/settings.dart';
import 'package:rainbow_round/audio/note_player.dart';
import 'package:rainbow_round/game/game_controller.dart';

void main() {
  late SilentNotePlayer player;
  late AppSettings settings;
  late GameController game;

  setUp(() {
    player = SilentNotePlayer();
    settings = AppSettings();
    game = GameController(
      player: player,
      settings: settings,
      random: math.Random(7),
    );
  });

  tearDown(() => game.dispose());

  /// Waits until the child's turn, from the start of a listening.
  void waitTurn(FakeAsync async) {
    async.elapse(
      GameController.leadIn +
          GameController.noteStep * (game.sequence.length - 1) +
          GameController.noteLit +
          GameController.handOver,
    );
  }

  test('starts ready, and the middle starts a sequence of two', () {
    expect(game.phase, Phase.ready);
    fakeAsync((async) {
      game.touchMiddle();
      expect(game.phase, Phase.listen);
      expect(game.sequence, hasLength(2));
      expect(game.shown, 0);
      waitTurn(async);
      expect(game.phase, Phase.yourTurn);
      expect(game.shown, 2);
      expect(player.played, game.sequence);
      expect(player.turns, 1);
      expect(game.cue, isTrue);
      async.elapse(GameController.cueLit);
      expect(game.cue, isFalse);
    });
  });

  test('two notes in a row are never the same', () {
    settings.startLength = 4;
    settings.longest = 12;
    fakeAsync((async) {
      game.touchMiddle();
      final s = game.sequence;
      for (var i = 1; i < s.length; i++) {
        expect(s[i], isNot(s[i - 1]));
      }
    });
  });

  test('touches while listening make no sound and are not kept', () {
    fakeAsync((async) {
      game.touchMiddle();
      async.elapse(GameController.leadIn);
      player.played.clear();
      for (var i = 0; i < 8; i++) {
        game.press(i);
        game.release(i);
      }
      expect(player.played, isEmpty);
      waitTurn(async);
      expect(game.done, 0);
    });
  });

  test('the right sequence is celebrated, then grows by one', () {
    fakeAsync((async) {
      game.touchMiddle();
      waitTurn(async);
      final first = game.sequence;
      for (final n in first) {
        game.press(n);
        game.release(n);
      }
      expect(game.done, 2);
      player.played.clear();
      async.elapse(GameController.beforeSuccess);
      expect(game.phase, Phase.success);
      async.elapse(GameController.arpeggioStep * 8);
      // The arpeggio goes up every lit slice.
      expect(player.played, [0, 1, 2, 3, 4, 5, 6, 7]);
      async.elapse(GameController.successHold);
      expect(game.phase, Phase.listen);
      expect(game.sequence, hasLength(3));
      expect(game.sequence.take(2), first);
    });
  });

  test('a wrong note locks the circle, then the sequence is heard again', () {
    fakeAsync((async) {
      game.touchMiddle();
      waitTurn(async);
      final sequence = game.sequence;
      final wrong = (sequence.first + 1) % 8;
      game.press(wrong);
      expect(game.phase, Phase.oops);
      expect(game.wrong, wrong);
      expect(player.oopses, 1);
      player.played.clear();
      // Touches during the lock do nothing at all.
      game.press(sequence.first);
      game.press(wrong);
      expect(player.played, isEmpty);
      expect(player.oopses, 1);
      async.elapse(GameController.lockout);
      expect(game.phase, Phase.listen);
      expect(game.sequence, sequence);
      waitTurn(async);
      expect(game.phase, Phase.yourTurn);
      expect(game.done, 0);
    });
  });

  test('after the longest sequence the game asks for another', () {
    settings.startLength = 4;
    settings.longest = 4;
    fakeAsync((async) {
      game.touchMiddle();
      waitTurn(async);
      for (final n in game.sequence) {
        game.press(n);
      }
      async.elapse(const Duration(seconds: 5));
      expect(game.phase, Phase.finished);
      game.touchMiddle();
      expect(game.phase, Phase.listen);
      expect(game.sequence, hasLength(4));
    });
  });

  test('only the slices lit are played', () {
    settings.activeCount = 3;
    settings.startLength = 4;
    settings.longest = 12;
    fakeAsync((async) {
      game.touchMiddle();
      expect(game.sequence.every((n) => n < 3), isTrue);
      waitTurn(async);
      player.played.clear();
      game.press(5);
      expect(game.phase, Phase.yourTurn);
      expect(player.played, isEmpty);
    });
  });

  test('free play: every touch sounds, several fingers at once', () {
    settings.mode = GameMode.free;
    expect(game.phase, Phase.free);
    fakeAsync((async) {
      game.press(0);
      game.press(2);
      game.press(4);
      expect(player.played, [0, 2, 4]);
      expect(game.lit, {0, 2, 4});
      game.release(2);
      async.elapse(GameController.touchLit);
      expect(game.lit, {0, 4});
      game.touchMiddle();
      expect(game.phase, Phase.free);
    });
  });

  test('changing the mode stops the game', () {
    fakeAsync((async) {
      game.touchMiddle();
      async.elapse(GameController.leadIn);
      settings.mode = GameMode.free;
      expect(game.phase, Phase.free);
      player.played.clear();
      async.elapse(const Duration(seconds: 10));
      expect(player.played, isEmpty);
    });
  });
}
