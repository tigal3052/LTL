import { combatToDisplay } from "../../vocabulary/node/combat-to-display.js";

export function renderNodeSelectOverlay({ nodeOverlay, nodeCardRoot, lootBar }, phase, onPick) {
  if (!nodeCardRoot) return;
  nodeCardRoot.innerHTML = "";
  for (let i = 0; i < (phase.candidates ?? []).length; i += 1) {
    const c = phase.candidates[i];
    const d = combatToDisplay(c.combat);
    const btn = document.createElement("button");
    btn.type = "button";
    btn.className = "node-card";
    const weakTxt =
      c.weakness.length === 0 ? "취약: 없음 (정박)" : `취약: ${c.weakness.join(", ")}`;
    btn.innerHTML = `<span class="tag">후보 ${i + 1}</span><div class="name">${c.label}</div><div class="meta">${weakTxt}<br>마력장 ${d.runMaxShield} · 체력 ${d.runMaxHp} · 제한 ${d.timeRemaining}s</div>`;
    btn.addEventListener("click", () => onPick(i));
    nodeCardRoot.appendChild(btn);
  }
  if (nodeOverlay) nodeOverlay.style.display = "flex";
  if (lootBar) lootBar.style.display = "none";
}
