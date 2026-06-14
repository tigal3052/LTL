# M7 Narrative Integration Replan Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** M7의 "서사와 진행 연동"을 현재 Godot 소스 구조에 맞춰, 전투 리듬을 막지 않는 짧은 내러티브 비트 시스템으로 구현한다.

**Architecture:** 현재 소스에는 `narrative-beats.json`과 `ReleaseContentVocab.project_narrative_beats()`라는 얇은 release-content 기반이 이미 있다. M7은 이 기반을 `NarrativeBeatModel`, `NarrativeHistory`, `SelectNarrativeBeat`, `NarrativeReadModel`, non-blocking toast/log UI, telemetry로 승격하되 phase reducer 결과는 바꾸지 않는 projection 계층으로 유지한다.

**Tech Stack:** Godot 4 GDScript, JSON data tables, existing `HeadlessMiniRun`/`SceneReadModel`/`MainControllerRuntime` flow, current Godot contract runners.

---

## 기존 M7 구현계획 요약 체크리스트

- [ ] **시스템 안정 이후 서사 연결:** 핵심 combat/reward/node 흐름이 굳어진 뒤에 narrative를 얹는다.
- [ ] **전환점 삽입 시점 결정:** 첫 런 시작, node select 진입, reward reveal 직후, 첫 artifact 획득, failure summary, mini-run clear, Leviathan clear 중 허용 지점을 확정한다.
- [ ] **짧은 의미 부여 계층:** 긴 컷신이 아니라 node/reward/failure/clear 화면에 1줄 작전 로그, 무전, subtitle, run log를 붙인다.
- [ ] **core reducer 오염 금지:** narrative trigger와 read-model은 domain replay 결과, combat damage, reward roll, node generation을 바꾸지 않는다.
- [ ] **핵심 beat 제공:** `intro_contract`, `first_valid_hit`, `first_artifact`, `first_failure`, `first_clear`, `hunt_tension`을 구현한다.
- [ ] **용어/톤 정리:** 기본 UI는 "채집/외피/파동/마력장/균열/침습도/회수/고정핀" 중심으로 잡고, "사냥"은 금기/갈등어로 의도적으로만 사용한다.
- [ ] **분리된 파일군:** `models/NarrativeBeat.gd`, `models/NarrativeHistory.gd`, `vocabulary/narrative/*`, `ui/read_models/NarrativeReadModel.gd`, `scenes/narrative/*`, `tests/test_narrative_contract.gd`를 둔다.
- [ ] **자동 테스트:** trigger 위치, shown-once persist, replay invariance, reward 선택 비차단, failure summary 동시 표시, terminology, text overflow를 검증한다.
- [ ] **Telemetry:** `narrative_beat_selected`, `narrative_beat_shown`, `narrative_beat_skipped`, `narrative_history_updated`를 기록한다.
- [ ] **사용자 결정 사항:** 내러티브 톤, 캐릭터 역할, "채집 vs 사냥" 첫 명시 시점, 레비아탄 정체성 차별화 축을 확정한다.

## 현재 소스 비교 분석

