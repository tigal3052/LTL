# Tech Stack

## 기본 스택

- **Game Engine**: Godot 4.3 이상
- **Language**: GDScript
- **Testing**: GUT (Godot Unit Test)
- **Data Format**: JSON, JSONL, CSV
- **Primary Target**: Windows PC prototype

## 웹 검토 근거

- Godot 4.3 export 문서는 export templates 설치, export preset, PCK/ZIP, 리소스 필터를 배포 준비의 핵심으로 설명한다.  
  출처: https://docs.godotengine.org/en/4.3/tutorials/export/exporting_projects.html
- Godot logging 문서는 stdout/stderr, verbose stdout, custom logger 등 로그 수집 방식을 제공한다.  
  출처: https://docs.godotengine.org/en/stable/tutorials/scripting/logging.html
- Godot audio buses 문서는 bus와 effect processor를 통해 사운드를 라우팅/가공할 수 있다고 설명한다.  
  출처: https://docs.godotengine.org/en/4.0/tutorials/audio/audio_buses.html
- Godot GPUParticles2D 문서는 2D 파티클 시스템과 ParticleProcessMaterial/ShaderMaterial 기반 효과 구성을 제공한다.  
  출처: https://docs.godotengine.org/en/4.0/classes/class_gpuparticles2d.html

## 일반 게임 개발 스택 대비 누락 검토

| 영역 | 필요 여부 | 현재 반영 | 보강 방침 |
|---|---|---|---|
| 엔진/언어 | 필수 | 있음 | Godot 4.3 이상으로 고정 |
| 단위 테스트 | 필수 | 있음 | GUT, headless 실행 |
| 데이터 테이블 | 필수 | 일부 | JSON schema/validator 추가 |
| 오디오/SFX | 필수 | 부족 | Audio buses, cue table, mixer policy 추가 |
| VFX/파티클 | 필수 | 부족 | GPUParticles2D, Tween, ShaderMaterial 기준 추가 |
| 애니메이션 | 필수 | 부족 | AnimationPlayer, Tween, state cue 추가 |
| 로그/텔레메트리 | 필수 | 일부 | JSONL, custom logger, replay comparison 추가 |
| 리플레이 | 핵심 필수 | 일부 | input log fixture와 replay runner 명시 |
| 저장/설정 | 필수 | 없음 | ConfigFile 또는 JSON save 정책 추가 |
| 배포/export | 필수 | 일부 | export templates, preset, resource filters 추가 |
| 현지화 | 권장 | 없음 | Translation CSV/keys 추가 |
| 접근성 | 권장 | 없음 | 색각 보조, 화면 흔들림, 오디오 볼륨 옵션 추가 |
| 성능 프로파일링 | 권장 | 없음 | Godot profiler, frame budget 기준 추가 |
| 크래시/버그 리포트 | 권장 | 없음 | log bundle export 추가 |

## 권장 폴더 구조

```text
res://
  addons/gut/
  prototype/
    domain/
    data/
    telemetry/
    tools/
    ui/
    vfx/
    audio/
  assets/
    sprites/
    portraits/
    backgrounds/
    sfx/
    music/
    fonts/
  localization/
    ltl_strings.csv
  tests/
    unit/
    integration/
    fixtures/
  export_presets.cfg
```

## 테스트와 자동화

### GUT

- `tests/unit`: domain 단위 테스트.
- `tests/integration`: replay, telemetry, scene smoke.
- headless 실행을 기본으로 한다.

권장 명령:

```text
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/integration
godot --headless --script res://prototype/tools/replay_runner.gd -- --seed 1234 --input res://tests/fixtures/input_logs/basic_clear.json
```

## 데이터와 밸런스

### JSON 파일

- `PrototypeTuning.json`: tick, cooldown, queue, damage, pin, repair.
- `ArtifactTable.json`: item shape, tags, rarity, generated energy, synergy rules.
- `NodeTable.json`: node type, weakness tags, shield/health, hazard pool.
- `VisualTuning.json`: colors, symbols, animation durations, VFX intensity.
- `AudioCueTable.json`: event id, stream path, bus, volume, pitch variation.

### 검증

- Godot 내부 JSON parser 또는 별도 validator script를 둔다.
- 필수 필드 누락은 테스트 실패로 처리한다.
- export 시 `.json`, `.csv`, `.jsonl` 리소스 필터 포함 여부를 확인한다.

## 오디오 스택

### Godot 기능

- `AudioStreamPlayer`, `AudioStreamPlayer2D`
- Audio buses
- bus effects: EQ, compressor, reverb, low-pass

### 권장 bus 구조

```text
Master
  Music
  SFX
    Combat
    UI
    Reward
  Ambience
  Debug
```

### 구현 방침

- 전투 판정 이벤트는 `AudioCueTable.json`의 cue id를 통해 재생한다.
- 같은 SFX 반복 피로를 줄이기 위해 pitch/volume randomization 범위를 둔다.
- 핀 해제와 노드 클리어는 음악/환경음 레이어 변화를 허용한다.
- 옵션에서 Master/Music/SFX/Ambience 볼륨을 분리한다.

