import { PHASE } from "../../phases/phase-tags.js";
import { isInventoryEditable } from "../../process/mini-run-stage-script.js";

export function renderPhaseChrome(
  { backpackWrap, lootBar, phaseBanner, startBtn },
  phase
) {
  backpackWrap?.classList.toggle("editable", isInventoryEditable(phase));
  if (lootBar) lootBar.style.display = phase.tag === PHASE.REWARD_LOOT ? "block" : "none";
  if (phaseBanner) {
    if (phase.tag === PHASE.REWARD_LOOT) {
      phaseBanner.style.display = "block";
      phaseBanner.innerHTML =
        "<strong>습득 페이즈</strong> — 보상 유물을 가방에 배치하거나 휴지통으로 버리세요.";
    } else {
      phaseBanner.style.display = "none";
    }
  }
  if (startBtn) {
    if (phase.tag === PHASE.COMBAT_START) {
      startBtn.textContent = "Start Game";
      startBtn.disabled = false;
    } else if (phase.tag === PHASE.COMBAT && phase.combat?.gameStarted) {
      startBtn.textContent = "전투 중";
      startBtn.disabled = true;
    } else {
      startBtn.textContent = "Start Game";
      startBtn.disabled = true;
    }
  }
}
