# Phase-First Page Shell Wireframes And Harness Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the approved HTML wireframe set for six non-combat pages and write a dedicated page-contract harness design note that prepares the runtime audit to move from shell containment checks to page-aware contracts.

**Architecture:** Treat the two approved specs as the source of truth, keep all deliverables inside `docs/mockups` and `docs/superpowers/specs`, and do not touch the Godot runtime in this pass. The HTML files should share a document-board presentation pattern while still standing alone. The harness note should describe how to evolve `run_main_layout_audit_contract.gd` and related page smoke runners without prematurely editing runtime code.

**Tech Stack:** Static HTML, inline CSS, Markdown design docs, existing `docs/mockups` presentation style, PowerShell verification commands, optional in-app browser review after implementation.

---

## File Structure

- Create: `docs/mockups/m6-run-start-wireframe.html`
  - Run-start wireframe for character choice, starter relic choice, and starter backpack preview.
- Create: `docs/mockups/m6-node-select-run-flow-wireframe.html`
  - Node-select wireframe showing run progress, five live node choices, collapsed unknown future nodes, and boss endpoint.
- Create: `docs/mockups/m6-reward-claim-wireframe.html`
  - Reward-claim wireframe for claimed relic list, fixed detail inspector, backpack placement space, and discard area.
- Create: `docs/mockups/m6-event-node-wireframe.html`
  - Event-node wireframe for a large narrative image and choice-button panel.
- Create: `docs/mockups/m6-boss-reward-pick-wireframe.html`
  - Boss-reward-pick wireframe for three-card relic choice with locked confirmation CTA.
- Create: `docs/mockups/m6-defeat-page-wireframe.html`
  - Defeat-page wireframe for parachute escape framing, large `GAME OVER`, and centered restart CTA.
- Create: `docs/superpowers/specs/2026-06-05-page-contract-harness-audit-design.ko.md`
  - Dedicated harness design note that turns the approved page-shell contract into actionable audit responsibilities and proposed test splits.
- Modify: `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-05.md`
  - Keep the current task aligned with the implementation-plan phase.
- Modify: `docs/codex-worklog/history_LootingTheLeviathan_2026-06-05.md`
  - Record the plan-writing change set.
- Modify: `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-05.md`
  - Record the plan-only completion state honestly.

## Task 1: Write the dedicated page-contract harness design note first

**Files:**
- Create: `docs/superpowers/specs/2026-06-05-page-contract-harness-audit-design.ko.md`
- Modify: `docs/codex-worklog/history_LootingTheLeviathan_2026-06-05.md`

- [ ] **Step 1: Verify the harness design note does not already exist**

Run:

```powershell
Test-Path 'docs/superpowers/specs/2026-06-05-page-contract-harness-audit-design.ko.md'
```

Expected:

- `False`

- [ ] **Step 2: Create the harness design note with explicit page contracts and audit ownership**

```md
# 2026-06-05 Page Contract Harness Audit Design

Date: 2026-06-05
Workspace: `LootingTheLeviathan`

## Goal

Move the current UI audit from generic shell containment toward page-aware contract validation.

## Current Inputs

- `docs/superpowers/specs/2026-06-05-phase-first-page-shell-contract-design.ko.md`
- `app-LTL/tests/run_main_layout_audit_contract.gd`
- `app-LTL/src/ui/MainViewRuntime.gd`
- `app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd`

## Required Audit Split

1. `run_start` page contract
2. `node_select` page contract
3. `combat` page contract
4. `reward_claim` page contract
5. `event_node` page contract
6. `boss_reward_pick` page contract
7. `defeat` page contract

## Per-Page Rules

### `run_start`

- visible: character list, selected character hero panel, starter relic candidates, starter backpack preview, start CTA
- hidden: battlefield, reward tray, discard zone, node map canvas
- allowed overlay actions: `settings`, `artifact codex`
- blocked overlay actions: `shop`

### `node_select`

- visible: run progress bar, path row, five live node choices, unknown future node chain, boss endpoint, selected-node detail
- hidden: battlefield, reward discard zone, defeat hero frame
- allowed overlay actions: `settings`, `artifact codex`, `shop`
- blocked interaction: full-size combat backpack dock

### `reward_claim`

- visible: reward image list, backpack grid, fixed detail inspector, discard zone, confirm CTA
- hidden: battlefield, node path row, event hero image
- required interaction: click-to-inspect drives the detail panel instead of hover-only tooltip

## Audit Migration

- keep `run_main_layout_audit_contract.gd` as the viewport-containment base
- add a page-aware runner for visible/hidden and action policy checks
- split page-specific smoke tests once runtime implementation starts

## Candidate Future Runners

- `app-LTL/tests/run_page_shell_contract_audit.gd`
- `app-LTL/tests/test_run_start_page_smoke.gd`
- `app-LTL/tests/test_reward_claim_page_smoke.gd`
- `app-LTL/tests/test_event_node_page_smoke.gd`
- `app-LTL/tests/test_boss_reward_pick_page_smoke.gd`
- `app-LTL/tests/test_defeat_page_smoke.gd`

## Verification Targets

- each page declares exactly one primary panel cluster
- blocked overlays stay hidden or disabled
- visible controls stay inside viewport bounds
- node-select progress model exposes run and stage counts separately
- reward-claim exposes detail-panel-first interaction language
```

