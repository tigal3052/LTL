# M9. Release Candidate

## 목표

외부 공유 가능한 릴리즈 후보 빌드를 준비한다.

## 산출물

- RC build
- release notes
- telemetry/log path guide
- crash/bug report template
- final regression evidence

## 검증 항목

- headless GUT suite 통과
- replay regression 통과
- export smoke test 통과
- 30분 수동 플레이에서 진행 불능 없음
- 데이터 해시와 버전이 로그에 기록됨

## 완료 기준

- 알려진 치명 이슈가 없다.
- 남은 이슈가 문서화되어 있고 우선순위가 있다.
- 다음 작업이 `릴리즈`, `플레이테스트`, `추가 콘텐츠` 중 무엇인지 결정되어 있다.
