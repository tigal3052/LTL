import { TICK_MS } from "../../domain/game-tuning.js";

export function renderBackpack(backpackEl, inventory) {
  if (!backpackEl) return;
  backpackEl.innerHTML = "";
  for (let r = 0; r < inventory.height; r++) {
    for (let c = 0; c < inventory.width; c++) {
      const slot = document.createElement("div");
      const instanceId = inventory.grid[r][c];
      if (instanceId !== null) {
        const artifact = inventory.getArtifactById(instanceId);
        let colorHex = "#fff";
        if (artifact.energyType === "red") colorHex = "#ff756b";
        if (artifact.energyType === "blue") colorHex = "#73bcff";
        if (artifact.energyType === "purple") colorHex = "#c79aff";
        if (artifact.energyType === "green") colorHex = "#8bdd74";

        slot.className = "slot item";
        if (artifact.freezeTicks > 0) {
          slot.classList.add("frozen");
          slot.title = `FROZEN (${Math.ceil(artifact.freezeTicks / (1000 / TICK_MS))}s)`;
        } else {
          slot.title = `${artifact.energyType} | CD: ${artifact.effectiveCooldown}`;
        }
        slot.style.borderColor = colorHex;
        slot.style.boxShadow = `inset 0 0 0 2px ${colorHex}40`;
        const eff = artifact.effectiveCooldown;
        const readyPct =
          eff > 0 ? Math.max(0, Math.min(100, (1 - artifact.currentCooldown / eff) * 100)) : 100;
        const cdBar = document.createElement("div");
        cdBar.className = "cd-bar";
        const cdFill = document.createElement("span");
        cdFill.style.width = `${readyPct}%`;
        cdBar.appendChild(cdFill);
        slot.appendChild(cdBar);
      } else {
        slot.className = "slot";
      }
      slot.dataset.r = String(r);
      slot.dataset.c = String(c);
      backpackEl.append(slot);
    }
  }
}