| 영역 | 현재 소스 상태 | M7 계획 대비 판정 |
|---|---|---|
| Narrative data | `app-LTL/src/data/narrative-beats.json`에 5개 beat가 존재한다. | 부분 충족. 데이터는 있으나 기존 M7의 `intro_contract`, `first_artifact`, `hunt_tension` 명명/의도와 다르다. |
| Release content hook | `ReleaseContentVocab.load_content_bundle()`이 `narrativeBeats`를 로드하고, `project_narrative_beats()`가 side-effect-free projection을 제공한다. | 좋은 출발점. 다만 M7 전용 model/history/read-model로 분리되어 있지 않다. |
| Trigger matching | `ReleaseContentVocab._beat_matches()`가 `first_run_start`, `first_reward`, `first_failure`, `first_clear`, `leviathan_unlocked`를 판정한다. | 부분 충족. `first_valid_hit`, `first_artifact`, `hunt_tension`이 빠져 있고, `first_failure`는 현재 state의 `result` 필드 의존이 실제 `run_complete + failed` 흐름과 어긋날 수 있다. |
| Progress/history | `HeadlessMiniRun`과 `SceneReadModel`은 `progress.clearedLeviathanIds`를 운반한다. `RunGrowthState`는 reward/artifact/base unlock 중심이다. | 미충족. `narrativeSeenBeatIds` 또는 동등한 history 저장 위치가 없다. |
| UI insertion points | `MainControllerRuntime`은 reward ceremony, phase log, page id decoration, telemetry emit 지점이 있다. `PageSceneModelBuilder`는 reward/defeat/clear page model을 만든다. | 부분 충족. 삽입 지점은 있으나 narrative read model을 받거나 render하는 표면이 없다. |
| Reward flow | reward reveal overlay와 tray review 단계가 이미 존재한다. | 주의 필요. M7은 reward 선택을 반복 컷신으로 지연시키면 안 되므로 첫 artifact beat는 tray-ready 이후 non-blocking으로 붙여야 한다. |
| Failure/clear flow | `FailureReadModel`과 `PageSceneModelBuilder`가 defeat/clear 문구를 투사한다. | 부분 충족. 실패/클리어 문구는 있으나 M7의 "금기/채집" tension beat는 아직 별도 projection이 아니다. |
| Telemetry | `_emit_ui_telemetry()`와 `BuildRewardTelemetry.gd`가 이미 있다. | 부분 충족. narrative telemetry builder가 없다. |
| Tests | `test_release_content_contract.gd`가 narrative beats side-effect-free 최소 계약을 갖고 있다. | 부분 충족. M7 trigger/history/UI/telemetry/replay invariance 테스트가 없다. |
| Terminology | 한국어/영어 i18n에 `전투`, `전리품`, `Combat`, `Loot`가 기본 UI 문구로 남아 있다. | 미충족. M7의 용어 정책과 충돌한다. 단, 전면 치환보다 화면별 허용 목록과 전환 규칙을 먼저 정의해야 한다. |

## 수정이 필요한 부분

- `app-LTL/src/data/narrative-beats.json`
  - 현재 `first_run_start`는 "안전한 흉터부터 고르세요"라서 M7의 "LTL은 사냥이 아니라 채집을 명분으로 삼는다"를 직접 전달하지 않는다.
  - 현재 `first_reward`는 전리품/전투 리듬 설명이라서 M7의 "첫 artifact 후 주인공의 살의/단장의 제지" beat와 다르다.
  - `first_valid_hit`, `hunt_tension`에 해당하는 beat가 없다.
  - `speaker`, `textKo`, `textEn`, `shownOnce`, `sideEffectFree`는 좋지만 `screenId`, `triggerPhase`, `priority`, `displayMode`, `skipInputAllowed`가 없다.

- `app-LTL/src/vocabulary/ReleaseContentVocab.gd`
  - narrative projection이 release content facade 안에 섞여 있어 M7의 `vocabulary/narrative/*` 경계와 맞지 않는다.
  - `_beat_matches("first_failure")`는 `state.result`만 보므로 현재 `run_complete + failed + failureReason` scene/read-model 경계에서 누락될 수 있다.
  - `first_reward`는 `growth.rewardHistory`가 비어 있지 않을 때만 뜨는데, 실제 "첫 artifact 획득 후" 기준은 reward claim effect 또는 artifact discovery와 연결되어야 한다.

- `app-LTL/src/models/RunGrowthState.gd` 또는 progress state
  - shown-once 저장소가 없다.
  - M7에는 save/load 후 중복 발생 방지가 있으므로 `progress.narrativeSeenBeatIds`처럼 replay/domain 결과와 분리된 progress history가 필요하다.

- `app-LTL/src/ui/SceneReadModel.gd`
  - phase/stage/reward/progress를 투사하지만 narrative 후보 또는 seen state는 노출하지 않는다.
  - narrative projection을 넣더라도 `phase`, `combat`, `pendingRewards`, `candidates` 값 자체가 바뀌지 않게 테스트가 필요하다.

- `app-LTL/src/ui/PageSceneModelBuilder.gd`
  - reward/defeat/clear page 문구는 고정 i18n subtitle 중심이다.
  - `narrative` read model을 받는 선택적 field가 없어 페이지별 narrative slot을 구성할 수 없다.

- `app-LTL/src/MainControllerRuntime.gd`
  - phase transition log와 reward ceremony hook은 있으나 narrative selection, shown/skipped telemetry, history update가 없다.
  - reward ceremony 중 입력 제한 로직이 많으므로, narrative는 `_reward_ceremony_active()` 동안 뜨지 않거나 skip 가능한 toast로 제한해야 한다.

- `app-LTL/src/data/i18n/text-ko.json`, `app-LTL/src/data/i18n/text-en.json`
  - `전투`, `전리품`, `Combat`, `Loot`가 기본 UI에 남아 있다.
  - M7의 terminology test는 무조건 금지가 아니라 page/phase별 허용 목록을 먼저 고정해야 한다.