- [ ] **Step 3: Verify the harness note contains the required page and runner sections**

Run:

```powershell
Select-String -Path 'docs/superpowers/specs/2026-06-05-page-contract-harness-audit-design.ko.md' -Pattern 'run_start','reward_claim','run_page_shell_contract_audit.gd','click-to-inspect'
```

Expected:

- Four matches covering the page-contract split, future runner, and reward-claim inspector rule.

- [ ] **Step 4: Commit the harness-note task**

```bash
git add docs/superpowers/specs/2026-06-05-page-contract-harness-audit-design.ko.md docs/codex-worklog/history_LootingTheLeviathan_2026-06-05.md
git commit -m "docs: add page contract harness design note"
```

## Task 2: Build the run-start wireframe

**Files:**
- Create: `docs/mockups/m6-run-start-wireframe.html`

- [ ] **Step 1: Confirm the run-start wireframe file is absent**

Run:

```powershell
Test-Path 'docs/mockups/m6-run-start-wireframe.html'
```

Expected:

- `False`

- [ ] **Step 2: Create the run-start wireframe with a three-zone board and annotations**

```html
<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>M6 Run Start Wireframe</title>
  <style>
    :root {
      color-scheme: dark;
      --bg-0: #0b1014;
      --bg-1: #121b22;
      --panel: rgba(17, 27, 35, 0.94);
      --line: rgba(222, 233, 242, 0.12);
      --text: #eef4f8;
      --muted: #9daebb;
      --accent: #ddb66a;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: "Segoe UI", "Pretendard", sans-serif;
      color: var(--text);
      background:
        radial-gradient(circle at top, rgba(108, 146, 176, 0.16), transparent 30%),
        linear-gradient(180deg, #10171d 0%, #090d12 100%);
    }
    .page { width: min(1440px, calc(100vw - 40px)); margin: 0 auto; padding: 28px 0 40px; }
    .hero { margin-bottom: 22px; }
    .eyebrow { color: var(--accent); font-size: 12px; letter-spacing: .16em; text-transform: uppercase; font-weight: 700; }
    h1 { margin: 10px 0 12px; font-size: clamp(30px, 4vw, 46px); }
    .subtitle { max-width: 880px; margin: 0; color: var(--muted); line-height: 1.6; }
    .board {
      background: var(--panel);
      border: 1px solid var(--line);
      border-radius: 28px;
      padding: 20px;
      box-shadow: 0 24px 64px rgba(0,0,0,.32);
    }
    .frame {
      display: grid;
      grid-template-columns: 0.95fr 1.2fr 1.05fr;
      gap: 16px;
      min-height: 760px;
    }
    .panel {
      border: 1px solid var(--line);
      border-radius: 22px;
      padding: 16px;
      background: rgba(255,255,255,.02);
    }
    .panel h2 { margin: 0 0 12px; font-size: 18px; }
    .stack { display: grid; gap: 12px; }
    .card, .slot-grid, .cta {
      border: 1px dashed rgba(255,255,255,.18);
      border-radius: 16px;
      padding: 12px;
      min-height: 90px;
      color: var(--muted);
    }
    .slot-grid {
      display: grid;
      grid-template-columns: repeat(6, 1fr);
      gap: 8px;
      min-height: 230px;
    }
    .slot-grid span {
      aspect-ratio: 1 / 1;
      border-radius: 10px;
      border: 1px solid rgba(255,255,255,.12);
      background: rgba(255,255,255,.03);
    }
    .notes {
      display: grid;
      grid-template-columns: 1.2fr .8fr;
      gap: 16px;
      margin-top: 16px;
    }
    .note-box {
      border: 1px solid var(--line);
      border-radius: 20px;
      padding: 16px 18px;
      background: rgba(8, 12, 16, .45);
    }
    ol { margin: 0; padding-left: 20px; line-height: 1.7; }
    ul { margin: 0; padding-left: 18px; line-height: 1.7; }
    @media (max-width: 1100px) {
      .frame, .notes { grid-template-columns: 1fr; }
    }
  </style>
</head>
<body>
  <main class="page">
    <header class="hero">
      <div class="eyebrow">M6 Wireframe · Run Start</div>
      <h1>런 시작 페이지</h1>
      <p class="subtitle">캐릭터 선택, 시작 유물 선택, 시작 백팩 미리보기를 한 화면에서 끝내는 준비 페이지. 전투 HUD가 아니라 준비 상태와 시작 조합 판독이 주인공이다.</p>
    </header>
    <section class="board">
      <div class="frame">
        <section class="panel">
          <h2>01 캐릭터 리스트</h2>
          <div class="stack">
            <div class="card">기본 캐릭터 카드 A</div>
            <div class="card">기본 캐릭터 카드 B</div>
            <div class="card">잠금 또는 대체 캐릭터 카드</div>
          </div>
        </section>
        <section class="panel">
          <h2>02 선택 캐릭터 히어로 패널</h2>
          <div class="card" style="min-height: 280px;">캐릭터 대형 일러스트 또는 전신 실루엣</div>
          <div class="card">코어 특성 / 난이도 / 추천 빌드</div>
          <div class="cta">런 시작 버튼과 시작 개요 텍스트</div>
        </section>
        <section class="panel">
          <h2>03 시작 유물 + 시작 백팩</h2>
          <div class="stack">
            <div class="card">시작 유물 선택 카드 3개</div>
            <div class="slot-grid">
              <span></span><span></span><span></span><span></span><span></span><span></span>
              <span></span><span></span><span></span><span></span><span></span><span></span>
              <span></span><span></span><span></span><span></span><span></span><span></span>
              <span></span><span></span><span></span><span></span><span></span><span></span>
            </div>
          </div>
        </section>
      </div>
      <div class="notes">
        <div class="note-box">
          <ol>
            <li>캐릭터 선택은 좌측 세로열에서 빠르게 비교되며, 중앙 패널이 선택 결과를 크게 보여준다.</li>
            <li>시작 유물 선택은 우측에서 이뤄지지만, 결과는 바로 아래 백팩 preview에 반영되어야 한다.</li>
            <li>이 페이지에서는 전투 HUD나 로그 패널이 아니라 시작 조합의 판독성이 중심이다.</li>
          </ol>
        </div>
        <div class="note-box">
          <ul>
            <li>허용 오버레이: 설정, 유물도감</li>
            <li>차단 오버레이: 상점</li>
            <li>구현 포인트: click-to-select, preview grid, start CTA hierarchy</li>
          </ul>
        </div>
      </div>
    </section>
  </main>
</body>
</html>
```

