# M6 Manual Sign-Off Checklist

## Current Status

- 자동 검증 기준 핵심 formal gate는 현재 그린이다.
- 하지만 M6를 최종 완료라고 부르기에는 아직 이르다.
- 남은 이유:
  - 수동 페이지별 QA와 스크린샷 매트릭스가 아직 정식 증거로 남지 않았다.
  - 활성 런타임과 과거 잔류 소스 분리 수술이 아직 진행 전이다.
  - 하네스가 실제 대형 런타임 파일을 막지 못한 원인 분석과 재발 방지 적용이 아직 남아 있다.

## Manual Checklist

- [ ] `character_select`: 1280x720, 1440x900, 1920x1080에서 보드/로스터/계속 버튼이 모두 viewport 안에 남는다.
- [ ] `leviathan_select`: 대상 리본, CTA, 설명 카피가 겹치지 않고 `Looting Start` 버튼이 즉시 보인다.
- [ ] `node_select` stage 1/2/boss: 경로 버튼, 노드 설명, 배경 장면, 공유 백팩 도킹 위치가 화면별로 깨지지 않는다.
- [ ] 전투 HUD: 좌측 상태 컬럼, 중앙 백팩, 우측 로그가 1280x720 이상에서 잘리지 않고 1초 안에 상태 파악이 된다.
- [ ] 전투 하단 액션 버튼: `Reset`, `Start`, `Hold Fire`, `Claim Rewards` 상태가 phase/page에 맞게만 노출된다.
- [ ] 보상 세레모니: reveal 연출이 안전영역 안에서 동작하고 confirm prompt와 카드가 겹치지 않는다.
- [ ] 보상 트레이: reward cloud, workspace, inspector, discard, confirm 5개 영역이 모두 viewport 안에 남는다.
- [ ] 보상 트레이 inspect 전환: reward meta 클릭, backpack slot 클릭을 번갈아 해도 보드 폭과 높이가 흔들리지 않는다.
- [ ] 보상 하단 카드: discard/confirm helper copy가 비어 있을 때 빈 제목줄이나 세로 스크롤바가 다시 생기지 않는다.
- [ ] defeat/clear/boss reward: 이전 손실 이유와 다음 행동이 명확하게 읽히고 restart 흐름이 끊기지 않는다.
- [ ] 접근성 토글: shake / flash / particle / assist 관련 토글이 실제 연출에 반영되고 재진입 후에도 유지된다.
- [ ] i18n: 새로 추가된 M6 페이지 텍스트와 버튼 라벨이 한국어/영문 카탈로그에서 빠지지 않는다.
- [ ] 스크린샷 매트릭스: 지원 해상도별 대표 화면 캡처를 남기고 남은 이슈를 명시한다.

## Completion Gate Reminder

- 전투 상호작용 상태가 색상만 보지 않아도 빠르게 판독되어야 한다.
- reward ceremony, tray review, node map, backpack가 하나의 시각 언어로 읽혀야 한다.
- 실패/재시도 페이지가 이전 손실과 다음 시도를 명확히 설명해야 한다.
- 접근성 토글은 실제 동작과 영속성까지 검증되어야 한다.
- 테마/아트킷은 스크립트별 임시 오버라이드가 아니라 재사용 가능한 체계여야 한다.
- 스크린샷 매트릭스와 잔여 이슈 목록이 함께 있어야 최종 완료 판정을 내릴 수 있다.
