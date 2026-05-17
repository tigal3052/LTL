class CalculatorApp {
  constructor(root) {
    // 생성자에서 전달받은 루트 요소를 this.root에 저장한다.
    this.root = root;

    // 루트 요소 안에서 현재 숫자를 표시할 display 요소를 찾아 this.displayElement에 저장한다.
    this.displayElement = root.querySelector("[data-display]");

    // 루트 요소 안에서 현재 대기 중인 수식이나 연산 상태를 표시할 expression 요소를 찾아 this.expressionElement에 저장한다.
    this.expressionElement = root.querySelector("[data-expression]");

    // 루트 요소 안에서 완료된 계산 기록 목록을 표시할 history 요소를 찾아 this.historyElement에 저장한다.
    this.historyElement = root.querySelector("[data-history]");

    // 계산기의 현재 입력 숫자를 문자열 "0"으로 시작하도록 this.currentValue에 저장한다.
    this.currentValue = "0";

    // 연산 왼쪽에 위치할 이전 숫자가 아직 없으므로 this.previousValue를 null로 시작한다.
    this.previousValue = null;

    // 아직 선택된 연산자가 없으므로 this.pendingOperator를 null로 시작한다.
    this.pendingOperator = null;

    // 완료된 계산 기록이 아직 없으므로 this.historyEntries를 빈 배열로 시작한다.
    this.historyEntries = [];

    // 계산기 버튼 클릭이 숫자 입력, 연산자 입력, 계산 실행, 초기화 실행으로 연결되도록 이벤트를 바인딩한다.
    this.bindButtonEvents();

    // 생성 직후의 숫자 표시 영역, 수식 표시 영역, 기록 표시 영역을 초기 상태로 렌더링한다.
    this.renderCalculator();
  }

  bindButtonEvents() {
    // 루트 요소 전체에서 버튼 클릭 이벤트를 감지할 수 있도록 click 이벤트 리스너를 등록한다.
    this.root.addEventListener("click", (event) => {
      // 클릭된 대상에서 가장 가까운 button 요소를 찾아 실제 계산기 버튼인지 확인한다.
      const button = event.target.closest("button");

      // 클릭된 대상이 계산기 버튼이 아니면 아무 동작도 하지 않고 종료한다.
      if (!button) {
        return;
      }

      // 계산기 버튼이면 버튼의 data 속성을 읽어 입력 종류를 분기하는 메서드로 전달한다.
      this.routeButtonAction(button);
    });
  }

  routeButtonAction(button) {
    // 전달받은 버튼에서 숫자 입력값인 data-digit 값을 읽는다.
    const digit = button.dataset.digit;

    // 전달받은 버튼에서 연산자 입력값인 data-operator 값을 읽는다.
    const operator = button.dataset.operator;

    // 전달받은 버튼에서 특수 동작 값인 data-action 값을 읽는다.
    const action = button.dataset.action;

    // 숫자 입력값이 있으면 숫자 입력 처리 메서드를 호출하고 나머지 분기는 진행하지 않는다.
    if (digit) {
      this.handleDigitInput(digit);
      return;
    }

    // 연산자 입력값이 있으면 연산자 입력 처리 메서드를 호출하고 나머지 분기는 진행하지 않는다.
    if (operator) {
      this.handleOperatorInput(operator);
      return;
    }

    // 특수 동작 값이 equals이면 계산 실행 메서드를 호출하고 나머지 분기는 진행하지 않는다.
    if (action === "equals") {
      this.handleEqualsInput();
      return;
    }

    // 특수 동작 값이 clear이면 계산기 전체 초기화 메서드를 호출한다.
    if (action === "clear") {
      this.handleClearInput();
    }
  }

  handleDigitInput(digit) {
    // 전달받은 숫자 한 자리를 현재 입력 문자열 뒤에 붙여 새로운 현재 입력값을 만든다.
    this.appendDigitToCurrentValue(digit);

    // 숫자 입력이 반영된 현재 숫자 표시 영역과 수식 표시 영역을 다시 렌더링한다.
    this.renderDisplay();
  }

  handleOperatorInput(operator) {
    // 이전 숫자와 연산자가 이미 남아 있으면 현재 숫자까지 포함해 먼저 계산 결과를 만든다.
    if (this.hasPendingOperationWithCurrentValue()) {
      this.completePendingCalculation();
    }

    // 현재 입력 숫자를 다음 계산의 왼쪽 숫자로 저장한다.
    this.storeCurrentValueAsPrevious();

    // 방금 누른 연산자를 다음 계산에 사용할 대기 연산자로 저장한다.
    this.setPendingOperator(operator);

    // 다음 숫자 입력을 받을 수 있도록 현재 입력 숫자를 기본값 "0"으로 초기화한다.
    this.prepareForNextValueInput();

    // 연산 대기 상태가 반영된 숫자 표시 영역과 수식 표시 영역을 다시 렌더링한다.
    this.renderDisplay();
  }

  handleEqualsInput() {
    // 이전 숫자와 연산자가 모두 준비되지 않았으면 계산을 실행하지 않고 종료한다.
    if (!this.hasPendingOperationWithCurrentValue()) {
      return;
    }

    // 이전 숫자, 대기 연산자, 현재 숫자를 사용해 계산 결과를 만든다.
    this.completePendingCalculation();

    // 계산에 사용한 수식을 기록 목록 맨 앞에 추가한다.

    // 계산 결과를 현재 입력 숫자로 바꿔 다음 계산의 시작값으로 사용할 수 있게 만든다.

    // 계산이 끝났으므로 이전 숫자와 대기 연산자를 비운다.
    this.clearPendingOperation();

    // 계산 결과와 최신 기록이 반영된 숫자 표시 영역, 수식 표시 영역, 기록 표시 영역을 다시 렌더링한다.
    this.renderCalculator();
  }

  handleClearInput() {
    // 현재 입력 숫자를 문자열 "0"으로 되돌린다.

    // 이전 숫자와 대기 연산자를 모두 null로 되돌린다.

    // 완료된 계산 기록 배열을 빈 배열로 되돌린다.
    this.resetCalculatorState();

    // 초기화된 숫자 표시 영역, 수식 표시 영역, 기록 표시 영역을 다시 렌더링한다.
    this.renderCalculator();
  }

  appendDigitToCurrentValue(digit) {
    // 현재 입력 숫자가 기본값 "0"이면 전달받은 숫자 한 자리로 현재 입력값을 교체한다.
    if (this.currentValue === "0") {
      this.currentValue = digit;
      return;
    }

    // 현재 입력 숫자가 이미 존재하면 전달받은 숫자 한 자리를 문자열 뒤에 이어 붙인다.
    this.currentValue += digit;
  }

  hasPendingOperationWithCurrentValue() {
    // 이전 숫자와 대기 연산자가 모두 존재하는지 확인해 계산 가능한 상태인지 boolean으로 반환한다.
    return this.previousValue !== null && this.pendingOperator !== null;
  }

  completePendingCalculation() {
    // 기록용으로 사용할 "이전 숫자 연산자 현재 숫자" 형태의 수식 문자열을 만든다.
    const expression = this.createExpressionText();

    // 이전 숫자, 대기 연산자, 현재 숫자를 사용해 실제 계산 결과 숫자를 만든다.
    const result = this.calculateResultFromPendingOperation();

    // 계산 결과 숫자를 화면 표시용 문자열로 바꿔 this.currentValue에 저장한다.
    this.currentValue = this.formatNumber(result);

    // 방금 계산한 수식 문자열과 결과 문자열을 기록 목록 맨 앞에 추가한다.
    this.recordCalculation(expression, this.currentValue);

    // 기록 목록이 너무 길어지지 않도록 최근 기록만 남기도록 정리한다.
    this.limitHistorySizeToTen();
  }

  storeCurrentValueAsPrevious() {
    // 현재 입력 숫자 문자열을 다음 계산의 왼쪽 숫자인 this.previousValue에 저장한다.
    this.previousValue = this.currentValue;
  }

  setPendingOperator(operator) {
    // 전달받은 연산자 문자열을 다음 계산에 사용할 this.pendingOperator에 저장한다.
    this.pendingOperator = operator;
  }

  prepareForNextValueInput() {
    // 오른쪽 숫자 입력을 새로 받을 수 있도록 this.currentValue를 문자열 "0"으로 되돌린다.
    this.currentValue = "0";
  }

  clearPendingOperation() {
    // 계산이 끝난 뒤 이전 숫자인 this.previousValue를 null로 비운다.
    this.previousValue = null;

    // 계산이 끝난 뒤 대기 연산자인 this.pendingOperator를 null로 비운다.
    this.pendingOperator = null;
  }

  calculateResultFromPendingOperation() {
    // this.previousValue 문자열을 숫자로 변환해 left 값으로 만든다.
    const left = Number(this.previousValue);

    // this.currentValue 문자열을 숫자로 변환해 right 값으로 만든다.
    const right = Number(this.currentValue);

    // 대기 연산자가 더하기이면 left + right 결과를 반환한다.
    if (this.pendingOperator === "+") {
      return left + right;
    }

    // 대기 연산자가 빼기이면 left - right 결과를 반환한다.
    if (this.pendingOperator === "-") {
      return left - right;
    }

    // 대기 연산자가 곱하기이면 left * right 결과를 반환한다.
    if (this.pendingOperator === "*") {
      return left * right;
    }

    // 대기 연산자가 나누기이면 left / right 결과를 반환한다.
    if (this.pendingOperator === "/") {
      return right === 0 ? 0 : left / right;
    }

    // 지원하지 않는 연산자가 들어오면 현재 오른쪽 숫자 또는 안전한 기본값을 반환한다.
    return right;
  }

  createExpressionText() {
    // 이전 숫자, 대기 연산자, 현재 숫자를 이어 붙여 기록용 수식 문자열을 반환한다.
    return `${this.previousValue} ${this.pendingOperator} ${this.currentValue}`;
  }

  recordCalculation(expression, result) {
    // 전달받은 수식 문자열과 결과 문자열을 객체로 만들어 기록 배열 맨 앞에 추가한다.
    this.historyEntries.unshift({ expression, result });

    // 기록 배열 길이가 제한을 넘으면 가장 오래된 기록부터 제거한다.
    if (this.historyEntries.length > 10) {
      this.historyEntries = this.historyEntries.slice(0, 10);
    }
  }

  limitHistorySizeToTen() {
    // 기록 배열을 잘라 최근 10개 기록만 남기고 나머지는 제거한다.
    this.historyEntries = this.historyEntries.slice(0, 10);
  }

  resetCalculatorState() {
    // 현재 입력 숫자인 this.currentValue를 문자열 "0"으로 되돌린다.
    this.currentValue = "0";

    // 이전 숫자인 this.previousValue를 null로 되돌린다.
    this.previousValue = null;

    // 대기 연산자인 this.pendingOperator를 null로 되돌린다.
    this.pendingOperator = null;

    // 계산 기록 배열인 this.historyEntries를 빈 배열로 되돌린다.
    this.historyEntries = [];
  }

  formatNumber(value) {
    // 전달받은 숫자를 화면에 표시하기 쉬운 문자열 형태로 정리해 반환한다.
    return String(Number(value.toFixed(6)));
  }

  renderCalculator() {
    // 현재 숫자와 대기 수식을 숫자 표시 영역과 수식 표시 영역에 렌더링한다.
    this.renderDisplay();

    // 계산 기록 배열을 기록 표시 영역에 렌더링한다.
    this.renderHistory();
  }

  renderDisplay() {
    // this.currentValue를 메인 숫자 표시 요소의 textContent에 반영한다.
    if (this.displayElement) {
      this.displayElement.textContent = this.currentValue;
    }

    // 현재 대기 중인 수식 설명 문자열을 수식 표시 요소의 textContent에 반영한다.
    if (this.expressionElement) {
      this.expressionElement.textContent = this.describePendingExpression();
    }
  }

  describePendingExpression() {
    // 이전 숫자와 대기 연산자가 없으면 "입력을 기다리는 중" 같은 안내 문자열을 반환한다.
    if (!this.hasPendingExpression()) {
      return "입력을 기다리는 중";
    }

    // 이전 숫자와 대기 연산자가 있으면 "이전 숫자 연산자" 형태의 표시 문자열을 반환한다.
    return `${this.previousValue} ${this.pendingOperator}`;
  }

  hasPendingExpression() {
    // 화면에 보여줄 이전 숫자와 대기 연산자가 존재하는지 boolean으로 반환한다.
    return this.previousValue !== null && this.pendingOperator !== null;
  }

  renderHistory() {
    // 기록 배열이 비어 있으면 기록이 없다는 안내 문구를 기록 표시 영역에 렌더링한다.
    if (!this.historyElement) {
      return;
    }

    if (this.historyEntries.length === 0) {
      this.historyElement.innerHTML =
        '<div class="history-empty">아직 완료된 계산이 없습니다.</div>';
      return;
    }

    // 기록 배열이 있으면 각 기록의 수식 문자열과 결과 문자열을 목록 HTML로 만들어 렌더링한다.
    this.historyElement.innerHTML = this.historyEntries
      .map(
        (entry) => `
          <div class="history-item">
            <div class="history-expression">${entry.expression}</div>
            <div class="history-result">= ${entry.result}</div>
          </div>
        `,
      )
      .join("");
  }
}

// 문서에서 계산기 루트로 사용할 요소를 선택해 appRoot에 저장한다.
const appRoot = document.querySelector(".page");

// 계산기 루트 요소가 존재하면 CalculatorApp 인스턴스를 생성한다.
if (appRoot) {
  new CalculatorApp(appRoot);
}