- [ ] **Step 3: Verify the run-start wireframe exposes the expected sections**

Run:

```powershell
Select-String -Path 'docs/mockups/m6-run-start-wireframe.html' -Pattern '<title>M6 Run Start Wireframe</title>','런 시작 페이지','시작 유물 + 시작 백팩'
```

Expected:

- Three matches proving title, page heading, and right-side preparation panel are present.

- [ ] **Step 4: Commit the run-start wireframe**

```bash
git add docs/mockups/m6-run-start-wireframe.html
git commit -m "docs: add run start wireframe mockup"
```

## Task 3: Build the node-select run-flow wireframe

**Files:**
- Create: `docs/mockups/m6-node-select-run-flow-wireframe.html`

- [ ] **Step 1: Confirm the node-select wireframe file is absent**

Run:

```powershell
Test-Path 'docs/mockups/m6-node-select-run-flow-wireframe.html'
```

Expected:

- `False`

- [ ] **Step 2: Create the node-select wireframe with run and stage progress lanes**

```html
<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>M6 Node Select Run Flow Wireframe</title>
  <style>
    :root {
      color-scheme: dark;
      --bg: #0c1116;
      --panel: rgba(18, 27, 35, 0.95);
      --line: rgba(232, 240, 246, 0.12);
      --text: #eff5f9;
      --muted: #9dafbd;
      --accent: #e2bb70;
    }
    * { box-sizing: border-box; }
    body { margin: 0; font-family: "Segoe UI", "Pretendard", sans-serif; color: var(--text); background: linear-gradient(180deg, #131a21 0%, #0a0f14 100%); }
    .page { width: min(1460px, calc(100vw - 40px)); margin: 0 auto; padding: 28px 0 42px; }
    .hero { margin-bottom: 20px; }
    .eyebrow { color: var(--accent); font-size: 12px; letter-spacing: .16em; text-transform: uppercase; font-weight: 700; }
    h1 { margin: 10px 0 12px; font-size: clamp(30px, 4vw, 46px); }
    .subtitle { margin: 0; max-width: 900px; color: var(--muted); line-height: 1.6; }
    .board { background: var(--panel); border: 1px solid var(--line); border-radius: 28px; padding: 20px; }
    .progress { display: grid; grid-template-columns: repeat(2, 1fr); gap: 14px; margin-bottom: 16px; }
    .progress-card, .main-board, .detail-panel, .note-box {
      border: 1px solid var(--line);
      border-radius: 18px;
      background: rgba(255,255,255,.02);
    }
    .progress-card { padding: 14px 16px; }
    .layout { display: grid; grid-template-columns: 1.35fr .65fr; gap: 16px; }
    .main-board { padding: 18px; min-height: 620px; }
    .track { display: grid; grid-template-columns: repeat(12, minmax(0, 1fr)); gap: 10px; align-items: center; min-height: 500px; }
    .node {
      border: 1px dashed rgba(255,255,255,.2);
      border-radius: 16px;
      min-height: 84px;
      display: grid;
      place-items: center;
      color: var(--muted);
      text-align: center;
      padding: 8px;
    }
    .node.choice { border-style: solid; color: var(--text); }
    .node.past { opacity: .65; }
    .node.unknown { font-size: 22px; }
    .detail-panel { padding: 18px; min-height: 620px; }
    .note-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-top: 16px; }
    .note-box { padding: 16px 18px; }
    ol, ul { margin: 0; padding-left: 20px; line-height: 1.7; }
    @media (max-width: 1120px) {
      .layout, .note-grid, .progress { grid-template-columns: 1fr; }
      .track { grid-template-columns: repeat(6, minmax(0, 1fr)); }
    }
  </style>
</head>
<body>
  <main class="page">
    <header class="hero">
      <div class="eyebrow">M6 Wireframe · Node Select</div>
      <h1>노드 선택 페이지</h1>
      <p class="subtitle">런 전체 길이와 현재 선택지를 동시에 읽는 경로 페이지. 현재 선택 가능한 다섯 개 노드와, 앞으로 남은 `?` 구간, 보스 종착점이 한 구조 안에서 보여야 한다.</p>
    </header>
    <section class="board">
      <div class="progress">
        <div class="progress-card">Run 1/5</div>
        <div class="progress-card">Stage 6/25</div>
      </div>
      <div class="layout">
        <section class="main-board">
          <div class="track">
            <div class="node">시작</div>
            <div class="node past">지나온 노드</div>
            <div class="node past">지나온 노드</div>
            <div class="node choice">선택지 1</div>
            <div class="node choice">선택지 2</div>
            <div class="node choice">선택지 3</div>
            <div class="node choice">선택지 4</div>
            <div class="node choice">선택지 5</div>
            <div class="node unknown">?</div>
            <div class="node unknown">?</div>
            <div class="node unknown">?</div>
            <div class="node">보스전</div>
          </div>
        </section>
        <aside class="detail-panel">
          <h2>선택 노드 상세</h2>
          <div class="node choice" style="min-height: 120px;">선택 노드 카드 확대</div>
          <div class="node" style="margin-top: 12px; min-height: 160px;">Risk / Reward / Special / 추천 빌드 힌트</div>
          <div class="node" style="margin-top: 12px; min-height: 100px;">축소형 loadout summary 또는 열림형 보조 패널 자리</div>
        </aside>
      </div>
      <div class="note-grid">
        <div class="note-box">
          <ol>
            <li>진행도는 `Run`과 `Stage`를 분리해, 런 묶음과 총 스테이지를 동시에 읽게 한다.</li>
            <li>현재 선택 가능한 다섯 개 노드는 동일한 우선순위로 비교되며, 남은 구간은 `?` 체인으로 압축한다.</li>
            <li>백팩은 전투처럼 상시 대형 패널이 아니라 참조형 loadout surface로 낮춘다.</li>
          </ol>
        </div>
        <div class="note-box">
          <ul>
            <li>허용 오버레이: 설정, 유물도감, 상점</li>
            <li>차단 구조: 전투 전용 HUD, reward discard zone</li>
            <li>구현 포인트: five live choices, unknown future chain, boss endpoint</li>
          </ul>
        </div>
      </div>
    </section>
  </main>
</body>
</html>
```