- `app-LTL/tests/godot_contract_runner.gd`
  - narrative scripts와 `test_narrative_contract.gd`를 로딩/실행하지 않는다.

## 개선해야 될 사항

- release-content 내부 helper로 남은 narrative logic을 전용 `vocabulary/narrative` capsule로 이동하고, 기존 `ReleaseContentVocab.project_narrative_beats()`는 호환 wrapper로 축소한다.
- beat id를 M7 용어로 정규화한다: `intro_contract`, `first_valid_hit`, `first_artifact`, `first_failure`, `first_clear`, `hunt_tension`.
- narrative history는 `progress` 계층에 저장한다. `growth.rewardHistory`는 보상 경제 이력이라 narrative shown-once와 섞지 않는다.
- first artifact trigger는 reward table의 artifact/relic claim 또는 `artifactDiscovery` 변화와 연결한다.
- failure/clear beat는 `PageSceneModelBuilder`의 defeat/clear model에 붙이되 기존 failure cause/tip을 지우지 않는다.
- first valid hit는 combat 중 입력을 막지 않는 HUD subtitle 1줄로만 표시하고, 길거나 modal인 UI는 금지한다.
- telemetry builder를 별도 파일로 둔다. `_emit_ui_telemetry()`는 그대로 재사용한다.
- terminology test는 `text-ko.json`과 `text-en.json`을 스캔하되, `phase.combat`처럼 현재 코드 경계상 즉시 바꾸기 어려운 key는 explicit allowlist에 넣고 M7 후속 정리 대상으로 표시한다.
- UI overflow 검증은 기존 `run_main_layout_audit_contract.gd`, `run_i18n_localization_smoke.gd`, `ui_text_tooltip_suite.gd` 성격의 테스트에 붙인다.

## 파일 구조 계획

- Modify: `app-LTL/src/data/narrative-beats.json`
  - M7 beat id/schema/copy 정규화.
- Create: `app-LTL/src/models/NarrativeBeat.gd`
  - beat dictionary validation and language projection.
- Create: `app-LTL/src/models/NarrativeHistory.gd`
  - `seenBeatIds` lookup, mark, serialize helpers.
- Create: `app-LTL/src/vocabulary/narrative/SelectNarrativeBeat.gd`
  - state/phase/history 기반 beat selection.
- Create: `app-LTL/src/vocabulary/narrative/MarkNarrativeSeen.gd`
  - progress history update without touching domain combat/reward fields.
- Create: `app-LTL/src/vocabulary/narrative/BuildNarrativeTelemetry.gd`
  - selected/shown/skipped/history telemetry payloads.
- Create: `app-LTL/src/ui/read_models/NarrativeReadModel.gd`
  - beat + scene snapshot을 UI-safe model로 투사.
- Create: `app-LTL/src/scenes/narrative/NarrativeToast.gd`
  - non-blocking toast/log surface.
- Modify: `app-LTL/src/ui/MainViewRuntime.gd`
  - toast instance creation/rendering.
- Modify: `app-LTL/src/ui/PageSceneModelBuilder.gd`
  - defeat/clear/reward page model에 optional narrative slot 추가.
- Modify: `app-LTL/src/MainControllerRuntime.gd`
  - page/phase transition 후 narrative selection, telemetry, history update.
- Modify: `app-LTL/src/vocabulary/ReleaseContentVocab.gd`
  - narrative functions를 새 capsule로 위임.
- Create: `app-LTL/tests/test_narrative_contract.gd`
  - trigger/history/replay invariance/terminology tests.
- Modify: `app-LTL/tests/godot_contract_runner.gd`
  - narrative test suite load/run 등록.
- Modify: `app-LTL/tests/run_i18n_localization_smoke.gd`
  - narrative i18n projection smoke 추가.

---

### Task 1: Narrative Data Contract 정규화

**Files:**
- Modify: `app-LTL/src/data/narrative-beats.json`
- Modify: `app-LTL/src/vocabulary/ReleaseContentVocab.gd`
- Modify: `app-LTL/tests/test_release_content_contract.gd`

- [ ] **Step 1: Write failing content-shape tests**

Add assertions in `test_release_content_contract.gd`:

