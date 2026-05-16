import { STAGE_SENTENCE } from "./mini-run-stage-script.js";

/** Maps current tag to the next tag in STAGE_SENTENCE (skips merged steps). */
export function nextStageTag(currentTag) {
  const merged = new Set(["backpack_organize"]);
  const flow = STAGE_SENTENCE.filter((t) => !merged.has(t) || t === "reward_loot");
  const idx = flow.indexOf(currentTag);
  if (idx === -1 || idx >= flow.length - 1) return null;
  return flow[idx + 1];
}

export function assertStageFlowOrder() {
  const required = ["node_select", "combat_start", "combat", "reward_loot"];
  for (const tag of required) {
    if (!STAGE_SENTENCE.includes(tag)) {
      throw new Error(`STAGE_SENTENCE missing ${tag}`);
    }
  }
}