- [ ] **Step 3: Verify the node-select wireframe includes run progress and five choices**

Run:

```powershell
Select-String -Path 'docs/mockups/m6-node-select-run-flow-wireframe.html' -Pattern 'Run 1/5','Stage 6/25','선택지 5','보스전'
```

Expected:

- Four matches proving the approved progress model and path structure are present.

- [ ] **Step 4: Commit the node-select wireframe**

```bash
git add docs/mockups/m6-node-select-run-flow-wireframe.html
git commit -m "docs: add node select run flow wireframe"
```

## Task 4: Build the reward-claim wireframe around a fixed inspector

**Files:**
- Create: `docs/mockups/m6-reward-claim-wireframe.html`

- [ ] **Step 1: Confirm the reward-claim wireframe file is absent**

Run:

```powershell
Test-Path 'docs/mockups/m6-reward-claim-wireframe.html'
```

Expected:

- `False`

- [ ] **Step 2: Create the reward-claim wireframe with reward list, backpack, and inspector**

```html
<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>M6 Reward Claim Wireframe</title>
  <style>
    :root {
      color-scheme: dark;
      --bg: #0b1015;
      --panel: rgba(18, 27, 35, 0.95);
      --line: rgba(236, 243, 247, 0.12);
      --text: #eff4f8;
      --muted: #9eadba;
      --accent: #ddb56a;
    }
    * { box-sizing: border-box; }
    body { margin: 0; font-family: "Segoe UI", "Pretendard", sans-serif; color: var(--text); background: linear-gradient(180deg, #10171c 0%, #090d11 100%); }
    .page { width: min(1480px, calc(100vw - 40px)); margin: 0 auto; padding: 28px 0 44px; }
    .eyebrow { color: var(--accent); font-size: 12px; letter-spacing: .16em; text-transform: uppercase; font-weight: 700; }
    h1 { margin: 10px 0 12px; font-size: clamp(30px, 4vw, 46px); }
    .subtitle { margin: 0 0 22px; max-width: 920px; color: var(--muted); line-height: 1.6; }
    .board { border: 1px solid var(--line); border-radius: 28px; padding: 20px; background: var(--panel); }
    .layout { display: grid; grid-template-columns: .8fr 1.1fr .9fr; gap: 16px; min-height: 760px; }
    .panel, .note-box { border: 1px solid var(--line); border-radius: 20px; padding: 16px; background: rgba(255,255,255,.02); }
    .panel h2 { margin: 0 0 12px; font-size: 18px; }
    .reward-list { display: grid; gap: 10px; }
    .reward-card, .detail-card, .discard, .toolbar {
      border: 1px dashed rgba(255,255,255,.18);
      border-radius: 16px;
      padding: 12px;
      color: var(--muted);
    }
    .grid {
      display: grid;
      grid-template-columns: repeat(8, 1fr);
      gap: 8px;
      min-height: 420px;
      margin-bottom: 14px;
    }
    .grid span {
      aspect-ratio: 1 / 1;
      border-radius: 10px;
      border: 1px solid rgba(255,255,255,.12);
      background: rgba(255,255,255,.03);
    }
    .placed {
      grid-column: span 2;
      grid-row: span 2;
      background: rgba(221, 181, 106, .12);
      border-style: solid;
    }
    .notes { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-top: 16px; }
    ol, ul { margin: 0; padding-left: 20px; line-height: 1.7; }
    @media (max-width: 1200px) {
      .layout, .notes { grid-template-columns: 1fr; }
    }
  </style>
</head>
<body>
  <main class="page">
    <div class="eyebrow">M6 Wireframe · Reward Claim</div>
    <h1>보상 수령 페이지</h1>
    <p class="subtitle">획득한 유물 목록을 이미지로 보고, 선택한 유물의 효과와 시너지를 고정형 상세 패널에서 읽은 뒤, 중앙 백팩에 배치하거나 파기하는 인스펙터 중심 페이지.</p>
    <section class="board">
      <div class="layout">
        <section class="panel">
          <h2>01 수령 보상 목록</h2>
          <div class="reward-list">
            <div class="reward-card">유물 카드 A 이미지</div>
            <div class="reward-card">유물 카드 B 이미지</div>
            <div class="reward-card">유물 카드 C 이미지</div>
            <div class="reward-card">유물 카드 D 이미지</div>
          </div>
        </section>
        <section class="panel">
          <h2>02 백팩 배치 공간</h2>
          <div class="grid">
            <span class="placed"></span><span></span><span></span><span></span><span></span><span></span><span></span>
            <span></span><span></span><span class="placed"></span><span></span><span></span><span></span><span></span><span></span>
            <span></span><span></span><span></span><span></span><span></span><span></span><span></span><span></span>
            <span></span><span></span><span></span><span></span><span></span><span></span><span></span><span></span>
            <span></span><span></span><span></span><span></span><span></span><span></span><span></span><span></span>
            <span></span><span></span><span></span><span></span><span></span><span></span><span></span><span></span>
            <span></span><span></span><span></span><span></span><span></span><span></span><span></span><span></span>
            <span></span><span></span><span></span><span></span><span></span><span></span><span></span><span></span>
          </div>
          <div class="toolbar">Rotate / Place / Pin / Confirm 배치 힌트</div>
          <div class="discard" style="margin-top: 12px;">03 파기 영역</div>
        </section>
        <aside class="panel">
          <h2>04 상세 정보 패널</h2>
          <div class="detail-card" style="min-height: 120px;">선택 유물 이름 / 희귀도 / 유형</div>
          <div class="detail-card" style="min-height: 140px; margin-top: 12px;">효과 설명과 시너지</div>
          <div class="detail-card" style="min-height: 120px; margin-top: 12px;">도형, 크기, 차지, 배치 힌트</div>
          <div class="detail-card" style="min-height: 90px; margin-top: 12px;">기존 hover tooltip 대신 click-to-inspect로 고정 표시</div>
        </aside>
      </div>
      <div class="notes">
        <div class="note-box">
          <ol>
            <li>유물 정보는 hover 툴팁이 아니라 우측 상세 패널에서 안정적으로 읽혀야 한다.</li>
            <li>중앙 백팩은 배치 판단의 무대이고, 좌측 목록은 선택 원천이다.</li>
            <li>파기 영역은 별도 행위 영역으로 분리해 accidental discard를 줄인다.</li>
          </ol>
        </div>
        <div class="note-box">
          <ul>
            <li>허용 오버레이: 설정, 유물도감</li>
            <li>차단 구조: battlefield, node path row</li>
            <li>구현 포인트: click-to-inspect, fixed inspector, discard safety</li>
          </ul>
        </div>
      </div>
    </section>
  </main>
</body>
</html>
```