```gdscript
func test_narrative_beats_cover_m7_core_beats() -> void:
	var bundle: Dictionary = ReleaseContentVocabScript.load_content_bundle()
	var ids := {}
	for beat in bundle.get("narrativeBeats", []):
		ids[str(beat.get("id", ""))] = true
	for required_id in ["intro_contract", "first_valid_hit", "first_artifact", "first_failure", "first_clear", "hunt_tension"]:
		_assert(ids.has(required_id), "M7 narrative beat exists: %s" % required_id)

func test_narrative_beats_have_screen_and_skip_contract() -> void:
	var bundle: Dictionary = ReleaseContentVocabScript.load_content_bundle()
	for beat in bundle.get("narrativeBeats", []):
		_assert(not str(beat.get("screenId", "")).is_empty(), "narrative beat has screenId: %s" % str(beat.get("id", "")))
		_assert(not str(beat.get("displayMode", "")).is_empty(), "narrative beat has displayMode: %s" % str(beat.get("id", "")))
		_assert(beat.has("skipInputAllowed"), "narrative beat declares skipInputAllowed: %s" % str(beat.get("id", "")))
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1
```

Expected: FAIL until the six M7 beat ids and new required fields exist.

- [ ] **Step 3: Update `narrative-beats.json`**

Replace the current five rows with six M7 rows using this schema:

```json
{
  "id": "intro_contract",
  "trigger": "first_run_start",
  "screenId": "node_select",
  "triggerPhase": "node_select",
  "shownOnce": true,
  "speaker": "Captain",
  "displayMode": "operation_log",
  "skipInputAllowed": true,
  "textKo": "LTL은 레비아탄을 사냥하지 않는다. 살아 있는 외피에서 필요한 것만 채집하고 철수한다.",
  "textEn": "LTL does not hunt leviathans. We collect only what the living shell yields, then withdraw.",
  "sideEffectFree": true
}
```

Add equivalent rows for:

- `first_valid_hit`: `trigger=first_valid_hit`, `screenId=battle`, `displayMode=hud_subtitle`.
- `first_artifact`: `trigger=first_artifact`, `screenId=reward`, `displayMode=radio_log`.
- `first_failure`: `trigger=first_failure`, `screenId=defeat`, `displayMode=summary_log`.
- `first_clear`: `trigger=first_clear`, `screenId=clear`, `displayMode=run_log`.
- `hunt_tension`: `trigger=leviathan_clear`, `screenId=clear`, `displayMode=post_run_log`.

- [ ] **Step 4: Tighten release content validation**

In `ReleaseContentVocab.validate_content_bundle()`, change narrative required fields to:

```gdscript
_validate_required_fields(bundle.get("narrativeBeats", []), "narrativeBeats", ["id", "trigger", "screenId", "triggerPhase", "displayMode", "textKo", "textEn", "sideEffectFree", "skipInputAllowed"], errors)
```

- [ ] **Step 5: Run focused validation**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1
```

Expected: PASS for release-content validation, with later narrative runtime tests still missing.

### Task 2: Narrative Model, History, and Selection Capsules

**Files:**
- Create: `app-LTL/src/models/NarrativeBeat.gd`
- Create: `app-LTL/src/models/NarrativeHistory.gd`
- Create: `app-LTL/src/vocabulary/narrative/SelectNarrativeBeat.gd`
- Create: `app-LTL/src/vocabulary/narrative/MarkNarrativeSeen.gd`
- Create: `app-LTL/tests/test_narrative_contract.gd`

- [ ] **Step 1: Write failing trigger/history tests**

Create `test_narrative_contract.gd` with:

```gdscript
extends RefCounted

const ReleaseContentVocabScript = preload("res://src/vocabulary/ReleaseContentVocab.gd")
const SelectNarrativeBeatScript = preload("res://src/vocabulary/narrative/SelectNarrativeBeat.gd")
const MarkNarrativeSeenScript = preload("res://src/vocabulary/narrative/MarkNarrativeSeen.gd")

var failures: Array[String] = []

func run_all_tests() -> Dictionary:
	failures.clear()
	test_intro_contract_selects_only_first_node_select()
	test_seen_once_beat_does_not_repeat()
	test_mark_seen_updates_progress_only()
	test_failure_and_clear_match_run_complete_scene()
	return {"ok": failures.is_empty(), "errors": failures}

func test_intro_contract_selects_only_first_node_select() -> void:
	var beats: Array = _beats()
	var beat: Dictionary = SelectNarrativeBeatScript.select({"phase": "node_select", "stageIndex": 0}, beats, {})
	_assert_eq(str(beat.get("id", "")), "intro_contract", "intro contract selected on first node select")
	var later: Dictionary = SelectNarrativeBeatScript.select({"phase": "node_select", "stageIndex": 1}, beats, {})
	_assert_eq(later.is_empty(), true, "intro contract does not select on later stages")

