// UI-IOS-8d · REQ-052 — 인건비 시뮬레이터(사장님). What-if 전용: 실제 데이터는 바뀌지 않는다.
// 예상 금액 · 내역 문구는 서버(엔진)가 준 값 그대로 — 화면에서 곱하거나 더하지 않는다(급여 계산은 엔진 한 곳).
// 결과는 계산 조건(basis)과 함께 받고, 지금 입력이 basis와 같을 때만 보인다. 다르면 숫자 · 내역을 숨기고 부모에게 알린다.
// REQ-051: 주휴수당 0원 등은 엔진 결과일 뿐 — 수당을 피하라는 추천 · 강조 문구를 만들지 않는다.
import Foundation

/// 세그먼트 3칸. 원문은 「직원 추가」 내용만 있다(나머지 둘은 화면 없음 — 눌림만 부모에 알림).
nonisolated enum LaborSimulatorMode: CaseIterable, Sendable {
    case addEmployee, changeHours, changeWage

    var title: String {
        switch self {
        case .addEmployee: "직원 추가"
        case .changeHours: "시간 변경"
        case .changeWage: "시급 변경"
        }
    }
}

/// 계산 조건 — 서버에 보내고, 결과가 어느 조건으로 계산됐는지 알려 주는 키. 요일 id는 월 1 … 일 7(C13와 같음).
nonisolated struct LaborSimulatorInputs: Equatable, Sendable {
    /// 시급(원, 정수)
    var hourlyWon: Int
    var weekdays: Set<Int>
    /// 하루 중 분(0 ..< 1440, Asia/Seoul 벽시계)
    var startMinutes: Int
    var endMinutes: Int
    /// 0(없음) · 30 · 60
    var breakMinutes: Int
    /// 「10/10 – 10/31」 — 날짜 선택은 #192 미정이라 글자만 가진다
    var periodText: String
}

/// 서버(엔진) 결과. 숫자와 문구는 받은 그대로 보여 준다.
nonisolated struct LaborSimulatorResult: Equatable, Sendable {
    struct Line: Equatable, Sendable {
        /// 서버 문구 — 예: 「기본급 · 9일 × 4.5h × 12,000」
        var title: String
        /// 정수 원
        var amountWon: Int
    }

    /// 이 결과를 계산한 조건
    var basis: LaborSimulatorInputs
    /// 정수 원 — 서버가 준 합계(화면에서 더하지 않는다)
    var expectedWon: Int
    var lines: [Line]
}

nonisolated struct LaborSimulatorState: Equatable, Sendable {
    static let title = "인건비 계산"
    static let resultHeading = "예상 추가 인건비"
    static let estimateBadge = "예상"
    static let detailTitle = "결과 자세히 보기"
    static let dash = " \u{2013} "

    var inputs: LaborSimulatorInputs
    /// 마지막으로 받은 엔진 결과. 아직 없으면 nil
    var result: LaborSimulatorResult?
    /// 선택된 세그먼트 — 원문은 「직원 추가」뿐이라 고정
    let mode: LaborSimulatorMode = .addEmployee

    /// 원문 값(입력 = basis)
    static let sample: LaborSimulatorState = {
        let inputs = LaborSimulatorInputs(
            hourlyWon: 12_000, weekdays: [1, 3, 5], startMinutes: 17 * 60, endMinutes: 22 * 60,
            breakMinutes: 30, periodText: "10/10\(dash)10/31")
        return LaborSimulatorState(inputs: inputs, result: LaborSimulatorResult(
            basis: inputs, expectedWon: 504_000,
            lines: [
                .init(title: "기본급 \u{00B7} 9일 \u{00D7} 4.5h \u{00D7} 12,000", amountWon: 486_000),
                .init(title: "주휴수당 \u{00B7} 계약 소정근로 4주 평균 기준", amountWon: 0),
                .init(title: "사업주 부담 4대보험 \u{00B7} 약", amountWon: 18_000),
            ]))
    }()

    // MARK: 결과 보임 규칙

    /// 결과가 있고 지금 입력과 계산 조건이 같을 때만 true
    var resultIsCurrent: Bool { result?.basis == inputs }
    /// 숫자 · 내역에 쓰는 결과 — 조건이 다르면 nil(숨김)
    var visibleResult: LaborSimulatorResult? { resultIsCurrent ? result : nil }
    /// 「결과 자세히 보기」 활성
    var canShowDetail: Bool { resultIsCurrent }

    // MARK: 입력 문구

    var wageText: String { "\(PumFormat.amount(inputs.hourlyWon))원" }

    var timeText: String {
        PumTimeWheelMath.clockText(inputs.startMinutes) + Self.dash + PumTimeWheelMath.clockText(inputs.endMinutes)
    }

    var breakText: String {
        PumTimePickerStyle.breakChoices.first { $0.minutes == inputs.breakMinutes }?.title ?? "\(inputs.breakMinutes)분"
    }

    var timeSpoken: String {
        "\(PumTimeWheelMath.spokenText(inputs.startMinutes))부터 \(PumTimeWheelMath.spokenText(inputs.endMinutes))까지"
    }

    // MARK: 결과 문구 (서버 값 그대로 — 곱셈 · 덧셈 없음)

    static func totalText(_ won: Int) -> String { "약 \(PumFormat.amount(won))원" }
    static func amountText(_ won: Int) -> String { "\(PumFormat.amount(won))원" }

    var totalText: String? { visibleResult.map { Self.totalText($0.expectedWon) } }

    /// VoiceOver — 「예상 추가 인건비 약 504,000원」
    var resultSpoken: String {
        totalText.map { "\(Self.resultHeading) \($0)" } ?? Self.resultHeading
    }

    // MARK: 요일

    func isWeekdaySelected(_ id: Int) -> Bool { inputs.weekdays.contains(id) }

    mutating func toggleWeekday(_ id: Int) {
        if inputs.weekdays.contains(id) { inputs.weekdays.remove(id) } else { inputs.weekdays.insert(id) }
    }

    // MARK: C13 시트

    var pickerValue: PumTimeRangeValue {
        var v = PumTimeRangeValue()
        v.startMinutes = inputs.startMinutes
        v.endMinutes = inputs.endMinutes
        v.breakMinutes = inputs.breakMinutes
        v.weekdays = inputs.weekdays
        return v
    }

    /// 시트 「완료」 — 시간 · 휴게만 가져온다
    mutating func apply(picked: PumTimeRangeValue) {
        inputs.startMinutes = picked.startMinutes
        inputs.endMinutes = picked.endMinutes
        inputs.breakMinutes = picked.breakMinutes
    }
}