- [ ] **Step 3: Verify the reward-claim wireframe advertises click-to-inspect**

Run:

```powershell
Select-String -Path 'docs/mockups/m6-reward-claim-wireframe.html' -Pattern '보상 수령 페이지','상세 정보 패널','click-to-inspect','파기 영역'
```

Expected:

- Four matches proving the fixed inspector behavior and discard zone are documented directly in the mockup.

- [ ] **Step 4: Commit the reward-claim wireframe**

```bash
git add docs/mockups/m6-reward-claim-wireframe.html
git commit -m "docs: add reward claim wireframe mockup"
```

## Task 5: Build the event-node wireframe

**Files:**
- Create: `docs/mockups/m6-event-node-wireframe.html`

- [ ] **Step 1: Confirm the event-node wireframe file is absent**

Run:

```powershell
Test-Path 'docs/mockups/m6-event-node-wireframe.html'
```

Expected:

- `False`

- [ ] **Step 2: Create the event-node wireframe with hero image and choice rail**

```html
<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>M6 Event Node Wireframe</title>
  <style>
    :root {
      color-scheme: dark;
      --bg: #0b1014;
      --panel: rgba(17, 27, 35, 0.95);
      --line: rgba(234, 242, 248, 0.12);
      --text: #eef4f8;
      --muted: #9eadb9;
      --accent: #deb56b;
    }
    * { box-sizing: border-box; }
    body { margin: 0; font-family: "Segoe UI", "Pretendard", sans-serif; color: var(--text); background: linear-gradient(180deg, #11181e 0%, #090d11 100%); }
    .page { width: min(1400px, calc(100vw - 40px)); margin: 0 auto; padding: 28px 0 42px; }
    .hero { margin-bottom: 20px; }
    .eyebrow { color: var(--accent); font-size: 12px; letter-spacing: .16em; text-transform: uppercase; font-weight: 700; }
    h1 { margin: 10px 0 12px; font-size: clamp(30px, 4vw, 46px); }
    .subtitle { max-width: 880px; margin: 0; color: var(--muted); line-height: 1.6; }
    .board, .note-box { border: 1px solid var(--line); border-radius: 26px; background: var(--panel); }
    .board { padding: 20px; }
    .layout { display: grid; grid-template-columns: 1.2fr .8fr; gap: 16px; min-height: 720px; }
    .hero-image, .choices, .side-note {
      border: 1px dashed rgba(255,255,255,.18);
      border-radius: 18px;
      padding: 14px;
      color: var(--muted);
      background: rgba(255,255,255,.02);
    }
    .hero-image { min-height: 520px; }
    .choices { min-height: 180px; display: grid; gap: 10px; }
    .choice { border: 1px solid rgba(255,255,255,.14); border-radius: 14px; padding: 12px; }
    .notes { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-top: 16px; }
    .note-box { padding: 16px 18px; }
    ol, ul { margin: 0; padding-left: 20px; line-height: 1.7; }
    @media (max-width: 1080px) {
      .layout, .notes { grid-template-columns: 1fr; }
    }
  </style>
</head>
<body>
  <main class="page">
    <header class="hero">
      <div class="eyebrow">M6 Wireframe · Event Node</div>
      <h1>이벤트 노드 페이지</h1>
      <p class="subtitle">대형 사건 이미지를 중심에 두고, 선택지는 하단 패널에서 명확하게 비교한다. 도감이나 상점보다 현재 이벤트의 서사와 선택 결과가 우선이다.</p>
    </header>
    <section class="board">
      <div class="layout">
        <section class="hero-image">01 이벤트 대형 이미지 또는 씬 아트</section>
        <aside class="side-note">02 결과/리스크 보조 메모 블록</aside>
      </div>
      <section class="choices" style="margin-top: 16px;">
        <div class="choice">03 선택지 A</div>
        <div class="choice">04 선택지 B</div>
        <div class="choice">05 선택지 C</div>
      </section>
      <div class="notes">
        <div class="note-box">
          <ol>
            <li>이벤트의 주인공은 이미지와 선택지다. loadout 정보는 보조 정보로 밀려야 한다.</li>
            <li>선택지는 버튼처럼 읽히되, 한 줄 요약과 짧은 결과 힌트를 함께 둔다.</li>
          </ol>
        </div>
        <div class="note-box">
          <ul>
            <li>허용 오버레이: 설정</li>
            <li>기본 차단: 유물도감, 상점</li>
            <li>구현 포인트: hero image hierarchy, choice clarity, low-distraction shell</li>
          </ul>
        </div>
      </div>
    </section>
  </main>
</body>
</html>
```