func test_seen_once_beat_does_not_repeat() -> void:
	var beat: Dictionary = SelectNarrativeBeatScript.select({"phase": "node_select", "stageIndex": 0}, _beats(), {"intro_contract": true})
	_assert_eq(beat.is_empty(), true, "seen shown-once beat does not repeat")

func test_mark_seen_updates_progress_only() -> void:
	var progress := {"clearedLeviathanIds": ["ossuary_tortoise"]}
	var next: Dictionary = MarkNarrativeSeenScript.mark_seen(progress, "intro_contract")
	_assert_eq(next.get("clearedLeviathanIds", []), ["ossuary_tortoise"], "mark seen preserves cleared ids")
	_assert(next.get("narrativeSeenBeatIds", []).has("intro_contract"), "mark seen stores beat id")
	_assert_eq(progress.has("narrativeSeenBeatIds"), false, "mark seen does not mutate original progress")

func test_failure_and_clear_match_run_complete_scene() -> void:
	var failed: Dictionary = SelectNarrativeBeatScript.select({"phase": "run_complete", "failed": true}, _beats(), {})
	_assert_eq(str(failed.get("id", "")), "first_failure", "failure beat selects on failed run_complete")
	var cleared: Dictionary = SelectNarrativeBeatScript.select({"phase": "run_complete", "failed": false, "runComplete": true}, _beats(), {})
	_assert_eq(str(cleared.get("id", "")), "first_clear", "clear beat selects on successful run_complete")

func _beats() -> Array:
	return ReleaseContentVocabScript.load_content_bundle().get("narrativeBeats", [])

