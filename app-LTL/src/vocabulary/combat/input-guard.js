export function canFireShot(nowMs, lastShotAtMs, cooldownMs) {
  return nowMs - lastShotAtMs >= cooldownMs;
}

export const TILE_SHOT_COOLDOWN_TICKS = 10;
export const QUEUE_CAPACITY = 8;