- [ ] **Step 3: Verify the event-node wireframe includes the event image and choice panel**

Run:

```powershell
Select-String -Path 'docs/mockups/m6-event-node-wireframe.html' -Pattern '이벤트 노드 페이지','이벤트 대형 이미지','선택지 C'
```

Expected:

- Three matches proving the page centers the event image and explicit choice list.

- [ ] **Step 4: Commit the event-node wireframe**

```bash
git add docs/mockups/m6-event-node-wireframe.html
git commit -m "docs: add event node wireframe mockup"
```

## Task 6: Build the boss reward pick wireframe

**Files:**
- Create: `docs/mockups/m6-boss-reward-pick-wireframe.html`

- [ ] **Step 1: Confirm the boss reward pick wireframe file is absent**

Run:

```powershell
Test-Path 'docs/mockups/m6-boss-reward-pick-wireframe.html'
```

Expected:

- `False`

- [ ] **Step 2: Create the boss reward pick wireframe with three fixed choice cards**

```html
<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>M6 Boss Reward Pick Wireframe</title>
  <style>
    :root {
      color-scheme: dark;
      --bg: #0c1116;
      --panel: rgba(18, 27, 35, 0.95);
      --line: rgba(236, 243, 248, 0.12);
      --text: #eef4f8;
      --muted: #9eacb8;
      --accent: #dfb86d;
    }
    * { box-sizing: border-box; }
    body { margin: 0; font-family: "Segoe UI", "Pretendard", sans-serif; color: var(--text); background: linear-gradient(180deg, #131920 0%, #090d11 100%); }
    .page { width: min(1420px, calc(100vw - 40px)); margin: 0 auto; padding: 28px 0 44px; }
    .eyebrow { color: var(--accent); font-size: 12px; letter-spacing: .16em; text-transform: uppercase; font-weight: 700; }
    h1 { margin: 10px 0 12px; font-size: clamp(30px, 4vw, 46px); }
    .subtitle { margin: 0 0 22px; max-width: 880px; color: var(--muted); line-height: 1.6; }
    .board { border: 1px solid var(--line); border-radius: 28px; background: var(--panel); padding: 20px; }
    .cards { display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; min-height: 460px; }
    .card, .detail, .cta, .note-box {
      border: 1px solid var(--line);
      border-radius: 20px;
      padding: 16px;
      background: rgba(255,255,255,.02);
    }
    .card { min-height: 420px; }
    .detail { margin-top: 16px; min-height: 140px; color: var(--muted); }
    .cta { margin-top: 16px; text-align: center; color: var(--text); }
    .notes { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-top: 16px; }
    ol, ul { margin: 0; padding-left: 20px; line-height: 1.7; }
    @media (max-width: 1100px) {
      .cards, .notes { grid-template-columns: 1fr; }
    }
  </style>
</head>
<body>
  <main class="page">
    <div class="eyebrow">M6 Wireframe · Boss Reward Pick</div>
    <h1>보스전 아이템 보상 페이지</h1>
    <p class="subtitle">보스전 승리 후 3개의 강한 선택 카드 중 하나를 확정하는 비교 페이지. 중앙 비교가 주인공이고, 상세 설명은 그 아래에서 선택 결과를 보강한다.</p>
    <section class="board">
      <div class="cards">
        <div class="card">01 보상 카드 A</div>
        <div class="card">02 보상 카드 B</div>
        <div class="card">03 보상 카드 C</div>
      </div>
      <div class="detail">04 선택 카드 상세 설명 / 시너지 / 가져가면 바뀌는 빌드 방향</div>
      <div class="cta">05 선택 확정 버튼</div>
      <div class="notes">
        <div class="note-box">
          <ol>
            <li>세 카드는 같은 우선순위로 나란히 비교되고, 마지막 선택은 별도 확인 동작으로 잠근다.</li>
            <li>Slay the Spire식 relic pick 판독성을 유지하되, 채굴 유물 질감으로 읽히게 번역한다.</li>
          </ol>
        </div>
        <div class="note-box">
          <ul>
            <li>허용 오버레이: 설정</li>
            <li>기본 차단: 유물도감, 상점</li>
            <li>구현 포인트: three-way comparison, locked confirm, single chosen relic</li>
          </ul>
        </div>
      </div>
    </section>
  </main>
</body>
</html>
```

