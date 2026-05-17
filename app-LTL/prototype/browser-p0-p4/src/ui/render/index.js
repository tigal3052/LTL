import { PHASE } from "../../phases/phase-tags.js";
import { lootReadyToContinue } from "../../process/mini-run-stage-script.js";
import { renderBackpack } from "./render-backpack.js";
import { renderNodeStats, renderTimePins, renderMiniRunHud } from "./render-combat-hud.js";
import { renderNodeSelectOverlay } from "./render-node-select.js";
import { renderPhaseChrome } from "./render-phase-chrome.js";
import { renderQueue } from "./render-queue.js";
import { renderLootContinueButton, renderRewardStaging } from "./render-reward-loot.js";
import { lobbyTerrainRenderState, renderTerrain } from "./render-terrain.js";

/**
 * 태그(`phase.tag`)별로 HUD·오버레이·지형·가방 등 DOM만 갱신한다.
 *
 * 주의: phase를 수정하지 않는다(읽기 전용). 진행·보유 유물 드래그 등 상태 변경은
 * `advanceMiniRun` / reducer에서만 이루어지고, 그 결과로 넘어온 phase를 그린다.
 */
export function renderForPhase(refs, phase, labels, maxStages, handlers) {
  if (!phase) return;

  renderMiniRunHud(refs, phase, labels, maxStages);
  renderPhaseChrome(refs, phase);

  if (phase.tag === PHASE.NODE_SELECT) {
    renderNodeSelectOverlay(refs, phase, handlers.onPickNode);
  } else if (refs.nodeOverlay) {
    refs.nodeOverlay.style.display = "none";
  }

  if (phase.tag === PHASE.REWARD_LOOT) {
    renderRewardStaging(refs.rewardStaging, phase.pendingRewards, handlers.onPickReward);
    renderLootContinueButton(
      refs.claimRewardsBtn,
      lootReadyToContinue(phase),
      phase.pendingRewards?.length ?? 0
    );
  }

  if (phase.combat) {
    renderNodeStats(refs, phase.combat);
    renderTimePins(refs, phase.combat);
    renderQueue(refs.queueContainer, phase.combat.queue);
    renderTerrain(refs.terrain, phase.combat);
  } else if (phase.tag === PHASE.NODE_SELECT) {
    // [프로토타입 임시조치] 로비 전용 가짜 combat 형태 — render-terrain.js 주석 참고
    renderTerrain(refs.terrain, lobbyTerrainRenderState(phase.seed ?? 0));
  }

  renderBackpack(refs.backpack, phase.inventory);
}
