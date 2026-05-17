import { createSeededRng } from "./seeded-rng.js";
import { deriveActionResult } from "../action-result.js";
import { InventoryModel } from "./inventory-model.js";
import { createCombatRuntime } from "../vocabulary/combat/create-combat-runtime.js";
import { fireShot, tickCombat } from "../vocabulary/combat/fire-shot.js";

const ENERGIES = ["red", "blue", "purple", "green"];

export class RunSimulator {
  constructor({
    seed = 1,
    queueCapacity = 8,
    timeLimitTicks = 1200,
    node = { shield: 0.75, health: 0, weakness: ["red"] },
    stageIndex = 0,
    nodeType = "normal",
    inventory = null
  } = {}) {
    this.seed = seed;
    this.rng = createSeededRng(seed);
    this.timeLimitTicks = timeLimitTicks;
    this.node = {
      shield: node.shield,
      health: node.health,
      weakness: [...(node.weakness ?? [])]
    };
    this.stageIndex = stageIndex;
    this.nodeType = nodeType;
    this.inventory = inventory ?? new InventoryModel(8, 8);
    this.ticksPerSecond = 1;
    this.pickColor = () => ENERGIES[this.rng.nextInt(ENERGIES.length)];

    const initialQueue = [];
    for (let i = 0; i < Math.min(queueCapacity, 4); i += 1) {
      initialQueue.push(ENERGIES[i % ENERGIES.length]);
    }

    this.combat = createCombatRuntime({
      display: {
        runMaxShield: node.shield,
        runMaxHp: node.health,
        timeRemaining: timeLimitTicks
      },
      seed,
      stageIndex,
      queueCapacity,
      initialQueue,
      gameStarted: true,
      ticksPerSecond: this.ticksPerSecond,
      timeProgressEveryTicks: 1,
      terrainScrollEveryTicks: 20,
      nodeWeakness: this.node.weakness,
      nodeType,
      pickColor: this.pickColor
    });
    this.energyQueue = {
      push: (energy) => {
        if (this.combat.queue.length >= this.combat.queueCapacity) {
          return false;
        }
        this.combat.queue.push(energy);
        return true;
      },
      consume: () => this.combat.queue.shift() ?? null,
      snapshot: () => [...this.combat.queue]
    };
    this.syncCompatState();
  }

  syncCompatState() {
    const snapshot = this.snapshot();
    this.tick = snapshot.tick;
    this.result = snapshot.result;
    this.repairRequired = snapshot.repairRequired;
    this.durabilityLossCount = snapshot.durabilityLossCount;
    this.targets = snapshot.targets;
  }

  advanceTicks(targetTick) {
    while (this.combat.tick < targetTick) {
      const beforeTick = this.combat.tick;
      const next = tickCombat(this.combat, this.inventory, {
        ticksPerSecond: this.ticksPerSecond,
        pickColor: this.pickColor
      });
      this.combat = next.combat;
      if (this.combat.tick === beforeTick) {
        break;
      }
    }
    this.syncCompatState();
  }

  applyInput(input) {
    this.advanceTicks(input.tick);

    const beforeSummary = { ...this.combat.summary };
    const beforeRepairRequired = this.combat.repairRequired;

    if (input.input === "click") {
      const result = fireShot(this.combat, input.target ?? 0);
      this.combat = result.combat;
    }

    const snapshot = this.snapshot();
    this.syncCompatState();
    snapshot.action = deriveActionResult({
      beforeSummary,
      afterSummary: snapshot.summary,
      beforeRepairRequired,
      afterRepairRequired: snapshot.repairRequired,
      attemptedInput: input.input
    });
    return snapshot;
  }

  run(inputLog = []) {
    for (const input of inputLog) {
      this.applyInput(input);
    }
    this.syncCompatState();
    return this.snapshot();
  }

  snapshot() {
    const summary = {
      ...this.combat.summary,
      node_type: this.nodeType
    };
    return {
      seed: this.seed,
      tick: this.combat.tick,
      result: summary.result,
      repairRequired: this.combat.repairRequired,
      durabilityLossCount: summary.durability_loss_count,
      queue: {
        items: [...this.combat.queue]
      },
      targets: Array.from({ length: 30 }, (_, index) => ({
        weakness: [...this.node.weakness],
        shield: this.combat.nodeShield,
        health: this.combat.nodeHp,
        disabledUntil: this.combat.disabledUntil[index]
      })),
      summary
    };
  }
}
