// UI-IOS-19a · UI-IOS-19b · REQ-082 — 사장님 · 연도 전환 + 새 시급 정하기 시트.
// 직원 분류 · 월 인건비 · 계약서 건수는 서버 값(화면에서 계산하지 않음 — 급여 계산은 엔진만). 금액은 정수(원).
import Foundation

/// 직원 한 명 — 이름 · 아바타 색 번호 · 지금 시급은 서버 값
nonisolated struct WageEmployee: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    /// 아바타 색 번호 — 서버 값
    let colorIndex: Int
    /// 지금 시급(원)
    let currentWage: Int
}

/// 퇴사 예정 직원 — 대상 아님
nonisolated struct WageExcludedEmployee: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    /// 「10월 31일 퇴사」 — 서버 값
    let leaveDateText: String
}

nonisolated struct WageYearTransitionState: Equatable, Sendable {
    static let backTitle = "홈"
    static let belowBadge = "미달"
    static let fineHeader = "그대로 괜찮은 직원"
    static let holidayTitle = "2027년 공휴일 · 4대보험 요율"
    static let holidayDetail = "1월 1일 자동 적용 · 요율은 고시 후"
    static let setWagesTitle = "새 시급 정하기"
    static let excludedSuffix = " · 대상 아님"

    /// 「2027년 1월 1일부터」
    let effectiveDateText: String
    /// 새 최저임금(원)
    let minimumWage: Int
    /// 올해 최저임금(원)
    let currentMinimumWage: Int
    /// 최저 미만 직원
    let below: [WageEmployee]
    /// 최저 이상이지만 여유가 적은 직원
    let thin: [WageEmployee]
    /// 그대로 괜찮은 직원
    let fine: [WageEmployee]
    /// 퇴사 예정 — 대상 아님
    let excluded: [WageExcludedEmployee]

    static func won(_ amount: Int) -> String { "\(PumFormat.amount(amount))원" }

    var minimumTitle: String { "최저임금 \(Self.won(minimumWage))" }
    /// 「올해 10,320원 · 380원 인상」
    var increaseLine: String { "올해 \(Self.won(currentMinimumWage)) · \(Self.won(minimumWage - currentMinimumWage)) 인상" }
    var belowHeader: String { "시급이 모자란 직원 \(below.count)명" }
    var thinHeader: String { "여유가 적은 직원 \(thin.count)명" }
    /// 「지금 10,320원」
    func currentLine(_ e: WageEmployee) -> String { "지금 \(Self.won(e.currentWage))" }
    /// 「100원 위」
    func marginBadge(_ e: WageEmployee) -> String { "\(Self.won(e.currentWage - minimumWage)) 위" }
    /// 「최유나, 지금 10,320원, 미달」
    func belowReadout(_ e: WageEmployee) -> String { "\(e.name), \(currentLine(e)), \(Self.belowBadge)" }
    func thinReadout(_ e: WageEmployee) -> String { "\(e.name), \(currentLine(e)), \(marginBadge(e))" }
    /// 「김하늘 · 이종민」
    var fineNames: String { fine.map(\.name).joined(separator: " · ") }
    /// 「11,500원 · 12,000원」
    var fineWages: String { fine.map { Self.won($0.currentWage) }.joined(separator: " · ") }
    var fineReadout: String { "\(fineNames), \(fineWages)" }
    /// 「10월 31일 퇴사 · 대상 아님」
    func excludedDetail(_ e: WageExcludedEmployee) -> String { e.leaveDateText + Self.excludedSuffix }
    func excludedReadout(_ e: WageExcludedEmployee) -> String { "\(e.name), \(excludedDetail(e))" }
    /// 「계약서 서명 전에도 1월 1일부터 10,700원 이상으로 계산돼요」
    var footerNotice: String { "계약서 서명 전에도 1월 1일부터 \(Self.won(minimumWage)) 이상으로 계산돼요" }

    static let sample = WageYearTransitionState(
        effectiveDateText: "2027년 1월 1일부터",
        minimumWage: 10_700,
        currentMinimumWage: 10_320,
        below: [
            WageEmployee(id: "yuna", name: "최유나", colorIndex: 2, currentWage: 10_320),
            WageEmployee(id: "daeun", name: "정다은", colorIndex: 3, currentWage: 10_320),
        ],
        thin: [WageEmployee(id: "sejin", name: "오세진", colorIndex: 4, currentWage: 10_800)],
        fine: [
            WageEmployee(id: "haneul", name: "김하늘", colorIndex: 1, currentWage: 11_500),
            WageEmployee(id: "jongmin", name: "이종민", colorIndex: 0, currentWage: 12_000),
        ],
        excluded: [WageExcludedEmployee(id: "seojun", name: "박서준", leaveDateText: "10월 31일 퇴사")]
    )
}

