/** Simulation tick length used by RunSimulator and browser demo (ms). */
export const TICK_MS = 50;

/** Default generator cooldown before synergy (seconds). */
export const BASE_COOLDOWN_SEC = 5;

/** Cooldown reduction per unique orthogonally adjacent same-color artifact (seconds). */
export const SYNERGY_COOLDOWN_REDUCTION_SEC_PER_NEIGHBOR = 0.1;

export function secondsToTicks(seconds) {
  return Math.max(1, Math.round((seconds * 1000) / TICK_MS));
}

export const BASE_COOLDOWN_TICKS = secondsToTicks(BASE_COOLDOWN_SEC);
export const SYNERGY_COOLDOWN_REDUCTION_TICKS_PER_NEIGHBOR = secondsToTicks(
  SYNERGY_COOLDOWN_REDUCTION_SEC_PER_NEIGHBOR
);
