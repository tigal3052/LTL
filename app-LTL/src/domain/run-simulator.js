import { EnergyQueue } from "./energy-queue.js";
import { MiningResolver } from "./mining-resolver.js";
import { createSeededRng } from "./seeded-rng.js";
import { Telemetry } from "../telemetry/telemetry.js";
import { deriveActionResult } from "../action-result.js";

const ENERGIES = ["red", "blue", "purple", "green"];

export class RunSimulator {
  constructor({
    seed = 1,
    queueCapacity = 8,
    timeLimitTicks = 1200,
    node = { shield: 0.75, health: 0, weakness: ["red"] },
    stageIndex = 0,
    nodeType = "normal"
  } = {}) {
    this.seed = seed;
    this.rng = createSeededRng(seed);
    this.timeLimitTicks = timeLimitTicks;
    this.energyQueue = new EnergyQueue(queueCapacity);
    this.resolver = new MiningResolver();
    this.telemetry = new Telemetry({ runId: `seed-${seed}`, seed, stageIndex, nodeType });
    this.durabilityLossCount = 0;
    this.repairRequired = false;
    this.result = "running";
    this.tick = 0;
    this.targets = Array.from({ length: 30 }, () => ({
      weakness: [...(node.weakness ?? [])],
      shield: node.shield,
      health: node.health,
      disabledUntil: -1
    }));

    this.prefillQueue(queueCapacity);
  }

  prefillQueue(queueCapacity) {
    for (let i = 0; i < Math.min(queueCapacity, 4); i += 1) {
      this.energyQueue.push(ENERGIES[i % ENERGIES.length]);
    }
    this.telemetry.syncQueueStats(this.energyQueue);
  }

  applyInput(input) {
    this.tick = input.tick;

    if (this.result !== "running" || this.repairRequired || input.input !== "click") {
      return this.snapshot();
    }

    this.telemetry.increment("shots_fired");
    const targetIndex = input.target ?? 0;
    if (targetIndex < 0 || targetIndex >= this.targets.length) {
      this.telemetry.increment("invalid_target_inputs");
      const invalidSnapshot = this.snapshot();
      invalidSnapshot.action = deriveActionResult({
        beforeSummary: invalidSnapshot.summary,
        afterSummary: invalidSnapshot.summary,
        beforeRepairRequired: this.repairRequired,
        afterRepairRequired: this.repairRequired
      });
      invalidSnapshot.action.feedback = "invalid_target";
      return invalidSnapshot;
    }

    const energy = this.energyQueue.consume();

    if (!energy) {
      this.durabilityLossCount += 1;
      this.telemetry.increment("shots_fired_empty_queue");
      this.telemetry.increment("durability_loss_count");

      if (this.durabilityLossCount >= 3) {
        this.repairRequired = true;
        this.telemetry.increment("repair_count");
        this.telemetry.record("repair_started", { tick: input.tick });
      }

      this.evaluateResult(input.tick);
      return this.snapshot();
    }

    const resolved = this.resolver.resolveShot({
      energy,
      target: this.targets[targetIndex],
      tick: input.tick
    });
    this.targets[targetIndex] = resolved.target;

    if (resolved.outcome === "match" || resolved.outcome === "normal") {
      this.telemetry.increment("shots_hit_match");
    } else if (resolved.outcome === "mismatch") {
      this.telemetry.increment("shots_hit_mismatch");
    } else if (resolved.outcome === "invalid_cooldown") {
      this.telemetry.increment("shots_invalid_tile_cooldown");
    }

    this.telemetry.record("shot_resolved", {
      tick: input.tick,
      target: targetIndex,
      energy,
      outcome: resolved.outcome
    });
    this.telemetry.syncQueueStats(this.energyQueue);
    this.evaluateResult(input.tick);

    return this.snapshot();
  }

  evaluateResult(tick) {
    const cleared = this.targets.some((target) => target.shield <= 0 && target.health <= 0);
    if (cleared) {
      this.result = "clear";
      this.telemetry.set("result", "clear");
      this.telemetry.set("clear_time_sec", tick * 0.05);
      return;
    }

    if (tick >= this.timeLimitTicks) {
      this.result = "time_over";
      this.telemetry.set("result", "time_over");
      this.telemetry.set("fail_time_sec", tick * 0.05);
    }
  }

  run(inputLog = []) {
    for (const input of inputLog) {
      this.applyInput(input);
    }
    this.telemetry.syncQueueStats(this.energyQueue);
    return this.snapshot();
  }

  snapshot() {
    return {
      seed: this.seed,
      tick: this.tick,
      result: this.result,
      repairRequired: this.repairRequired,
      durabilityLossCount: this.durabilityLossCount,
      queue: this.energyQueue.snapshot(),
      targets: this.targets.map((target) => ({ ...target, weakness: [...target.weakness] })),
      summary: this.telemetry.summary()
    };
  }
}
