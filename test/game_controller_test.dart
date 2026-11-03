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

  /// Waits until the child's turn, from the start of a listening that
  /// began after [lead].
  void waitTurn(Duration lead, FakeAsync async) {
    async.elapse(
      lead +
          GameController.noteStep * (game.sequence.length - 1) +
          GameController.noteLit +
          GameController.handOver,
    );
  }

  /// Plays the whole sequence right.
  void repeat() {
    for (final n in game.sequence) {
      game.press(n);
      game.release(n);
    }
  }

  test('starts ready, and the middle plays a sequence of two', () {
    expect(game.phase, Phase.ready);
    expect(game.middleStarts, isTrue);
    expect(game.playable, isFalse);
    fakeAsync((async) {
      game.touchMiddle();
      expect(game.phase, Phase.listen);
      expect(game.middleStarts, isFalse);
      expect(game.sequence, hasLength(2));
      expect(game.shown, 0);
      waitTurn(GameController.leadIn, async);
      expect(game.phase, Phase.yourTurn);
      expect(game.playable, isTrue);
      expect(game.shown, 2);
      expect(player.played, game.sequence);
    });
  });

  test('two notes in a row are never the same', () {
    settings.startLength = 4;
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
      for (var i = 0; i < 7; i++) {
        game.press(i);
        game.release(i);
      }
      game.touchMiddle();
      expect(player.played, isEmpty);
      waitTurn(Duration.zero, async);
      expect(game.done, 0);
    });
  });

  test('a right sequence is not celebrated: one more note follows', () {
    fakeAsync((async) {
      game.touchMiddle();
      waitTurn(GameController.leadIn, async);
      final first = game.sequence;
      repeat();
      // Grey again at once, nothing lit but the note under the finger.
      expect(game.phase, Phase.listen);
      expect(game.playable, isFalse);
      expect(game.sequence, hasLength(3));
      expect(game.sequence.take(2), first);
      player.played.clear();
      waitTurn(GameController.betweenRounds, async);
      expect(player.played, game.sequence);
      expect(game.phase, Phase.yourTurn);
    });
  });

  test('a wrong note is silent and crossed; the middle replays it', () {
    fakeAsync((async) {
      game.touchMiddle();
      waitTurn(GameController.leadIn, async);
      final sequence = game.sequence;
      game.press(sequence.first);
      game.release(sequence.first);
      final wrong = (sequence[1] + 1) % 7;
      player.played.clear();
      game.press(wrong);
      expect(game.phase, Phase.oops);
      expect(game.wrong, wrong);
      expect(game.done, 1);
      expect(player.played, isEmpty);
      // Touches during the lock do nothing at all, the middle too.
      game.press(sequence[1]);
      game.touchMiddle();
      expect(player.played, isEmpty);
      expect(game.phase, Phase.oops);
      async.elapse(GameController.lockout);
      // Then it waits for the middle, with the cross still shown.
      expect(game.phase, Phase.again);
      expect(game.wrong, wrong);
      async.elapse(const Duration(seconds: 10));
      expect(game.phase, Phase.again);
      expect(player.played, isEmpty);
      game.touchMiddle();
      expect(game.phase, Phase.listen);
      expect(game.wrong, isNull);
      expect(game.sequence, sequence);
      waitTurn(GameController.leadIn, async);
      expect(player.played, sequence);
      expect(game.phase, Phase.yourTurn);
      expect(game.done, 0);
    });
  });

  test('from two to eight notes, then the celebration, then ready', () {
    expect(settings.longest, 8);
    fakeAsync((async) {
      game.touchMiddle();
      waitTurn(GameController.leadIn, async);
      while (game.sequence.length < 8) {
        repeat();
        expect(game.phase, Phase.listen);
        waitTurn(GameController.betweenRounds, async);
      }
      player.played.clear();
      repeat();
      expect(game.phase, Phase.success);
      expect(game.lit, {0, 1, 2, 3, 4, 5, 6});
      expect(player.played, hasLength(8));
      async.elapse(GameController.successHold);
      expect(game.phase, Phase.ready);
      expect(game.sequence, isEmpty);
      game.touchMiddle();
      expect(game.sequence, hasLength(2));
    });
  });

  test('only the slices lit are played', () {
    settings.activeCount = 3;
    settings.startLength = 4;
    fakeAsync((async) {
      game.touchMiddle();
      expect(game.sequence.every((n) => n < 3), isTrue);
      waitTurn(GameController.leadIn, async);
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
