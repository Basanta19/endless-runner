import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runner_rush/core/difficulty.dart';
import 'package:runner_rush/core/object_pool.dart';

class _TestComponent extends Component with Poolable {}

void main() {
  group('Dynamic difficulty (weighted average)', () {
    test('no history → normal difficulty', () {
      expect(DifficultyAdjuster.factorFor([]), 1.0);
    });

    test('repeated early deaths → easiest', () {
      expect(DifficultyAdjuster.factorFor([300, 500, 200, 400, 350]),
          DifficultyAdjuster.minFactor);
    });

    test('consistently long runs → hardest', () {
      expect(DifficultyAdjuster.factorFor([9000, 12000, 10000, 15000, 11000]),
          DifficultyAdjuster.maxFactor);
    });

    test('recent runs count more than old ones', () {
      // Same scores, opposite order: improving player vs declining player
      final improving = DifficultyAdjuster.factorFor([1000, 2000, 5000, 8000]);
      final declining = DifficultyAdjuster.factorFor([8000, 5000, 2000, 1000]);
      expect(improving, greaterThan(declining));
    });

    test('one lucky run does not max out difficulty', () {
      final f = DifficultyAdjuster.factorFor([1000, 1200, 900, 1100, 20000]);
      expect(f, lessThan(DifficultyAdjuster.maxFactor));
      expect(f, greaterThan(DifficultyAdjuster.minFactor));
    });

    test('weighted average math', () {
      // newest (2000) weight 1, older (1000) weight 0.8:
      // (2000*1 + 1000*0.8) / 1.8 = 1555.55…
      expect(DifficultyAdjuster.skillEstimate([1000, 2000]),
          closeTo(2800 / 1.8, 1e-9));
    });
  });

  group('Object pooling', () {
    testWithFlameGame('removed components are reused, not recreated',
        (game) async {
      final pool = ObjectPool<_TestComponent>(_TestComponent.new);

      final first = pool.acquire();
      await game.ensureAdd(first);
      expect(first.isMounted, isTrue);

      first.removeFromParent();
      game.update(0); // apply the removal
      expect(pool.freeCount, 1);

      final second = pool.acquire();
      expect(identical(first, second), isTrue); // same object recycled
      expect(pool.created, 1);

      await game.ensureAdd(second);
      expect(second.isMounted, isTrue); // re-added fine
    });

    test('never hands out the same object twice at once', () {
      final pool = ObjectPool<_TestComponent>(_TestComponent.new);
      final a = pool.acquire();
      final b = pool.acquire();
      expect(identical(a, b), isFalse);
      expect(pool.created, 2);
    });

    testWithFlameGame('pool size is capped', (game) async {
      final pool = ObjectPool<_TestComponent>(_TestComponent.new, maxSize: 2);

      final items = List.generate(4, (_) => pool.acquire());
      await game.ensureAddAll(items);
      for (final c in items) {
        c.removeFromParent();
      }
      game.update(0);
      expect(pool.freeCount, 2);
    });
  });
}
