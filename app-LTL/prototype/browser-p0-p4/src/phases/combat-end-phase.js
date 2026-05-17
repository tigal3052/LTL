import { PHASE } from "./phase-tags.js";

/** 전투 종료 절 — 보상 롤 직전 스냅샷 (headless/UI 공통 개념) */
export function enterCombatEnd(phase, outcome = "clear") {
  return {
    tag: PHASE.COMBAT_END,
    seed: phase.seed,
    stageIndex: phase.stageIndex,
    maxStages: phase.maxStages,
    inventory: phase.inventory,
    lastClearWeakness: phase.lastClearWeakness ?? [],
    lastNodeLabel: phase.lastNodeLabel ?? "",
    outcome,
    held: null
  };
}
