using System;

namespace Gearbound.Core
{
    /// <summary>
    /// Shared <c>xorshift32-v1</c> generator. Shifts are 13/17/5, a zero seed is replaced by
    /// <see cref="ZeroSeedReplacement"/>, and every call consumes exactly one 32-bit draw.
    /// Verified against shared/test-fixtures/random_vectors.json.
    /// </summary>
    public sealed class SeededRandom
    {
        public const uint ZeroSeedReplacement = 0x9E3779B9u;
        public uint State { get; private set; }
        public int Draws { get; private set; }

        public SeededRandom(uint seed) => State = seed == 0 ? ZeroSeedReplacement : seed;

        public static SeededRandom FromState(uint state, int draws = 0)
        {
            if (state == 0) throw new ArgumentOutOfRangeException(nameof(state), "xorshift32 state can never be zero.");
            return new SeededRandom(state) { Draws = draws };
        }

        public uint NextUint()
        {
            var x = State;
            x ^= x << 13;
            x ^= x >> 17;
            x ^= x << 5;
            State = x;
            Draws++;
            return x;
        }

        /// <summary>
        /// murmur3 <c>fmix32</c> finalizer: the shared seed-derivation rule (flutter/lib/core/seeded_random.dart
        /// <c>mixSeed32</c>). Derive generator seeds from small or sequential integers with it; xorshift32's first
        /// outputs for small seeds are tiny and would always map to index 0. Vectors: shared/test-fixtures/workshop_cases.json.
        /// </summary>
        public static uint MixSeed32(uint seed)
        {
            var h = seed;
            h ^= h >> 16;
            h *= 0x85EBCA6Bu;
            h ^= h >> 13;
            h *= 0xC2B2AE35u;
            h ^= h >> 16;
            return h;
        }

        /// <summary>Multiply-shift mapping into [0, exclusiveMax). One draw, no rejection loop.</summary>
        public int NextInt(int exclusiveMax)
        {
            if (exclusiveMax < 1) throw new ArgumentOutOfRangeException(nameof(exclusiveMax));
            return (int)(((ulong)NextUint() * (ulong)exclusiveMax) >> 32);
        }
    }
}