/// 보내는 값 — 직원별 새 시급(원)
nonisolated struct NewWageInput: Equatable, Sendable {
    let employeeID: String
    let wage: Int
}

/// 시트(19b) — 월 인건비 · 건수는 서버 값. 서버 값이 있을 때만 시트를 연다.
nonisolated struct NewWageSheetState: Equatable, Sendable {
    static let title = "새 시급 · 1월 1일부터"
    static let cancelTitle = "취소"
    static let sendingTitle = "보내는 중"
    static let costTitle = "월 인건비 · 예상"
    static let costDetail = "9월 근무 기준 · 주휴 포함"
    static let contractTitle = "변경 계약서"
    static let contractDetail = "바뀌는 직원에게만"
    static let footerNotice = "직원이 서명하면 계약서 보관함에 · 활동 기록에 남아요"
    /// 원문 없음 — 최저 미만 행의 이유
    static let belowMinimumHint = "최저임금 이상이어야 해요"

    /// 새 최저임금(원)
    let minimumWage: Int
    /// 입력 행 — 지금 시급은 서버 값
    let rows: [WageEmployee]
    /// 화면 초안의 시작값(직원 id → 새 시급, 원) — 서버 값
    let initialWages: [String: Int]
    /// 월 인건비 증가 예상(원) — 서버 값
    let monthlyCostDelta: Int
    /// 변경 계약서 건수 — 서버 값
    let contractCount: Int

    var minimumLine: String { "최저 \(WageYearTransitionState.won(minimumWage))" }
    var costValue: String {
        let text = WageYearTransitionState.won(monthlyCostDelta)
        return monthlyCostDelta > 0 ? "+" + text : text
    }
    var contractValue: String { "\(contractCount)건" }
    var sendTitle: String { "계약서 \(contractCount)건 보내기" }

    func wage(_ id: String, in draft: [String: Int]) -> Int { draft[id] ?? initialWages[id] ?? 0 }
    func isBelowMinimum(_ wage: Int) -> Bool { wage < minimumWage }
    func isRowBelowMinimum(_ e: WageEmployee, in draft: [String: Int]) -> Bool { isBelowMinimum(wage(e.id, in: draft)) }
    func canSend(_ draft: [String: Int]) -> Bool {
        !rows.isEmpty && !rows.contains { isRowBelowMinimum($0, in: draft) }
    }
    /// 시급이 바뀌는 직원만 — 「바뀌는 직원에게만」 변경 계약서
    func inputs(_ draft: [String: Int]) -> [NewWageInput] {
        rows.compactMap { e in
            let w = wage(e.id, in: draft)
            return w == e.currentWage ? nil : NewWageInput(employeeID: e.id, wage: w)
        }
    }
    /// 「최유나, 지금 10,320원, 새 시급」 — 입력 행 라벨. 값은 입력칸이 읽는다
    func inputLabel(_ e: WageEmployee) -> String { "\(e.name), 지금 \(WageYearTransitionState.won(e.currentWage)), 새 시급" }

    static let sample = NewWageSheetState(
        minimumWage: 10_700,
        rows: [
            WageEmployee(id: "yuna", name: "최유나", colorIndex: 2, currentWage: 10_320),
            WageEmployee(id: "daeun", name: "정다은", colorIndex: 3, currentWage: 10_320),
            WageEmployee(id: "sejin", name: "오세진", colorIndex: 4, currentWage: 10_800),
        ],
        initialWages: ["yuna": 10_700, "daeun": 10_700, "sejin": 10_800],
        monthlyCostDelta: 36_290,
        contractCount: 2
    )
}