- [ ] **Step 3: Verify the boss reward pick wireframe advertises three choices and confirm**

Run:

```powershell
Select-String -Path 'docs/mockups/m6-boss-reward-pick-wireframe.html' -Pattern '보스전 아이템 보상 페이지','보상 카드 C','선택 확정 버튼'
```

Expected:

- Three matches proving the approved three-choice comparison flow is present.

- [ ] **Step 4: Commit the boss reward pick wireframe**

```bash
git add docs/mockups/m6-boss-reward-pick-wireframe.html
git commit -m "docs: add boss reward pick wireframe mockup"
```

## Task 7: Build the defeat-page wireframe

**Files:**
- Create: `docs/mockups/m6-defeat-page-wireframe.html`

- [ ] **Step 1: Confirm the defeat-page wireframe file is absent**

Run:

```powershell
Test-Path 'docs/mockups/m6-defeat-page-wireframe.html'
```

Expected:

- `False`

- [ ] **Step 2: Create the defeat-page wireframe with escape framing and centered restart CTA**

```html
<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>M6 Defeat Page Wireframe</title>
  <style>
    :root {
      color-scheme: dark;
      --bg: #0a0d11;
      --panel: rgba(20, 16, 18, 0.94);
      --line: rgba(255, 219, 219, 0.12);
      --text: #f6ecec;
      --muted: #cbbbbb;
      --accent: #e19a72;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: "Segoe UI", "Pretendard", sans-serif;
      color: var(--text);
      background:
        radial-gradient(circle at top, rgba(190, 90, 70, 0.18), transparent 28%),
        linear-gradient(180deg, #160d11 0%, #09090c 100%);
    }
    .page { width: min(1280px, calc(100vw - 40px)); margin: 0 auto; padding: 28px 0 40px; }
    .eyebrow { color: var(--accent); font-size: 12px; letter-spacing: .16em; text-transform: uppercase; font-weight: 700; }
    h1 { margin: 14px 0 10px; font-size: clamp(48px, 8vw, 96px); letter-spacing: .08em; text-align: center; }
    .board, .note-box {
      border: 1px solid var(--line);
      border-radius: 26px;
      background: var(--panel);
    }
    .board { padding: 22px; }
    .hero-frame {
      min-height: 520px;
      border: 1px dashed rgba(255,255,255,.18);
      border-radius: 22px;
      display: grid;
      place-items: center;
      text-align: center;
      color: var(--muted);
      padding: 20px;
      background: rgba(255,255,255,.02);
    }
    .meta { max-width: 760px; margin: 18px auto 0; text-align: center; color: var(--muted); line-height: 1.7; }
    .cta {
      max-width: 320px;
      margin: 20px auto 0;
      border: 1px solid rgba(255,255,255,.18);
      border-radius: 18px;
      padding: 16px;
      text-align: center;
      color: var(--text);
      background: rgba(255,255,255,.03);
    }
    .notes { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-top: 16px; }
    .note-box { padding: 16px 18px; }
    ol, ul { margin: 0; padding-left: 20px; line-height: 1.7; }
    @media (max-width: 980px) {
      .notes { grid-template-columns: 1fr; }
    }
  </style>
</head>
<body>
  <main class="page">
    <div class="eyebrow">M6 Wireframe · Defeat</div>
    <h1>GAME OVER</h1>
    <section class="board">
      <div class="hero-frame">01 캐릭터 확대 패널 + 패러글라이딩 탈출 애니메이션 자리</div>
      <p class="meta">02 실패 원인 한 줄 · 03 다음 시도 힌트 한 줄</p>
      <div class="cta">04 다시하기 버튼</div>
      <div class="notes">
        <div class="note-box">
          <ol>
            <li>패배 페이지는 설명보다 감정이 먼저 와야 하므로 캐릭터 연출 프레임이 가장 커야 한다.</li>
            <li>`다시하기` CTA는 하단 중앙에 고정해 첫 시선 이동 후 바로 눌리게 한다.</li>
          </ol>
        </div>
        <div class="note-box">
          <ul>
            <li>허용 오버레이: 설정만 선택적으로 허용</li>
            <li>차단 구조: 유물도감, 상점, 노드 선택, 전투 HUD</li>
            <li>구현 포인트: emotional beat, escape framing, centered restart CTA</li>
          </ul>
        </div>
      </div>
    </section>
  </main>
</body>
</html>
```

