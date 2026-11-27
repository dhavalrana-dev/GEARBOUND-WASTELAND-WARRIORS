/// Shared `xorshift32-v1` generator (shifts 13/17/5). A zero seed is replaced
/// by [zeroSeedReplacement] and every call consumes exactly one 32-bit draw.
///
/// Uses 64-bit integer arithmetic: valid on the Dart VM and AOT targets
/// (Android/iOS/desktop). Web builds would need a BigInt or split-multiply
/// variant and are not configured for this project.
class SeededRandom {
  SeededRandom(int seed) : _state = _initial(seed & _mask);

  static const zeroSeedReplacement = 0x9E3779B9;
  static const _mask = 0xFFFFFFFF;

  int _state;
  int draws = 0;
  int get state => _state;

  static int _initial(int seed) => seed == 0 ? zeroSeedReplacement : seed;

  int nextUint() {
    var x = _state;
    x ^= (x << 13) & _mask;
    x ^= x >> 17;
    x ^= (x << 5) & _mask;
    _state = x & _mask;
    draws++;
    return _state;
  }

  /// Multiply-shift mapping into `[0, exclusiveMax)`; no rejection loop.
  int nextInt(int exclusiveMax) {
    if (exclusiveMax < 1 || exclusiveMax > 0x7FFFFFFF) {
      throw RangeError.range(exclusiveMax, 1, 0x7FFFFFFF, 'exclusiveMax');
    }
    return (nextUint() * exclusiveMax) >> 32;
  }
}

/// murmur3 `fmix32` finalizer. Use it to derive a generator seed from small or
/// sequential integers: xorshift32's first outputs for small seeds are tiny
/// (seed 1 → 270369), which multiply-shift maps to index 0 almost every time.
/// Shared seed-derivation rule; Unity must use the same function.
int mixSeed32(int seed) {
  var h = seed & 0xFFFFFFFF;
  h ^= h >> 16;
  h = (h * 0x85EBCA6B) & 0xFFFFFFFF;
  h ^= h >> 13;
  h = (h * 0xC2B2AE35) & 0xFFFFFFFF;
  h ^= h >> 16;
  return h;
}
