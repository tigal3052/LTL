export class EnergyQueue {
  constructor(capacity = 8) {
    this.capacity = capacity;
    this.items = [];
    this.stats = {
      generated: 0,
      consumed: 0,
      wasted: 0
    };
  }

  push(energy) {
    this.stats.generated += 1;

    if (this.items.length >= this.capacity) {
      this.stats.wasted += 1;
      return false;
    }

    this.items.push(energy);
    return true;
  }

  consume() {
    if (this.items.length === 0) {
      return null;
    }

    this.stats.consumed += 1;
    return this.items.shift();
  }

  snapshot() {
    return {
      capacity: this.capacity,
      items: [...this.items],
      stats: { ...this.stats }
    };
  }
}
