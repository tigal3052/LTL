import { generateNodeCandidates } from "../domain/node-generator.js";
import {
  createStarterInventory,
  discardHeldArtifact as discardHeldInventoryArtifact,
  pickUpPlacedArtifact as pickUpInventoryArtifact,
  placeHeldArtifact as placeHeldInventoryArtifact
} from "../domain/inventory-model.js";
import { resolveStageRewards } from "../domain/reward-resolver.js";
import { RunSimulator } from "../domain/run-simulator.js";
import { createReplaySummary, createRunSnapshot } from "../domain/snapshot.js";
import { loadArtifactTable } from "../loaders/artifact-loader.js";
import { loadLeviathanTable } from "../loaders/leviathan-loader.js";
import { loadNodeTable } from "../loaders/node-loader.js";
import { loadProgressData } from "../loaders/progress-loader.js";
import { loadRewardTable } from "../loaders/reward-loader.js";

function assertLoaded(loaderName, result) {
  if (!result.ok) {
    const message = result.errors?.[0]?.message ?? `${loaderName} failed validation.`;
    throw new Error(message);
  }
  return result.facts;
}

function normalizeConfig(config = {}) {
  return {
    artifacts: assertLoaded("artifacts", loadArtifactTable({ input: config.artifacts, source: "artifacts" })),
    nodes: assertLoaded("nodes", loadNodeTable({ input: config.nodes, source: "nodes" })),
    rewards: assertLoaded("rewards", loadRewardTable({ input: config.rewards, source: "rewards" })),
    leviathans: assertLoaded("leviathans", loadLeviathanTable({ input: config.leviathans, source: "leviathans" })),
    progress: assertLoaded("progress", loadProgressData({ input: config.progress, source: "progress" }))
  };
}

export class HeadlessMiniRun {
  constructor(config = {}) {
    const data = normalizeConfig(config);
    const leviathan =
      data.leviathans.leviathans.find((entry) => entry.id === config.leviathanId) ??
      data.leviathans.leviathans[0];

    this.seed = config.seed ?? 1;
    this.leviathanId = leviathan.id;
    this.maxStages = config.stageCount ?? leviathan.stageCnt;
    this.maxRuns = config.runCount ?? leviathan.runCnt;
    this.runIndex = config.runIndex ?? 0;
    this.stageIndex = 0;
    this.queueCapacity = config.queueCapacity ?? 8;
    this.initialQueue = config.initialQueue ?? null;
    this.scalingOverrides = config.scalingOverrides ?? {};
    this.data = data;
    this.phase = "node_select";
    this.inventory = createStarterInventory(data.artifacts, config.initialInventory ?? null);
    this.progress = {
      clearedLeviathanIds: [...data.progress.clearedLeviathanIds]
    };
    this.candidates = this.#buildCandidates();
    this.pendingRewards = [];
    this.lastNodeLabel = null;
    this.selectedNode = null;
    this.simulator = null;
    this.runComplete = false;
    this.failed = false;
    this.resultTag = "active";
    this.lastCombatSummary = null;
  }

  #buildCandidates() {
    return generateNodeCandidates({
      seed: this.seed ^ ((this.runIndex + 1) * 0x9e3779b9),
      stageIndex: this.stageIndex,
      table: this.data.nodes,
      scalingOverrides: this.scalingOverrides
    });
  }

  snapshot() {
    return createRunSnapshot(this);
  }

  replaySummary() {
    return createReplaySummary(this);
  }

  selectNode(candidateIndex) {
    if (this.phase !== "node_select") {
      return this.snapshot();
    }

    const selected = this.candidates[candidateIndex];
    if (!selected) {
      return this.snapshot();
    }

    this.selectedNode = selected;
    this.lastNodeLabel = selected.label;
    this.simulator = new RunSimulator({
      seed: (this.seed + this.runIndex * 1009 + this.stageIndex * 9176) >>> 0,
      queueCapacity: this.queueCapacity,
      timeLimitTicks: selected.combat.timeLimitTicks,
      node: {
        shield: selected.combat.shield,
        health: selected.combat.health,
        weakness: [...selected.combat.weakness]
      },
      initialQueue: this.stageIndex === 0 ? this.initialQueue : null,
      stageIndex: this.stageIndex,
      nodeType: selected.id
    });
    this.phase = "combat";
    this.resultTag = "combat";
    return this.snapshot();
  }

  applyCombatInput(input) {
    if (this.phase !== "combat" || !this.simulator) {
      return this.snapshot();
    }

    const combatSnapshot = this.simulator.applyInput(input);
    this.lastCombatSummary = { ...combatSnapshot.summary };

    if (combatSnapshot.result === "clear") {
      this.pendingRewards = resolveStageRewards({
        seed: this.seed,
        stageIndex: this.stageIndex,
        runIndex: this.runIndex,
        rewardTable: this.data.rewards,
        clearedWeaknesses: combatSnapshot.targets?.[0]?.weakness ?? []
      });
      this.phase = "reward_loot";
      this.simulator = null;
      this.resultTag = "stage_clear";
    } else if (combatSnapshot.repairRequired || combatSnapshot.result === "time_over") {
      this.phase = "failed";
      this.failed = true;
      this.resultTag = combatSnapshot.repairRequired ? "repair_required" : "time_over";
    }

    return this.snapshot();
  }

  claimRewards() {
    if (this.phase !== "reward_loot") {
      return this.snapshot();
    }

    this.pendingRewards = [];
    this.selectedNode = null;
    this.lastNodeLabel = this.lastNodeLabel ?? null;

    const clearedFinalStage = this.stageIndex >= this.maxStages - 1;
    if (!clearedFinalStage) {
      this.stageIndex += 1;
      this.candidates = this.#buildCandidates();
      this.phase = "node_select";
      this.resultTag = "next_stage";
      return this.snapshot();
    }

    const clearedFinalRun = this.runIndex >= this.maxRuns - 1;
    if (clearedFinalRun) {
      if (!this.progress.clearedLeviathanIds.includes(this.leviathanId)) {
        this.progress.clearedLeviathanIds.push(this.leviathanId);
      }
      this.phase = "run_complete";
      this.runComplete = true;
      this.resultTag = "leviathan_clear";
      return this.snapshot();
    }

    this.runIndex += 1;
    this.stageIndex = 0;
    this.candidates = this.#buildCandidates();
    this.phase = "node_select";
    this.resultTag = "next_run";
    return this.snapshot();
  }

  pickUpPlacedArtifact(instanceId) {
    if (this.phase !== "reward_loot") {
      return this.snapshot();
    }

    this.inventory = pickUpInventoryArtifact(this.inventory, instanceId);
    return this.snapshot();
  }

  placeHeldArtifact(placement) {
    if (this.phase !== "reward_loot") {
      return this.snapshot();
    }

    this.inventory = placeHeldInventoryArtifact(this.inventory, placement);
    return this.snapshot();
  }

  discardHeldArtifact() {
    if (this.phase !== "reward_loot") {
      return this.snapshot();
    }

    this.inventory = discardHeldInventoryArtifact(this.inventory);
    return this.snapshot();
  }
}

export function createHeadlessRun(config = {}) {
  return new HeadlessMiniRun(config);
}