### 필수 cue

- `shot_match`
- `shot_mismatch`
- `shot_invalid_cooldown`
- `queue_generated`
- `queue_wasted`
- `pin_released`
- `repair_started`
- `repair_completed`
- `node_clear_crack`
- `reward_reveal`

## VFX/이펙트 스택

### Godot 기능

- `GPUParticles2D`: 균열 파편, 에너지 누수, 보상 빛.
- `ShaderMaterial`: 파동 흐름, 셀 테두리 pulse, 레비아탄 표면 호흡.
- `Tween`: UI 흔들림, scale punch, fade.
- `AnimationPlayer`: 반복 가능한 reward reveal, pin release.

### 구현 방침

- VFX는 도메인 이벤트를 입력으로 받는다.
- VFX가 판정 시간을 바꾸면 안 된다.
- 파동 색과 보상 빛은 전투 판독 색을 가리지 않게 intensity cap을 둔다.
- 저사양 옵션으로 particles amount ratio를 낮출 수 있게 한다.

## 애니메이션 스택

- UI micro animation: Tween.
- 상태 전환: AnimationPlayer.
- 캐릭터 idle/aim/fire/repair: AnimationTree는 M2 이후 필요할 때 도입.
- 프로토타입에서는 스프라이트 시트보다 간단한 frame/tween 조합을 우선한다.

## 로그와 텔레메트리

### 런타임 로그

- Godot stdout/stderr는 개발 로그.
- `Telemetry.gd`는 게임 분석 로그.
- `ReplayLogger.gd`는 input log와 result 비교 전용.

### 파일 포맷

- 이벤트 로그: JSONL 권장.
- 요약 리포트: CSV 또는 JSON.
- replay fixture: JSON.

### 저장 위치

- 개발 중: `user://logs/`
- 테스트 fixture: `res://tests/fixtures/`
- export build: `user://ltl/logs/`

### 필수 로그 레벨

- `debug`: tick, input, VFX cue.
- `info`: node enter, reward, clear/fail.
- `warn`: missing cue, data fallback, replay mismatch.
- `error`: data load failure, invalid domain state.

## 리플레이와 결정성

- 모든 난수는 seed 주입 방식으로 처리한다.
- input log는 `(tick, target_cell, input_type)` 중심으로 기록한다.
- replay runner는 렌더링 없이 domain result를 비교한다.
- VFX/SFX 랜덤 pitch는 도메인 seed와 분리한다.
- HUD/컨트롤러 피드백은 누적 telemetry를 직접 읽지 않고 `beforeSummary -> afterSummary diff` 공통 규칙으로 계산한다.

## 저장과 설정

- 옵션 저장: Godot `ConfigFile` 또는 `user://settings.cfg`.
- 런 저장: P0~M9에서는 완전한 저장/로드보다 run summary 저장을 우선한다.
- 키 설정: Godot InputMap을 사용하고 변경 사항을 settings에 저장한다.
- 로그 export: run_id 단위로 input log, telemetry, summary를 묶는다.

## 배포와 빌드

### Godot export

- export templates 설치가 필요하다.
- Windows preset을 우선 생성한다.
- `.json`, `.csv`, `.jsonl`, `.import` 관련 리소스 포함을 확인한다.
- Debug/Release preset을 분리한다.

### 배포 산출물

- `build/windows/LTL_Prototype.exe`
- `build/windows/LTL_Prototype.pck`
- `build/notes/version.txt`
- `build/notes/data_hashes.json`
- `build/notes/known_issues.md`

### RC 전 검증

- headless GUT 전체 통과.
- replay regression 통과.
- export build 실행.
- 로그 파일 생성 확인.
- 데이터 해시 기록 확인.

## 현지화

- 초기 문서와 UI key는 한국어 기준으로 작성하되, 문자열은 코드에 직접 박지 않는다.
- `localization/ltl_strings.csv`를 사용한다.
- 전투 중 핵심 상태는 텍스트보다 아이콘/패턴 중심으로 설계해 번역 부담을 줄인다.

## 접근성

- 색각 보조: 파동 색마다 패턴/아이콘 제공.
- 화면 흔들림 강도 옵션.
- 이펙트 강도 옵션.
- Master/Music/SFX/Ambience 볼륨 분리.
- UI scale 옵션.

## 성능 기준

- prototype 목표: 1080p 60fps.
- 전투 중 GPUParticles2D amount cap을 둔다.
- 3x10 셀은 개별 Node 과다 생성보다 pooling을 고려한다.
- telemetry는 매 tick 전체 dump가 아니라 이벤트 중심으로 기록한다.
- Godot profiler로 frame time, draw calls, script time을 확인한다.

## 버전 고정 원칙

- Godot minor 버전이 바뀌면 최소 P0/P1 replay 테스트를 다시 실행한다.
- GUT 버전 변경 시 assertion helper와 headless 실행 옵션을 확인한다.
- JSON 데이터 포맷이 바뀌면 마이그레이션 규칙 또는 기본값을 문서화한다.
- export preset이 바뀌면 QA와 deployment 문서를 함께 갱신한다.
