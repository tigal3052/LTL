export class HazardModel {
  constructor(inventory) {
    this.inventory = inventory;
    this.activeHazards = [];
  }

  // Freeze delays cooldown by keeping freezeTicks > 0
  applyFreeze(artifactId, durationTicks) {
    const artifact = this.inventory.getArtifactById(artifactId);
    if (artifact) {
      artifact.freezeTicks += durationTicks;
      this.activeHazards.push({ type: 'freeze', artifactId, duration: durationTicks });
      return true;
    }
    return false;
  }

  // Break entirely disables energy generation until repaired
  applyBreak(artifactId) {
    const artifact = this.inventory.getArtifactById(artifactId);
    if (artifact && !artifact.isBroken) {
      artifact.isBroken = true;
      this.activeHazards.push({ type: 'break', artifactId });
      return true;
    }
    return false;
  }

  // Repair fixes break status and clears freeze
  repairHazard(artifactId) {
    const artifact = this.inventory.getArtifactById(artifactId);
    if (artifact) {
      const wasBroken = artifact.isBroken;
      const wasFrozen = artifact.freezeTicks > 0;
      
      artifact.isBroken = false;
      artifact.freezeTicks = 0;

      // Remove from active hazards
      this.activeHazards = this.activeHazards.filter(h => h.artifactId !== artifactId);

      return wasBroken || wasFrozen;
    }
    return false;
  }
}
