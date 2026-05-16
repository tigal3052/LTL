/**
 * @returns {{ combat: object, pinBreak?: { pins: number } }}
 */
export function checkTimeProgress(combat) {
  if (combat.gameOver || combat.gameWon) {
    return { combat };
  }

  let timeRemaining = combat.timeRemaining - 1;
  const T = Math.max(1, combat.stageInitialTime || 60);
  const s = T / 60;
  const t = timeRemaining;

  let newPins = 4;
  if (t <= Math.floor(45 * s)) newPins = 3;
  if (t <= Math.floor(30 * s)) newPins = 2;
  if (t <= Math.floor(15 * s)) newPins = 1;
  if (t <= Math.max(5, Math.floor(5 * s))) newPins = 0;

  let next = { ...combat, timeRemaining };
  let pinBreak;

  if (combat.pins !== newPins) {
    next = { ...next, pins: newPins };
    pinBreak = { pins: newPins };
  }

  if (timeRemaining <= 0) {
    next = {
      ...next,
      gameOver: true,
      timeRemaining: 0,
      summary: {
        ...next.summary,
        result: "fail",
        fail_time_sec: combat.stageInitialTime - timeRemaining
      }
    };
  }

  return { combat: next, pinBreak };
}
