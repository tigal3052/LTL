function hashSeed(seed) {
  let state = seed >>> 0;
  return () => {
    state = (state + 0x6d2b79f5) >>> 0;
    let t = Math.imul(state ^ (state >>> 15), 1 | state);
    t ^= t + Math.imul(t ^ (t >>> 7), 61 | t);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

export function createSeededRng(seed = 1) {
  const nextFloat = hashSeed(seed >>> 0);

  return {
    next() {
      return nextFloat();
    },
    nextInt(maxExclusive) {
      if (!Number.isInteger(maxExclusive) || maxExclusive <= 0) {
        throw new RangeError("nextInt requires a positive integer maxExclusive.");
      }
      return Math.floor(nextFloat() * maxExclusive);
    }
  };
}
