const COUNTER_FIELDS = [
  "shots_fired",
  "shots_hit_match",
  "shots_hit_mismatch",
  "shots_invalid_tile_cooldown",
  "shots_fired_empty_queue",
  "invalid_target_inputs",
  "queue_generated",
  "queue_consumed",
  "queue_wasted",
  "durability_loss_count",
  "repair_count"
];

export function diffSummaryCounters(beforeSummary = {}, afterSummary = {}) {
  const diff = {};

  for (const field of COUNTER_FIELDS) {
    diff[field] = (afterSummary[field] ?? 0) - (beforeSummary[field] ?? 0);
  }

  return diff;
}

export function deriveActionResult({
  beforeSummary = {},
  afterSummary = {},
  beforeRepairRequired = false,
  afterRepairRequired = false,
  attemptedInput = "click"
} = {}) {
  const diff = diffSummaryCounters(beforeSummary, afterSummary);

  let feedback = "idle";
  if (diff.invalid_target_inputs > 0) {
    feedback = "invalid_target";
  } else if (diff.shots_fired_empty_queue > 0) {
    feedback = "empty_queue";
  } else if (diff.shots_invalid_tile_cooldown > 0) {
    feedback = "invalid_cooldown";
  } else if (afterSummary.result === "clear" && beforeSummary.result !== "clear") {
    feedback = "clear";
  } else if (afterSummary.result === "time_over" && beforeSummary.result !== "time_over") {
    feedback = "time_over";
  } else if (afterRepairRequired && !beforeRepairRequired) {
    feedback = "repair_required";
  } else if (attemptedInput === "click" && diff.shots_fired > 0) {
    feedback = "fired";
  }

  return {
    feedback,
    diff
  };
}
