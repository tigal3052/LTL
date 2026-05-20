const DEFAULT_QUEUE = ["red", "blue", "purple", "green"];

function clone(value) {
  return value == null ? value : JSON.parse(JSON.stringify(value));
}

function consumeDamage(nodeState, damage) {
  let remaining = damage;
  const next = { ...nodeState };

  if (next.shield > 0) {
    const shieldDamage = Math.min(next.shield, remaining);
    next.shield -= shieldDamage;
    remaining -= shieldDamage;
  }

  if (remaining > 0) {
    next.health = Math.max(0, next.health - remaining);
  }

  return next;
}

export class RunSimulator {
  constructor({
    seed = 1,
    queueCapacity = 8,
    timeLimitTicks = 1200,
    node = { shield: 1, health: 1, weakness: ["red"] },
    initialQueue = null,
    stageIndex = 0,
    nodeType = "normal"
  } = {}) {
    this.seed = seed >>> 0;
    this.tick = 0;
    this.timeLimitTicks = timeLimitTicks;
    this.stageIndex = stageIndex;
    this.nodeType = nodeType;
    this.queue = Array.isArray(initialQueue)
      ? [...initialQueue]
      : DEFAULT_QUEUE.slice(0, Math.max(0, Math.min(queueCapacity, DEFAULT_QUEUE.length)));
    this.queueCapacity = queueCapacity;
    this.nodeState = {
      shield: node.shield,
      health: node.health,
      weakness: [...(node.weakness ?? [])],
      disabledUntil: 0
    };
    this.result = "active";
    this.repairRequired = false;
    this.durabilityLossCount = 0;
    this.summary = {
      result: "active",
      shots_fired: 0,
      shots_hit_match: 0,
      shots_hit_normal: 0,
      shots_hit_mismatch: 0,
      shots_fired_empty_queue: 0,
      shots_invalid_target: 0,
      durability_loss_count: 0,
      node_type: nodeType
    };
  }

  snapshot() {
    return {
      seed: this.seed,
      tick: this.tick,
      result: this.result,
      repairRequired: this.repairRequired,
      durabilityLossCount: this.durabilityLossCount,
      queue: {
        items: [...this.queue]
      },
      targets: [
        {
          weakness: [...this.nodeState.weakness],
          shield: this.nodeState.shield,
          health: this.nodeState.health,
          disabledUntil: this.nodeState.disabledUntil
        }
      ],
      summary: clone(this.summary)
    };
  }

  applyInput(input) {
    if (this.result === "clear" || this.result === "time_over" || this.repairRequired) {
      return this.snapshot();
    }

    this.tick = Math.max(this.tick, input.tick ?? this.tick);

    if (input.input === "click") {
      if ((input.target ?? 0) !== 0) {
        this.summary.shots_invalid_target += 1;
      } else if (this.queue.length === 0) {
        this.summary.shots_fired_empty_queue += 1;
        this.durabilityLossCount += 1;
        this.summary.durability_loss_count = this.durabilityLossCount;
        if (this.durabilityLossCount >= 3) {
          this.repairRequired = true;
        }
      } else {
        const energy = this.queue.shift();
        this.summary.shots_fired += 1;
        let damage = 0.5;

        if (this.nodeState.weakness.includes(energy)) {
          damage = 10;
          this.summary.shots_hit_match += 1;
        } else if (this.nodeState.weakness.length === 0) {
          this.summary.shots_hit_normal += 1;
        } else {
          damage = 0.25;
          this.summary.shots_hit_mismatch += 1;
        }

        this.nodeState = consumeDamage(this.nodeState, damage);
        if (this.nodeState.shield <= 0 && this.nodeState.health <= 0) {
          this.result = "clear";
        }
      }
    }

    if (this.result !== "clear" && !this.repairRequired && this.tick >= this.timeLimitTicks) {
      this.result = "time_over";
    }

    if (this.repairRequired) {
      this.result = "repair_required";
    }

    this.summary.result = this.result;
    return this.snapshot();
  }
}
