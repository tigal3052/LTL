import { ARTIFACT_LABELS } from "../../tuning/mini-run-config.js";

export function renderRewardStaging(rewardStaging, pendingRewards, onPickReward) {
  if (!rewardStaging) return;
  rewardStaging.innerHTML = "";
  for (const rw of pendingRewards ?? []) {
    const chip = document.createElement("button");
    chip.type = "button";
    chip.className = `reward-chip ${rw.color}`;
    const label = ARTIFACT_LABELS[rw.tableId] ?? rw.tableId;
    chip.textContent = label;
    chip.title = `${label} (${rw.color}) — 클릭하여 들기`;
    chip.addEventListener("mousedown", (e) => {
      e.preventDefault();
      onPickReward(rw.rewardId);
    });
    rewardStaging.appendChild(chip);
  }
  if ((pendingRewards ?? []).length === 0) {
    const empty = document.createElement("span");
    empty.style.color = "#8fa2ad";
    empty.style.fontSize = "13px";
    empty.textContent = "모든 보상을 가방에 넣었거나 버렸습니다.";
    rewardStaging.appendChild(empty);
  }
}

export function renderLootContinueButton(claimRewardsBtn, ready, pendingCount) {
  if (!claimRewardsBtn) return;
  claimRewardsBtn.disabled = !ready;
  claimRewardsBtn.textContent = ready ? "다음 스테이지로" : `남은 보상 ${pendingCount}개`;
}
