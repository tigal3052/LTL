# M1. 코어 도메인 안정화

## 목표

프로토타입에서 검증된 순수 로직을 정식 구현 경계로 옮기고 테스트 계약을 안정화한다.

## 산출물

- 정식 `domain` 모듈
- 데이터 로더/validator
- replay regression suite
- 도메인 API 문서

## TDD 대상

- P1/P4 fixture 모두 통과
- JSON 필수 필드 누락 검사
- 도메인 snapshot backward compatibility

## 완료 기준

- 화면 없이 전체 코어 런 판정이 가능하다.
- 정식 화면 구현자가 도메인 내부를 읽지 않고 API로 상태를 표시할 수 있다.
