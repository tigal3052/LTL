# M6 Known Issues And Sign-Off Gaps

## 2026-06-15 Closure Status

- M6 is closed by explicit user request on 2026-06-15.
- The items below are no longer treated as blockers for creating the M6 completion report, but they remain release-polish / M7+ evidence gaps.
- Do not reinterpret this closure as proof that the unperformed manual screenshot matrix or human readability checks passed.

기준일: 2026-06-12

## 남아 있는 항목

1. 전체 스크린샷 매트릭스가 아직 저장소 증거로 남아 있지 않다.
2. 전투 화면의 "1초 가독성"은 자동 테스트로 증명할 수 없어서 사람 눈 검수가 남아 있다.
3. failure/retry 화면의 설명력이 충분한지는 최종 문구 체감 확인이 남아 있다.
4. 접근성 토글은 코드상 저장과 재적용이 되지만, 실제 체감 강도가 충분한지는 수동 확인이 남아 있다.

## 해석

- 1번은 코드 결함이라기보다 증거 공백이다.
- 2번과 3번은 UX 품질 판정이라 자동 계약만으로는 닫을 수 없다.
- 4번은 기능 자체는 구현되어 있지만, "사용자가 확실히 느낄 정도인가"는 사람 검수가 필요하다.

## 완료 판정 규칙

- 위 4개 중 하나라도 비어 있으면 "M6 코드 구현은 거의 완료"라고는 말할 수 있어도 "M6 최종 완료"라고는 말하지 않는다.
