export const PHASE = {
  NODE_SELECT: "node_select",
  COMBAT_START: "combat_start",
  COMBAT: "combat",
  COMBAT_END: "combat_end",
  REWARD_LOOT: "reward_loot",
  BACKPACK_ORGANIZE: "backpack_organize",
  RUN_COMPLETE: "run_complete"
};

export const PHASE_LABELS = {
  [PHASE.NODE_SELECT]: "노드 선택",
  [PHASE.COMBAT_START]: "전투 준비",
  [PHASE.COMBAT]: "전투",
  [PHASE.COMBAT_END]: "전투 종료",
  [PHASE.REWARD_LOOT]: "습득",
  [PHASE.BACKPACK_ORGANIZE]: "가방 정리",
  [PHASE.RUN_COMPLETE]: "런 완료"
};
