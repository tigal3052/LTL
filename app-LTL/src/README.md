# app-LTL src comment skeleton

이 경로는 M1 코어 도메인 안정화를 위한 정식 구현 경계입니다.

현재 패스의 산출물은 구현 코드가 아니라 논리기반 프로그래밍 주석입니다.
다음 구현자는 각 파일의 주석을 위에서 아래로 따라가며 한 문장 함수, 사실
factory, 규칙 질의, 전이, 공개 스냅샷 순서로 코드를 채웁니다.

기준:

- `app-LTL/prototype/browser-p0-p4/**`는 검증된 참조 원형이며 직접 수정하지 않습니다.
- `app-LTL/src/domain/**`는 사실, 규칙, 질의, 전이, 스냅샷의 SoT 후보입니다.
- loader와 validation은 raw JSON을 검증된 facts로 바꾸는 경계입니다.
- process와 controller는 명령을 도메인에 전달할 뿐 규칙을 재구현하지 않습니다.
- UI, DOM, browser timing, prototype render 의존은 이 정식 도메인 안으로 들어오지 않습니다.

구현 순서:

1. 주석의 `한 문장`을 테스트 이름 또는 describe 문장으로 고정합니다.
2. `입력 사실`과 `생성할 사실`을 불변 record로 먼저 만듭니다.
3. `규칙` 항목 하나마다 작은 순수 함수를 만듭니다.
4. `전이`는 기존 facts를 변경하지 않고 새 facts 또는 snapshot 입력을 반환합니다.
5. `금지 규칙`을 어긴 중복 로직이 생기면 SoT 함수 하나로 다시 모읍니다.
