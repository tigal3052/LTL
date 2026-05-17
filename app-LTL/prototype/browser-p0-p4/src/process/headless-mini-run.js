import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

import { RunSimulator } from "../models/combat-simulator.js";
import { offerNodeChoices } from "../vocabulary/node/offer-node-choices.js";
import { rollStageRewards } from "../vocabulary/reward/roll-stage-rewards.js";

const __dirname = dirname(fileURLToPath(import.meta.url));

function loadDefaultNodeTable() {
  const path = join(__dirname, "../data/node-table.json");
  return JSON.parse(readFileSync(path, "utf8"));
}

/**
 * Headless mini-run (RunSimulator). UI browser combat uses phases + vocabulary/combat/*.
 */
export class HeadlessMiniRun {
  constructor({
    seed = 1,
    maxStages = 5,
    queueCapacity = 8,
    nodeTable = null,
    nodeTablePath = null,
    scalingOverrides = {}
  } = {}) {
    this.seed = seed >>> 0;
    this.maxStages = maxStages;
    this.queueCapacity = queueCapacity;
    this.scalingOverrides = scalingOverrides;
    this.nodeTable =
      nodeTable ?? (nodeTablePath ? JSON.parse(readFileSync(nodeTablePath, "utf8")) : loadDefaultNodeTable());

    this.phase = "node_select";
    this.combatStageIndex = 0;
    this.candidates = offerNodeChoices({
      seed: this.seed,
      stageIndex: this.combatStageIndex,
      table: this.nodeTable,
      scalingOverrides: this.scalingOverrides
    });
    this.pendingRewards = [];
    this.lastClearedWeaknesses = [];
    this.simulator = null;
    this.selectedNodeId = null;
    this.runComplete = false;
    this.failed = false;
    this.history = [];
  }

  snapshot() {
    return {
      seed: this.seed,
      phase: this.phase,
      combatStageIndex: this.combatStageIndex,
      maxStages: this.maxStages,
      candidates: this.candidates.map((c) => ({ ...c, combat: { ...c.combat, weakness: [...c.combat.weakness] } })),
      pendingRewards: this.pendingRewards.map((r) => ({ ...r })),
      lastClearedWeaknesses: [...this.lastClearedWeaknesses],
      selectedNodeId: this.selectedNodeId,
      runComplete: this.runComplete,
      failed: this.failed,
      combat: this.simulator ? this.simulator.snapshot() : null
    };
  }

  selectNode(candidateIndex) {
    if (this.phase !== "node_select" || this.runComplete || this.failed) {
      return this.snapshot();
    }
    const choice = this.candidates[candidateIndex];
    if (!choice) {
      return this.snapshot();
    }

    this.selectedNodeId = choice.id;
    this.simulator = new RunSimulator({
      seed: this.seed + this.combatStageIndex * 1315423911,
      queueCapacity: this.queueCapacity,
      timeLimitTicks: choice.combat.timeLimitTicks,
      node: {
        shield: choice.combat.shield,
        health: choice.combat.health,
        weakness: choice.combat.weakness
      },
      stageIndex: this.combatStageIndex,
      nodeType: choice.id
    });

    this.phase = "combat";
    this.history.push({ event: "node_selected", combatStageIndex: this.combatStageIndex, nodeId: choice.id });
    return this.snapshot();
  }

  applyCombatInput(input) {
    if (this.phase !== "combat" || !this.simulator) {
      return this.snapshot();
    }

    const snap = this.simulator.applyInput(input);
    if (snap.result === "clear") {
      this.lastClearedWeaknesses = [...(this.simulator.targets[0]?.weakness ?? [])];
      this.pendingRewards = rollStageRewards({
        seed: this.seed + this.combatStageIndex * 0x85ebca6b,
        clearedWeaknesses: this.lastClearedWeaknesses
      });
      this.phase = "reward";
      this.history.push({ event: "stage_cleared", combatStageIndex: this.combatStageIndex });
    } else if (snap.result === "time_over" || snap.repairRequired) {
      this.failed = true;
      this.phase = "failed";
      this.history.push({ event: "stage_failed", combatStageIndex: this.combatStageIndex });
    }

    return this.snapshot();
  }

  claimRewards() {
    if (this.phase !== "reward" || this.runComplete || this.failed) {
      return this.snapshot();
    }

    this.history.push({
      event: "rewards_claimed",
      combatStageIndex: this.combatStageIndex,
      rewards: this.pendingRewards.map((r) => ({ ...r }))
    });
    this.pendingRewards = [];

    const clearedFinalStage = this.combatStageIndex >= this.maxStages - 1;
    if (clearedFinalStage) {
      this.runComplete = true;
      this.phase = "run_complete";
      this.candidates = [];
      this.simulator = null;
      this.history.push({ event: "run_complete" });
      return this.snapshot();
    }

    this.combatStageIndex += 1;
    this.phase = "node_select";
    this.candidates = offerNodeChoices({
      seed: this.seed,
      stageIndex: this.combatStageIndex,
      table: this.nodeTable,
      scalingOverrides: this.scalingOverrides
    });
    this.simulator = null;
    return this.snapshot();
  }
}

/** @deprecated import from process/headless-mini-run.js */
export { HeadlessMiniRun as RunProgression };
