const DAMAGE = {
  red: { shield: 0.5, health: 1.2 },
  blue: { shield: 1.5, health: 0.75 },
  purple: { shield: 0.75, health: 0.75 },
  green: { shield: 0, health: 1.0 }
};

export class MiningResolver {
  constructor({ tileCooldownTicks = 10 } = {}) {
    this.tileCooldownTicks = tileCooldownTicks;
  }

  resolveShot({ energy, target, tick }) {
    const nextTarget = {
      weakness: [...(target.weakness ?? [])],
      shield: target.shield,
      health: target.health,
      disabledUntil: target.disabledUntil ?? -1
    };

    if (tick < nextTarget.disabledUntil) {
      return {
        outcome: "invalid_cooldown",
        damage: { shield: 0, health: 0 },
        target: nextTarget
      };
    }

    const base = DAMAGE[energy] ?? DAMAGE.red;
    const isNormal = nextTarget.weakness.length === 0;
    const isMatch = isNormal || nextTarget.weakness.includes(energy);
    const multiplier = isNormal ? 1 : isMatch ? 1.5 : null;
    const damage = multiplier
      ? {
          shield: base.shield * multiplier,
          health: base.health * multiplier
        }
      : {
          shield: 0.2,
          health: 0.5
        };

    if (nextTarget.shield > 0) {
      nextTarget.shield = Math.max(0, nextTarget.shield - damage.shield);
    } else {
      nextTarget.health = Math.max(0, nextTarget.health - damage.health);
    }

    nextTarget.disabledUntil = tick + this.tileCooldownTicks;

    return {
      outcome: isNormal ? "normal" : isMatch ? "match" : "mismatch",
      damage,
      target: nextTarget
    };
  }
}
