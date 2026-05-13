import { deriveActionResult } from "./action-result.js";

export class CombatController {
  constructor({ simulator, fireIntervalTicks = 2 } = {}) {
    if (!simulator) {
      throw new Error("CombatController requires a simulator");
    }

    this.simulator = simulator;
    this.fireIntervalTicks = fireIntervalTicks;
    this.inputLog = [];
    this.lastSnapshot = simulator.snapshot();
    this.state = {
      hoveredTile: null,
      feedback: "idle"
    };
    this.hold = {
      active: false,
      target: null,
      nextTick: null
    };
  }

  hoverTile(tileIndex) {
    this.state.hoveredTile = tileIndex;
    return this.state.hoveredTile;
  }

  clickAtTick(tick, tileIndex = this.state.hoveredTile) {
    if (tileIndex == null) {
      this.state.feedback = "no_target";
      return this.lastSnapshot;
    }

    const entry = { tick, target: tileIndex, input: "click" };
    const beforeSummary = this.lastSnapshot.summary;
    const beforeRepairRequired = this.lastSnapshot.repairRequired;
    this.inputLog.push(entry);
    this.lastSnapshot = this.simulator.applyInput(entry);
    const action = this.lastSnapshot.action ?? deriveActionResult({
      beforeSummary,
      afterSummary: this.lastSnapshot.summary,
      beforeRepairRequired,
      afterRepairRequired: this.lastSnapshot.repairRequired
    });
    this.state.feedback = action.feedback;
    return this.lastSnapshot;
  }

  startHoldAtTick(tick, tileIndex = this.state.hoveredTile) {
    this.hold.active = true;
    this.hold.target = tileIndex;
    this.hold.nextTick = tick;
    this.advanceToTick(tick);
    return this.lastSnapshot;
  }

  advanceToTick(tick) {
    if (!this.hold.active || this.hold.target == null) {
      return this.lastSnapshot;
    }

    while (this.hold.nextTick != null && this.hold.nextTick <= tick) {
      this.clickAtTick(this.hold.nextTick, this.hold.target);
      this.hold.nextTick += this.fireIntervalTicks;
    }

    return this.lastSnapshot;
  }

  stopHold() {
    this.hold.active = false;
    this.hold.nextTick = null;
    return this.lastSnapshot;
  }
}
