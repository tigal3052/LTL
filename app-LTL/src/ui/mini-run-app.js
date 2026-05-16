import { InventoryModel } from "../models/inventory.js";
import { TICK_MS } from "../domain/game-tuning.js";
import { getArtifactDef } from "../models/artifact-table.js";
import { recalculateSynergy } from "../vocabulary/backpack/recalculate-synergy.js";
import { rotateHeld } from "../vocabulary/backpack/held-item.js";
import { fireShot, tickCombat } from "../vocabulary/combat/fire-shot.js";
import { canFireShot } from "../vocabulary/combat/input-guard.js";
import {
  advanceMiniRun,
  isInventoryEditable,
  lootReadyToContinue,
  startMiniRun
} from "../process/mini-run-stage-script.js";
import { PHASE, PHASE_LABELS } from "../phases/phase-tags.js";
import {
  ARTIFACT_LABELS,
  ENERGY_COLORS,
  HOLD_DELAY_MS,
  HOLD_INTERVAL_MS,
  MINI_RUN_MAX_STAGES,
  MINI_RUN_SEED,
  MONO_COLOR_CYCLE,
  SHOT_COOLDOWN_MS
} from "../tuning/mini-run-config.js";
import { renderForPhase } from "./render/index.js";
import { bindTerrainGrid, renderTerrain } from "./render/render-terrain.js";

const refs = {
  terrain: document.querySelector("#terrain"),
  backpack: document.querySelector("#backpack"),
  output: document.querySelector("#output"),
  queueContainer: document.querySelector("#queue-container"),
  feedbackLabel: document.querySelector("#feedback-label"),
  shieldBar: document.querySelector("#shield-bar"),
  shieldText: document.querySelector("#shield-text"),
  hpBar: document.querySelector("#hp-bar"),
  hpText: document.querySelector("#hp-text"),
  timeLabel: document.querySelector("#time-label"),
  pinLabel: document.querySelector("#pin-label"),
  overlay: document.querySelector("#game-over-overlay"),
  overlayText: document.querySelector("#overlay-text"),
  monoColorBtn: document.querySelector("#mono-color-mode"),
  nodeOverlay: document.querySelector("#node-overlay"),
  nodeCardRoot: document.querySelector("#node-card-root"),
  lootBar: document.querySelector("#loot-bar"),
  rewardStaging: document.querySelector("#reward-staging"),
  trashZone: document.querySelector("#trash-zone"),
  phaseBanner: document.querySelector("#phase-banner"),
  claimRewardsBtn: document.querySelector("#claim-rewards-btn"),
  miniRunPhaseLabel: document.querySelector("#mini-run-phase-label"),
  miniRunStageLabel: document.querySelector("#mini-run-stage-label"),
  miniRunMaxLabel: document.querySelector("#mini-run-max-label"),
  miniRunNodeLabel: document.querySelector("#mini-run-node-label"),
  backpackWrap: document.querySelector(".backpack"),
  startBtn: document.querySelector("#start-btn")
};

let phase = null;
let gameTimer = null;
let holdDelayTimer = null;
let lastShotAt = 0;
let trashHover = false;
/** 지형 타일을 누르고 있는 동안만 true — document mouseup에서 끊어 연발 사격이 멈춤 */
let terrainPointerActive = false;
const uiPrefs = { monoEnergyType: null };

function dispatch(event) {
  phase = advanceMiniRun(phase, event);
  paint();
}

function paint() {
  if (!phase) return;
  renderForPhase(refs, phase, PHASE_LABELS, MINI_RUN_MAX_STAGES, handlers);
  if (!phase.held) hideGhost();
  if (phase.combat && refs.output) {
    refs.output.textContent = JSON.stringify(phase.combat.summary, null, 2);
  }
}

const handlers = {
  onPickNode(index) {
    dispatch({ type: "choose_node", index });
    if (phase.tag !== PHASE.COMBAT_START) return;
    clearHeld();
    setFeedback("전투 준비 — Start Game으로 시작");
  },
  onPickReward(rewardId) {
    dispatch({ type: "pick_up_reward", rewardId });
    if (phase.held) {
      renderGhost(window.lastMouseX ?? 0, window.lastMouseY ?? 0);
    } else {
      hideGhost();
    }
    paint();
  },
  onBackpackMouseDown(e) {
    if (!phase || !isInventoryEditable(phase)) return;
    const slot = e.target.closest?.(".slot");
    if (!slot || !refs.backpack?.contains(slot)) return;
    if (phase.combat?.gameOver || phase.combat?.gameWon) return;
    e.preventDefault();
    const r = parseInt(slot.dataset.r, 10);
    const c = parseInt(slot.dataset.c, 10);
    if (!phase.held) {
      dispatch({ type: "pick_up_inventory", row: r, col: c });
      if (phase.held) {
        renderGhost(window.lastMouseX ?? 0, window.lastMouseY ?? 0);
      }
    } else {
      dispatch({ type: "place", row: r, col: c });
      if (!phase.held) {
        hideGhost();
      } else {
        renderGhost(window.lastMouseX ?? 0, window.lastMouseY ?? 0);
      }
    }
    applyMonoColorMode();
    paint();
  }
};

