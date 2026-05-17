# LootingTheLeviathan — history — 2026-05-15

## P4 미니 런·스케일링

- **Intent:** 3스테이지 미니 런에서 클리어 → 보상 수령 → 노드 선택 → 다음 전투 루프, 스테이지 상승 시 마력장·체력·시간 압박을 비선형(초반 완만 → 중반 급증 → 후반 완화)으로 스케일.
- **Files:** `app-LTL/src/domain/stage-scaling.js`, `node-generator.js`, `reward-resolver.js`, `run-progression.js`, `src/data/node-table.json`, `tests/p4_mini_run.test.js`, `src/tools/mini-run-telemetry.js`, `public/index.html`.
- **Verification:** `node --test tests/*.test.js` (29 pass); `npm run mini-run-telemetry` (20/20 complete in harness).