- [ ] **Step 3: Verify the defeat-page wireframe includes the escape frame and restart CTA**

Run:

```powershell
Select-String -Path 'docs/mockups/m6-defeat-page-wireframe.html' -Pattern 'GAME OVER','패러글라이딩 탈출 애니메이션','다시하기 버튼'
```

Expected:

- Three matches proving the emotional frame and central restart CTA are present.

- [ ] **Step 4: Commit the defeat-page wireframe**

```bash
git add docs/mockups/m6-defeat-page-wireframe.html
git commit -m "docs: add defeat page wireframe mockup"
```

## Task 8: Update today's worklog and verify the documentation pass

**Files:**
- Modify: `docs/codex-worklog/history_LootingTheLeviathan_2026-06-05.md`
- Modify: `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-05.md`

- [ ] **Step 1: Record the actual implementation story in history**

```md
## 2026-06-05 wireframe implementation

- Intent: implement the six approved non-combat mockups and the dedicated harness design note.
- Files or areas touched:
  - `docs/mockups/m6-run-start-wireframe.html`
  - `docs/mockups/m6-node-select-run-flow-wireframe.html`
  - `docs/mockups/m6-reward-claim-wireframe.html`
  - `docs/mockups/m6-event-node-wireframe.html`
  - `docs/mockups/m6-boss-reward-pick-wireframe.html`
  - `docs/mockups/m6-defeat-page-wireframe.html`
  - `docs/superpowers/specs/2026-06-05-page-contract-harness-audit-design.ko.md`
- Summary: Built the approved page-shell wireframe documents and translated the shell contract into a dedicated harness-audit design note.
- Verification status: file existence checks, string checks, and final `git diff --check`.
```

- [ ] **Step 2: Update the completion report honestly**

```md
## Completion Summary

Implemented the six approved non-combat wireframe mockups and added a dedicated page-contract harness audit design note.

## Actual Outputs

- `docs/mockups/m6-run-start-wireframe.html`
- `docs/mockups/m6-node-select-run-flow-wireframe.html`
- `docs/mockups/m6-reward-claim-wireframe.html`
- `docs/mockups/m6-event-node-wireframe.html`
- `docs/mockups/m6-boss-reward-pick-wireframe.html`
- `docs/mockups/m6-defeat-page-wireframe.html`
- `docs/superpowers/specs/2026-06-05-page-contract-harness-audit-design.ko.md`
```

- [ ] **Step 3: Run the final documentation check**

Run:

```powershell
git diff --check
```

Expected:

- No whitespace errors.
- Existing repository-wide LF/CRLF warnings may still appear, but no new mockup file should report trailing whitespace or malformed patch output.

- [ ] **Step 4: Commit the final documentation pass**

```bash
git add docs/mockups/m6-run-start-wireframe.html docs/mockups/m6-node-select-run-flow-wireframe.html docs/mockups/m6-reward-claim-wireframe.html docs/mockups/m6-event-node-wireframe.html docs/mockups/m6-boss-reward-pick-wireframe.html docs/mockups/m6-defeat-page-wireframe.html docs/superpowers/specs/2026-06-05-page-contract-harness-audit-design.ko.md docs/codex-worklog/history_LootingTheLeviathan_2026-06-05.md docs/codex-worklog/complete_LootingTheLeviathan_2026-06-05.md
git commit -m "docs: add phase-first page shell wireframes"
```

## Self-Review

### Spec coverage

- `run_start`, `node_select`, `reward_claim`, `event_node`, `boss_reward_pick`, and `defeat` each have their own file task.
- The dedicated harness design note is produced before any mockup file work.
- `combat`, `reward_reveal`, and `boss_combat` remain deliberately unimplemented in HTML for this pass.

### Placeholder scan

- No `TODO`, `TBD`, or “implement later” placeholders are used in tasks.
- Each file-creation step includes concrete content and concrete verification commands.

### Type consistency

- All mockup filenames match the approved page-shell contract spec exactly.
- The harness note filename stays under `docs/superpowers/specs` and is referenced consistently across tasks.

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-06-05-phase-first-page-shell-wireframes-and-harness-plan.md`. Two execution options:

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?