function clearHeld() {
  if (phase?.held) phase = { ...phase, held: null };
  hideGhost();
  refs.trashZone?.classList.remove("active");
  trashHover = false;
}

function setFeedback(message) {
  if (refs.feedbackLabel) refs.feedbackLabel.textContent = `Feedback: ${message}`;
}

function showFloatingText(text, x, y, color) {
  const el = document.createElement("div");
  el.className = "floating-text";
  el.textContent = text;
  el.style.left = `${x}px`;
  el.style.top = `${y}px`;
  el.style.color = color;
  document.body.appendChild(el);
  setTimeout(() => el.remove(), 1000);
}

function hideGhost() {
  const ghost = document.getElementById("ghost");
  if (ghost) ghost.remove();
}

function renderGhost(x, y) {
  if (!phase?.held) return;
  let ghost = document.getElementById("ghost");
  if (!ghost) {
    ghost = document.createElement("div");
    ghost.id = "ghost";
    ghost.style.cssText = "position:fixed;pointer-events:none;z-index:100";
    document.body.appendChild(ghost);
  }
  ghost.style.display = "grid";
  ghost.style.left = `${x + 10}px`;
  ghost.style.top = `${y + 10}px`;
  const shape = phase.held.shape;
  ghost.style.gridTemplateColumns = `repeat(${shape[0].length}, 40px)`;
  ghost.style.gridTemplateRows = `repeat(${shape.length}, 40px)`;
  ghost.style.gap = "8px";
  ghost.innerHTML = "";
  const colorMap = { red: "#ff756b", blue: "#73bcff", purple: "#c79aff", green: "#8bdd74" };
  const colorHex = colorMap[phase.held.energyType] ?? "#fff";
  for (let r = 0; r < shape.length; r++) {
    for (let c = 0; c < shape[r].length; c++) {
      const cell = document.createElement("div");
      if (shape[r][c] === 1) {
        cell.className = "slot item";
        cell.style.borderColor = colorHex;
        cell.style.boxShadow = `inset 0 0 0 2px ${colorHex}40`;
        cell.style.background = "rgba(51, 67, 81, 0.8)";
      } else {
        cell.style.visibility = "hidden";
      }
      ghost.append(cell);
    }
  }
}

function applyMonoColorMode() {
  for (const a of phase.inventory.artifacts) {
    const def = getArtifactDef(a.tableId);
    a.energyType =
      uiPrefs.monoEnergyType != null ? uiPrefs.monoEnergyType : def ? def.energyType : a.energyType;
  }
  recalculateSynergy(phase.inventory);
  syncMonoColorButtonLabel();
}

function syncMonoColorButtonLabel() {
  if (!refs.monoColorBtn) return;
  if (uiPrefs.monoEnergyType == null) {
    refs.monoColorBtn.textContent = "동일 색 모드 (끔)";
  } else {
    const names = { red: "빨강", blue: "파랑", purple: "보라", green: "초록" };
    refs.monoColorBtn.textContent = `동일 색: ${names[uiPrefs.monoEnergyType]}`;
  }
}

function randomColor() {
  return ENERGY_COLORS[Math.floor(Math.random() * ENERGY_COLORS.length)];
}

function onStageCleared() {
  stopGameLoop();
  if (phase.combat) {
    phase = {
      ...phase,
      combat: {
        ...phase.combat,
        gameStarted: false,
        summary: {
          ...phase.combat.summary,
          result: "clear",
          stage_index: phase.stageIndex,
          clear_time_sec: phase.combat.stageInitialTime - phase.combat.timeRemaining
        }
      }
    };
  }
  if (refs.overlay) refs.overlay.style.display = "none";
  dispatch({ type: "stage_cleared" });
  paint();
}

