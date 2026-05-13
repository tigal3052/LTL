export class SeededRng {
  constructor(seed) {
    this.state = seed >>> 0;
  }

  next() {
    this.state = (1664525 * this.state + 1013904223) >>> 0;
    return this.state / 0x100000000;
  }

  nextInt(maxExclusive) {
    if (maxExclusive <= 0) {
      throw new RangeError("maxExclusive must be greater than zero");
    }
    return Math.floor(this.next() * maxExclusive);
  }

  pick(values) {
    if (!values.length) {
      throw new RangeError("cannot pick from an empty array");
    }
    return values[this.nextInt(values.length)];
  }
}

export function createSeededRng(seed) {
  return new SeededRng(seed);
}