func _assert(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1
```

Expected: FAIL because `vocabulary/narrative/*` files do not exist and runner is not wired yet.

- [ ] **Step 3: Implement `NarrativeHistory.gd`**

Create:

```gdscript
class_name NarrativeHistory
extends RefCounted

static func from_progress(progress: Dictionary) -> Dictionary:
	var seen := {}
	for beat_id in progress.get("narrativeSeenBeatIds", []):
		seen[str(beat_id)] = true
	return seen

static func mark_seen(progress: Dictionary, beat_id: String) -> Dictionary:
	var next := progress.duplicate(true)
	var seen_ids: Array = next.get("narrativeSeenBeatIds", []).duplicate(true)
	if not seen_ids.has(beat_id):
		seen_ids.append(beat_id)
	next["narrativeSeenBeatIds"] = seen_ids
	return next
```

- [ ] **Step 4: Implement selection and mark wrappers**

`SelectNarrativeBeat.gd`:

```gdscript
class_name SelectNarrativeBeat
extends RefCounted

static func select(state: Dictionary, beats: Array, history: Dictionary = {}) -> Dictionary:
	for beat in beats:
		if not (beat is Dictionary):
			continue
		var id := str(beat.get("id", ""))
		if bool(beat.get("shownOnce", true)) and bool(history.get(id, false)):
			continue
		if not bool(beat.get("sideEffectFree", false)):
			continue
		if _matches(str(beat.get("trigger", "")), state):
			return beat.duplicate(true)
	return {}

static func _matches(trigger: String, state: Dictionary) -> bool:
	match trigger:
		"first_run_start":
			return str(state.get("phase", "")) == "node_select" and int(state.get("stageIndex", 0)) == 0
		"first_valid_hit":
			var combat: Dictionary = state.get("combat", {}) if state.get("combat", {}) is Dictionary else {}
			var summary: Dictionary = combat.get("summary", {}) if combat.get("summary", {}) is Dictionary else {}
			return int(summary.get("shots_hit_match", 0)) > 0
		"first_artifact":
			var growth: Dictionary = state.get("growth", {}) if state.get("growth", {}) is Dictionary else {}
			return str(state.get("phase", "")) == "reward_loot" and not Array(growth.get("artifactDiscovery", [])).is_empty()
		"first_failure":
			return str(state.get("phase", "")) == "run_complete" and bool(state.get("failed", false))
		"first_clear":
			return str(state.get("phase", "")) == "run_complete" and bool(state.get("runComplete", false)) and not bool(state.get("failed", false))
		"leviathan_clear":
			return str(state.get("phase", "")) == "run_complete" and bool(state.get("runComplete", false)) and not bool(state.get("failed", false))
	return false
```

`MarkNarrativeSeen.gd`:

```gdscript
class_name MarkNarrativeSeen
extends RefCounted

const NarrativeHistoryScript = preload("res://src/models/NarrativeHistory.gd")

static func mark_seen(progress: Dictionary, beat_id: String) -> Dictionary:
	if beat_id.is_empty():
		return progress.duplicate(true)
	return NarrativeHistoryScript.mark_seen(progress, beat_id)
```

- [ ] **Step 5: Wire test runner**

In `godot_contract_runner.gd`, add:

```gdscript
func _test_narrative_contracts() -> void:
	var TestNarrativeClass = load("res://tests/test_narrative_contract.gd")
	_assert(TestNarrativeClass != null, "test narrative contract loads")
	if TestNarrativeClass == null:
		return
	var tester = TestNarrativeClass.new()
	var test_res = tester.run_all_tests()
	_assert(test_res["ok"], "narrative contract tests passed")
	if not test_res["ok"]:
		for err in test_res["errors"]:
			failures.append("Narrative test failed: %s" % err)
```

Call `_test_narrative_contracts()` from `_run_contracts()` before release-content tests.

### Task 3: Projection and Replay Invariance

**Files:**
- Create: `app-LTL/src/ui/read_models/NarrativeReadModel.gd`
- Modify: `app-LTL/src/ui/SceneReadModel.gd`
- Modify: `app-LTL/src/vocabulary/ReleaseContentVocab.gd`
- Modify: `app-LTL/tests/test_narrative_contract.gd`

- [ ] **Step 1: Add replay invariance test**

Append:

```gdscript
func test_narrative_projection_does_not_change_domain_snapshot() -> void:
	var state := {"phase": "node_select", "stageIndex": 0, "candidates": [{"id": "normal"}], "progress": {}}
	var before := state.duplicate(true)
	var beat := SelectNarrativeBeatScript.select(state, _beats(), {})
	_assert(not beat.is_empty(), "narrative beat selected for invariance test")
	_assert_eq(state, before, "narrative selection does not mutate state")
```

- [ ] **Step 2: Implement `NarrativeReadModel.gd`**

Create:

```gdscript
class_name NarrativeReadModel
extends RefCounted

static func project(beat: Dictionary, locale: String = "ko") -> Dictionary:
	if beat.is_empty():
		return {"visible": false}
	var text_key := "textKo" if locale == "ko" else "textEn"
	return {
		"visible": true,
		"beatId": str(beat.get("id", "")),
		"speaker": str(beat.get("speaker", "")),
		"text": str(beat.get(text_key, beat.get("textKo", ""))),
		"displayMode": str(beat.get("displayMode", "toast")),
		"screenId": str(beat.get("screenId", "")),
		"skipInputAllowed": bool(beat.get("skipInputAllowed", true))
	}
```

- [ ] **Step 3: Keep `SceneReadModel` pure**

Do not call narrative selection from `SceneReadModel.create()` yet. Instead, expose enough state that `MainControllerRuntime` can select narrative after scene decoration:

```gdscript
"growth": run_snapshot.get("growth", {}).duplicate(true),
"progress": run_snapshot.get("progress", {}).duplicate(true)
```

If `growth` is already omitted from the read model, add it as a cloned field and assert no combat/reward fields change.

- [ ] **Step 4: Delegate old release helper**

Keep `ReleaseContentVocab.project_narrative_beats()` as a wrapper:

```gdscript
const SelectNarrativeBeatScript = preload("res://src/vocabulary/narrative/SelectNarrativeBeat.gd")

static func project_narrative_beats(state: Dictionary, beats: Array, history: Dictionary = {}) -> Array:
	var beat := SelectNarrativeBeatScript.select(state, beats, history)
	return [] if beat.is_empty() else [beat]
```

### Task 4: Runtime Hook, Non-Blocking UI, and Telemetry

**Files:**
- Create: `app-LTL/src/vocabulary/narrative/BuildNarrativeTelemetry.gd`
- Create: `app-LTL/src/scenes/narrative/NarrativeToast.gd`
- Modify: `app-LTL/src/ui/MainViewRuntime.gd`
- Modify: `app-LTL/src/MainControllerRuntime.gd`
- Modify: `app-LTL/tests/test_narrative_contract.gd`

- [ ] **Step 1: Add telemetry builder tests**

Add assertions:

```gdscript
func test_narrative_telemetry_payloads_have_required_fields() -> void:
	var BuildNarrativeTelemetryScript = load("res://src/vocabulary/narrative/BuildNarrativeTelemetry.gd")
	var payload: Dictionary = BuildNarrativeTelemetryScript.build_shown("intro_contract", "node_select", "node_select", true, 2400, false)
	_assert_eq(str(payload.get("event", "")), "narrative_beat_shown", "shown telemetry event name")
	for key in ["beat_id", "screen_id", "trigger_phase", "shown_once", "display_duration_ms", "skip_input"]:
		_assert(payload.has(key), "shown telemetry has %s" % key)
```

- [ ] **Step 2: Implement telemetry builder**

Create:

```gdscript
class_name BuildNarrativeTelemetry
extends RefCounted

static func build_selected(beat_id: String, screen_id: String, trigger_phase: String, shown_once: bool) -> Dictionary:
	return _base("narrative_beat_selected", beat_id, screen_id, trigger_phase, shown_once, 0, false)

static func build_shown(beat_id: String, screen_id: String, trigger_phase: String, shown_once: bool, display_duration_ms: int, skip_input: bool) -> Dictionary:
	return _base("narrative_beat_shown", beat_id, screen_id, trigger_phase, shown_once, display_duration_ms, skip_input)

static func build_skipped(beat_id: String, screen_id: String, trigger_phase: String, shown_once: bool, skip_input: bool) -> Dictionary:
	return _base("narrative_beat_skipped", beat_id, screen_id, trigger_phase, shown_once, 0, skip_input)

static func build_history_updated(beat_id: String, screen_id: String, trigger_phase: String, shown_once: bool) -> Dictionary:
	return _base("narrative_history_updated", beat_id, screen_id, trigger_phase, shown_once, 0, false)

static func _base(event_name: String, beat_id: String, screen_id: String, trigger_phase: String, shown_once: bool, duration_ms: int, skip_input: bool) -> Dictionary:
	return {
		"event": event_name,
		"beat_id": beat_id,
		"screen_id": screen_id,
		"trigger_phase": trigger_phase,
		"shown_once": shown_once,
		"display_duration_ms": duration_ms,
		"skip_input": skip_input
	}
```

- [ ] **Step 3: Implement toast view**

`NarrativeToast.gd` should extend `PanelContainer`, set `mouse_filter = Control.MOUSE_FILTER_IGNORE`, own one speaker label and one text label, and expose:

```gdscript
func render(model: Dictionary) -> void:
	visible = bool(model.get("visible", false))
	if not visible:
		return
	speaker_label.text = str(model.get("speaker", ""))
	body_label.text = str(model.get("text", ""))
```

- [ ] **Step 4: Install toast in MainViewRuntime**

Add a `narrative_toast` field, instantiate it in `_ready()`, and expose:

```gdscript
func render_narrative(model: Dictionary) -> void:
	if narrative_toast != null and narrative_toast.has_method("render"):
		narrative_toast.render(model)
```

The toast must not hide or disable action buttons.

- [ ] **Step 5: Select narrative in MainControllerRuntime**

After `_decorate_scene(scene)` and before `view.render_scene(...)`, call a helper:

```gdscript
func _sync_narrative_for_scene(scene: Dictionary) -> void:
	if _reward_ceremony_active():
		view.render_narrative({"visible": false})
		return
	var history := NarrativeHistoryScript.from_progress(campaign_progress)
	var beat := SelectNarrativeBeatScript.select(scene, _narrative_beats(), history)
	var model := NarrativeReadModelScript.project(beat, TextCatalogScript.locale())
	view.render_narrative(model)
	if beat.is_empty():
		return
	_emit_ui_telemetry(BuildNarrativeTelemetryScript.build_selected(str(beat.get("id", "")), str(beat.get("screenId", "")), str(beat.get("triggerPhase", "")), bool(beat.get("shownOnce", true))))
	campaign_progress = MarkNarrativeSeenScript.mark_seen(campaign_progress, str(beat.get("id", "")))
	_emit_ui_telemetry(BuildNarrativeTelemetryScript.build_history_updated(str(beat.get("id", "")), str(beat.get("screenId", "")), str(beat.get("triggerPhase", "")), bool(beat.get("shownOnce", true))))
```

Use the existing `_emit_ui_telemetry()` printer.

### Task 5: Page Model Integration and Terminology Pass

**Files:**
- Modify: `app-LTL/src/ui/PageSceneModelBuilder.gd`
- Modify: `app-LTL/src/data/i18n/text-ko.json`
- Modify: `app-LTL/src/data/i18n/text-en.json`
- Modify: `app-LTL/tests/test_narrative_contract.gd`
- Modify: `app-LTL/tests/run_i18n_localization_smoke.gd`

- [ ] **Step 1: Add terminology test with allowlist**

Add a test that scans `text-ko.json` and flags:

```gdscript
var ko_forbidden := ["사냥", "처치", "사망"]
```

For `전투` and `전리품`, use an explicit temporary allowlist of keys, then reduce that allowlist as copy is changed to `채굴`, `회수품`, `유물`, `외피`, `추락`.

- [ ] **Step 2: Replace high-impact default copy**

Change visible player-facing keys first:

- `node.select.header`: "전투 시작" -> "채굴 시작"
- `panel.log.ready`: "전투를 시작하세요" -> "채굴을 시작하세요"
- `main.node_select.subtitle`: "전투 시작" -> "채굴 시작"
- `failure.victory.cause`: "전리품" -> "회수품" or "유물"
- `log.reward.ceremony_starting`: "전리품" -> "회수품"
- English equivalents: "Start Combat" -> "Start Mining", "Loot" where needed -> "Recovered artifacts" or "haul".

- [ ] **Step 3: Feed page narrative slots**

In `PageSceneModelBuilder.project()`, preserve existing fields and allow `scene.get("narrative", {})` to pass through:

```gdscript
var narrative: Dictionary = scene.get("narrative", {}) if scene.get("narrative", {}) is Dictionary else {}
model["narrative"] = narrative.duplicate(true)
```

Use this only for page scenes; combat HUD still uses toast.

### Task 6: Verification and Manual QA Evidence

**Files:**
- Modify: `app-LTL/tests/godot_contract_runner.gd`
- Modify: `app-LTL/tests/run_main_start_flow_contract.gd`
- Optional Modify: `app-LTL/tests/run_main_layout_audit_contract.gd`
- Create or update: `docs/m7-manual-signoff-checklist.ko.md`

- [ ] **Step 1: Add flow assertions**

In `run_main_start_flow_contract.gd`, assert:

- Intro toast appears on first node select and does not block route selection.
- Reward page can still claim/place rewards when narrative is shown.
- Defeat page shows both failure cause/tip and narrative beat.
- Clear page shows clear beat.

- [ ] **Step 2: Add layout assertions**

In `run_main_layout_audit_contract.gd`, assert visible narrative toast/control stays inside viewport at canonical desktop size and does not cover action bar hit targets.

- [ ] **Step 3: Run focused checks**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-ltl-quality-gate.ps1
```

Expected:

- `test_narrative_contract.gd` passes.
- Existing release content and UI read model suites still pass.
- No replay summary changes except optional narrative projection fields.

- [ ] **Step 4: Manual QA checklist**

Create `docs/m7-manual-signoff-checklist.ko.md` with:

- 전투 중 긴 대사 없음.
- node/reward/failure/clear 문구가 흐름을 막지 않음.
- 첫 화면 또는 첫 reward 후 플레이어가 "채집 vs 사냥" 차이를 설명할 수 있음.
- failure/clear 문구가 다음 시도를 유도함.
- 같은 shown-once beat가 반복되지 않음.
- 한국어/영어 텍스트가 UI 밖으로 넘치지 않음.

## 실행 순서 요약

1. 데이터/schema부터 고정한다.
2. narrative selection/history를 pure vocabulary로 분리한다.
3. read-model/UI/telemetry를 non-blocking으로 붙인다.
4. terminology를 allowlist 기반으로 정리한다.
5. contract runner와 flow/layout QA로 완료 증거를 남긴다.

## 우선 결정이 필요한 항목

- M7 톤은 우선 **건조한 작전 로그 + 단장 무전 1줄**을 기본값으로 제안한다.
- "채집 vs 사냥"의 첫 명시는 `intro_contract`에서 바로 보여 주는 안을 기본값으로 제안한다.
- 캐릭터 역할은 이번 M7에서는 대사 중심으로만 쓰고, 고유 능력/시작 유물 차이는 후속 캐릭터 시스템에서 다룬다.
- 레비아탄 정체성은 이번 M7에서는 biome/copy/read-model 차별화에 머물고, 보상 풀/환경 규칙 차별화는 M8 이후로 넘긴다.

## Self-Review

- Spec coverage: 기존 M7의 삽입 위치, 핵심 beat, architecture separation, telemetry, tests, terminology, manual QA를 모두 task에 연결했다.
- Placeholder scan: TBD/TODO/나중에 구현 같은 placeholder를 쓰지 않았다.
- Type consistency: `narrativeSeenBeatIds`, `beatId`, `screenId`, `triggerPhase`, `displayMode`, `skipInputAllowed` naming을 데이터, model, telemetry에서 일관되게 사용했다.