function runFireShot(x, y) {
  const combat = phase.combat;
  if (!combat) return;
  const tile =
    combat.hoveredTile != null ? refs.terrain?.children[combat.hoveredTile] : null;
  const fx = x || window.lastMouseX || (tile ? tile.getBoundingClientRect().left + 20 : 0);
  const fy = y || window.lastMouseY || (tile ? tile.getBoundingClientRect().top + 20 : 0);

  const { combat: next, outcome, damage, hitIndex } = fireShot(combat, combat.hoveredTile);
  phase = { ...phase, combat: next };

  if (outcome === "no_target") setFeedback("no_target");
  else if (outcome === "empty_queue") {
    setFeedback("empty_queue");
    showFloatingText("Empty!", fx, fy, "#ff756b");
  } else if (outcome === "invalid_cooldown") {
    setFeedback("invalid_cooldown");
    showFloatingText("Invalid", fx, fy, "#8fa2ad");
  } else if (outcome === "fired" && damage) {
    showFloatingText(
      damage.type === "match" ? "Match!" : "Mismatch",
      fx,
      fy,
      damage.type === "match" ? "#f6c762" : "#8fa2ad"
    );
    const statsEl = document.querySelector(".node-stats");
    if (statsEl) {
      const rect = statsEl.getBoundingClientRect();
      showFloatingText(
        `-${Math.round(damage.shield + damage.hp)}`,
        rect.left + rect.width / 2,
        rect.bottom + 20,
        "#ff756b"
      );
    }
    if (hitIndex != null && refs.terrain?.children[hitIndex]) {
      const t = refs.terrain.children[hitIndex];
      refs.terrain.querySelectorAll(".hit").forEach((n) => n.classList.remove("hit"));
      t.classList.add("hit");
      setTimeout(() => t.classList.remove("hit"), 150);
    }
    setFeedback("fired");
    if (next.gameWon) onStageCleared();
  }
  paint();
}

function gameTick() {
  if (!phase || phase.tag !== PHASE.COMBAT || !phase.combat?.gameStarted) return;
  const { combat, queueChanged, pinBreak } = tickCombat(phase.combat, phase.inventory, {
    pickColor: randomColor
  });
  phase = { ...phase, combat };
  if (pinBreak) {
    showFloatingText(`Pin Break! (${pinBreak.pins} left)`, window.innerWidth / 2, 100, "#f6c762");
  }
  if (combat.gameOver) {
    stopGameLoop();
    if (refs.overlayText) {
      refs.overlayText.textContent = "GAME OVER";
      refs.overlayText.style.color = "#ff756b";
    }
    if (refs.overlay) refs.overlay.style.display = "flex";
  }
  if (queueChanged || phase.combat.tick % 2 === 0) paint();
  else renderTerrain(refs.terrain, phase.combat);
}

function stopGameLoop() {
  if (gameTimer !== null) {
    window.clearInterval(gameTimer);
    gameTimer = null;
  }
}

function startGameLoop() {
  stopGameLoop();
  if (!phase || phase.tag !== PHASE.COMBAT || !phase.combat?.gameStarted) return;
  gameTimer = window.setInterval(gameTick, TICK_MS);
}

function stopHold() {
  if (phase?.combat?.holdTimer != null) {
    window.clearInterval(phase.combat.holdTimer);
    phase = { ...phase, combat: { ...phase.combat, holdTimer: null } };
  }
}

function stopHoldFire() {
  terrainPointerActive = false;
  if (holdDelayTimer !== null) {
    clearTimeout(holdDelayTimer);
    holdDelayTimer = null;
  }
  stopHold();
}

function bindTerrain() {
  bindTerrainGrid(refs.terrain, {
    onHover(index) {
      if (!phase?.combat || phase.tag !== PHASE.COMBAT) return;
      phase = { ...phase, combat: { ...phase.combat, hoveredTile: index } };
      renderTerrain(refs.terrain, phase.combat);
    },
    onMouseDown(index, event) {
      if (!phase || phase.tag !== PHASE.COMBAT || !phase.combat?.gameStarted) return;
      event.preventDefault();
      terrainPointerActive = true;
      phase = { ...phase, combat: { ...phase.combat, hoveredTile: index } };
      const now = Date.now();
      if (canFireShot(now, lastShotAt, SHOT_COOLDOWN_MS)) {
        runFireShot(event.clientX, event.clientY);
        lastShotAt = now;
      }
      if (holdDelayTimer !== null) clearTimeout(holdDelayTimer);
      holdDelayTimer = setTimeout(() => {
        if (!terrainPointerActive) return;
        stopHold();
        const holdTimer = window.setInterval(() => {
          if (!terrainPointerActive) {
            stopHold();
            return;
          }
          const t = Date.now();
          if (t - lastShotAt < HOLD_INTERVAL_MS) return;
          runFireShot(null, null);
          lastShotAt = t;
        }, HOLD_INTERVAL_MS);
        phase = { ...phase, combat: { ...phase.combat, holdTimer } };
      }, HOLD_DELAY_MS);
    },
    onMouseUp: stopHoldFire,
    onMouseLeave(index) {
      stopHoldFire();
      if (!phase?.combat) return;
      if (phase.combat.hoveredTile === index) {
        phase = { ...phase, combat: { ...phase.combat, hoveredTile: null } };
        renderTerrain(refs.terrain, phase.combat);
      }
    }
  });
}

