import 'package:flame/components.dart';

/// Object pooling for game components.
///
/// Spawning a fresh obstacle or coin every few hundred milliseconds and
/// throwing it away when it leaves the screen creates a steady stream of
/// garbage, and the garbage collector pausing to clean it up is one source of
/// tiny frame hitches. A pool keeps removed components and hands them out
/// again, so after warm-up the game creates almost nothing during a run.
///
/// Usage: `pool.acquire()` → reset its state → `game.add(it)`.
/// When the component is removed from the game (off-screen, collected, run
/// reset), [Poolable] returns it to its pool automatically.
class ObjectPool<T extends Poolable> {
  final T Function() _create;
  final int maxSize;
  final List<T> _free = [];

  /// How many objects this pool has ever created (for debugging/tuning).
  int created = 0;

  ObjectPool(this._create, {this.maxSize = 40});

  /// A free object from the pool, or a new one if the pool is empty.
  T acquire() {
    final T item;
    if (_free.isNotEmpty) {
      item = _free.removeLast();
    } else {
      item = _create();
      created++;
    }
    item._pool = this;
    return item;
  }

  void _release(Poolable item) {
    // A component can be removed only once per use, but guard anyway so an
    // object can never be handed out twice at the same time.
    if (_free.length < maxSize && !_free.contains(item)) _free.add(item as T);
  }

  int get freeCount => _free.length;
}

/// Mix into a component so it returns to its [ObjectPool] when removed.
mixin Poolable on Component {
  ObjectPool? _pool;

  @override
  void onRemove() {
    super.onRemove();
    final pool = _pool;
    _pool = null;
    pool?._release(this);
  }
}
