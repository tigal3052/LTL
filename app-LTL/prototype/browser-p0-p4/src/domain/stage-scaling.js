/**
 * Stage combat scaling: total shield/health rise with stageIndex, while marginal
 * growth per stage is small early, steep mid-run, then tapers (Gaussian bump on deltas).
 * Time pressure uses the same bump shape for per-stage tick cuts.
 */

const DEFAULTS = {
  baseShield: 2.4,
  baseHealth: 3.2,
  baseTimeLimitTicks: 1200,
  peakStage: 3.25,
  sigma: 1.65,
  peakShieldDelta: 0.55,
  peakHealthDelta: 0.72,
  peakTimeCutTicks: 140,
  minTimeLimitTicks: 360
};

function gaussianBump(stageIndex, { peakStage, sigma, peak }) {
  const z = (stageIndex - peakStage) / sigma;
  return peak * Math.exp(-0.5 * z * z);
}

/**
 * @param {number} stageIndex - 0-based stage; stage 0 uses base stats only.
 * @param {Partial<typeof DEFAULTS>} [overrides]
 */
export function computeStageCombatParams(stageIndex, overrides = {}) {
  const o = { ...DEFAULTS, ...overrides };
  let shield = o.baseShield;
  let health = o.baseHealth;
  let timeLimitTicks = o.baseTimeLimitTicks;

  for (let k = 0; k < stageIndex; k += 1) {
    shield += gaussianBump(k, {
      peakStage: o.peakStage,
      sigma: o.sigma,
      peak: o.peakShieldDelta
    });
    health += gaussianBump(k, {
      peakStage: o.peakStage,
      sigma: o.sigma,
      peak: o.peakHealthDelta
    });
    timeLimitTicks -= gaussianBump(k, {
      peakStage: o.peakStage,
      sigma: o.sigma,
      peak: o.peakTimeCutTicks
    });
  }

  timeLimitTicks = Math.max(o.minTimeLimitTicks, Math.floor(timeLimitTicks));

  return {
    stageIndex,
    shield,
    health,
    timeLimitTicks
  };
}

/**
 * Exposed for tests: marginal shield gain when moving from stage `stageIndex` to `stageIndex+1`.
 */
export function marginalShieldDelta(stageIndex, overrides = {}) {
  const o = { ...DEFAULTS, ...overrides };
  return gaussianBump(stageIndex, {
    peakStage: o.peakStage,
    sigma: o.sigma,
    peak: o.peakShieldDelta
  });
}

export function marginalHealthDelta(stageIndex, overrides = {}) {
  const o = { ...DEFAULTS, ...overrides };
  return gaussianBump(stageIndex, {
    peakStage: o.peakStage,
    sigma: o.sigma,
    peak: o.peakHealthDelta
  });
}