function resetDemo() {
  stopHoldFire();
  stopGameLoop();

  const inventory = new InventoryModel();
  inventory.placeArtifact("basic_red", 0, 0, 0);
  inventory.placeArtifact("basic_red", 0, 1, 0);
  inventory.placeArtifact("basic_blue", 3, 0, 90);
  inventory.placeArtifact("l_purple", 0, 4, 0);
  inventory.placeArtifact("square_green", 4, 4, 0);

  phase = startMiniRun({ seed: MINI_RUN_SEED, maxStages: MINI_RUN_MAX_STAGES, inventory });
  uiPrefs.monoEnergyType = null;
  if (refs.overlay) refs.overlay.style.display = "none";
  clearHeld();
  applyMonoColorMode();
  setFeedback("idle");
  paint();
}

function onClaimRewards() {
  if (!lootReadyToContinue(phase)) return;
  dispatch({ type: "claim_rewards" });
  if (refs.lootBar) refs.lootBar.style.display = "none";

  if (phase.tag === PHASE.RUN_COMPLETE) {
    if (refs.overlayText) {
      refs.overlayText.textContent = "미니 런 클리어";
      refs.overlayText.style.color = "#8bdd74";
    }
    if (refs.overlay) refs.overlay.style.display = "flex";
    paint();
    return;
  }
  paint();
}

document.querySelector("#run")?.addEventListener("click", resetDemo);

refs.startBtn?.addEventListener("click", () => {
  if (phase.tag !== PHASE.COMBAT_START) {
    setFeedback("먼저 노드를 고르세요");
    return;
  }
  dispatch({ type: "begin_combat" });
  startGameLoop();
  setFeedback("전투 시작!");
  paint();
});

refs.claimRewardsBtn?.addEventListener("click", onClaimRewards);

refs.trashZone?.addEventListener("mousedown", (e) => {
  e.preventDefault();
  if (phase.held) {
    dispatch({ type: "discard_held" });
    clearHeld();
    paint();
  }
});

document.querySelector("#freeze-test")?.addEventListener("click", () => {
  const active = phase.inventory.artifacts;
  if (active.length > 0) {
    active[Math.floor(Math.random() * active.length)].freezeTicks = 60;
    paint();
    showFloatingText("FROZEN!", window.innerWidth / 2, 200, "#73bcff");
  }
});

refs.monoColorBtn?.addEventListener("click", () => {
  let i = MONO_COLOR_CYCLE.indexOf(uiPrefs.monoEnergyType);
  if (i === -1) i = 0;
  uiPrefs.monoEnergyType = MONO_COLOR_CYCLE[(i + 1) % MONO_COLOR_CYCLE.length];
  applyMonoColorMode();
  paint();
  const names = { red: "빨강", blue: "파랑", purple: "보라", green: "초록" };
  showFloatingText(
    uiPrefs.monoEnergyType == null
      ? "유물 색: 기본(종류별)"
      : `모든 유물 → ${names[uiPrefs.monoEnergyType]}`,
    window.innerWidth / 2,
    160,
    "#f6c762"
  );
});

window.addEventListener("mousemove", (e) => {
  window.lastMouseX = e.clientX;
  window.lastMouseY = e.clientY;
  if (phase?.held) renderGhost(e.clientX, e.clientY);
  if (refs.trashZone) {
    const rect = refs.trashZone.getBoundingClientRect();
    const over =
      e.clientX >= rect.left &&
      e.clientX <= rect.right &&
      e.clientY >= rect.top &&
      e.clientY <= rect.bottom;
    trashHover = over && Boolean(phase?.held);
    refs.trashZone.classList.toggle("active", trashHover);
  }
});

window.addEventListener("keydown", (e) => {
  if ((e.key === "r" || e.key === "R") && phase?.held) {
    phase = { ...phase, held: rotateHeld(phase.held) };
    renderGhost(window.lastMouseX || 0, window.lastMouseY || 0);
  }
});

window.addEventListener("mouseup", () => {
  if (trashHover && phase?.held) {
    dispatch({ type: "discard_held" });
    clearHeld();
    paint();
  }
  stopHoldFire();
});

if (!refs.terrain || !refs.backpack) {
  const msg = document.createElement("p");
  msg.style.cssText = "color:#ff756b;padding:16px";
  msg.textContent = "UI 요소를 찾지 못했습니다. npm run dev 후 /public/index.html 로 여세요.";
  document.body.prepend(msg);
} else {
  resetDemo();
  bindTerrain();
  refs.backpack?.addEventListener("mousedown", (e) => handlers.onBackpackMouseDown(e));
}
