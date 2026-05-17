export function renderNodeStats({ shieldBar, shieldText, hpBar, hpText }, combat) {
  if (!combat) return;
  if (shieldBar) shieldBar.style.width = `${(combat.nodeShield / combat.runMaxShield) * 100}%`;
  if (shieldText) {
    shieldText.textContent = `Shield: ${Math.round(combat.nodeShield)}/${combat.runMaxShield}`;
  }
  if (hpBar) hpBar.style.width = `${(combat.nodeHp / combat.runMaxHp) * 100}%`;
  if (hpText) hpText.textContent = `HP: ${Math.round(combat.nodeHp)}/${combat.runMaxHp}`;
}

export function renderTimePins({ timeLabel, pinLabel }, combat) {
  if (!combat) return;
  if (timeLabel) {
    timeLabel.textContent = `Time: ${combat.timeRemaining}s`;
    timeLabel.style.color =
      combat.timeRemaining <= 5 && combat.pins === 0 ? "#ff756b" : "#e8edf2";
  }
  if (pinLabel) pinLabel.textContent = `Pins: ${combat.pins}`;
}

export function renderMiniRunHud({ miniRunStageLabel, miniRunPhaseLabel, miniRunNodeLabel, miniRunMaxLabel }, phase, labels, maxStages) {
  if (miniRunStageLabel) miniRunStageLabel.textContent = String((phase.stageIndex ?? 0) + 1);
  if (miniRunPhaseLabel) miniRunPhaseLabel.textContent = labels[phase.tag] ?? phase.tag;
  if (miniRunNodeLabel) {
    miniRunNodeLabel.textContent = phase.lastNodeLabel ? `노드: ${phase.lastNodeLabel}` : "노드: —";
  }
  if (miniRunMaxLabel) miniRunMaxLabel.textContent = String(maxStages);
}
