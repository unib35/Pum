// UI-IOS-10c · REQ-060 — 조건 변경 → 변경 계약서. 서명 전까지는 기존 조건으로 계산한다(고정 안내).
// 금액 · 차이 · 시간 · 날짜 · 문구는 서버(엔진) 값 그대로 — 화면에서 계산하지 않는다.
// 영향 값은 계산 조건(basis = 바뀐 시급 · 적용 시작일)과 함께 받고, 지금 선택과 같을 때만 숫자를 보인다(10a · 8d와 같은 규칙).
import Foundation

/// 「언제부터」 선택. 날짜 직접 선택의 날짜 고르기는 #192 미정이라 선택 종류만 가진다.
nonisolated enum ContractChangeStart: Equatable, Sendable {
    case nextPeriod
    case custom
}

/// 영향 계산 조건
nonisolated struct ContractChangeBasis: Equatable, Sendable {
    /// 바뀐 시급(원, 정수)
    var newHourlyWon: Int
    var start: ContractChangeStart
}

/// 서버(엔진) 영향 결과. 숫자와 문구는 받은 그대로 보여 준다.
nonisolated struct ContractChangeImpact: Equatable, Sendable {
    /// 이 결과를 계산한 조건
    var basis: ContractChangeBasis
    /// 「근무 78시간 + 주휴 포함」
    var detailText: String
    /// 월 예상 급여 차이(원, 정수, 서버 값)
    var differenceWon: Int
    /// 「김하늘님이 서명하면 11월 1일부터 적용돼요」
    var noticeText: String
}

nonisolated struct ContractChangeState: Equatable, Sendable {
    static let headerTitle = "근로조건 변경"
    static let changedHeading = "바뀌는 조건"
    static let wageTitle = "시급"
    static let whenHeading = "언제부터"
    static let customDateTitle = "날짜 직접 선택"
    static let impactHeading = "영향 · 예상"
    /// REQ-060 고정 안내
    static let beforeSignTitle = "서명 전까지"
    static let beforeSignValue = "기존 조건으로 계산"
    static let sendTitle = "변경 계약서 보내기"

    var employeeName: String
    /// 「현재 계약 · 2026.10.6부터」
    var subtitle: String
    /// 「계약 중」
    var badgeText: String
    /// 지금 계약의 시급(원, 정수)
    var currentHourlyWon: Int
    /// 변경 입력 = 계산 조건
    var basis: ContractChangeBasis
    /// 「그대로인 조건 7개」의 7 — 서버 값
    var unchangedCount: Int
    /// 「근무 요일 · 시간 · 휴게 · 급여일 …」
    var unchangedSummary: String
    /// 「11월 1일부터」
    var nextPeriodTitle: String
    /// 「다음 급여 기간 시작일」
    var nextPeriodDetail: String
    /// 「11월 예상 급여」
    var impactTitle: String
    /// 마지막으로 받은 엔진 결과. 아직 없으면 nil
    var impact: ContractChangeImpact?

    /// 원문 값(결과 basis 일치)
    static let sample: ContractChangeState = {
        let basis = ContractChangeBasis(newHourlyWon: 12_000, start: .nextPeriod)
        return ContractChangeState(
            employeeName: "김하늘", subtitle: "현재 계약 · 2026.10.6부터", badgeText: "계약 중",
            currentHourlyWon: 11_500, basis: basis,
            unchangedCount: 7, unchangedSummary: "근무 요일 · 시간 · 휴게 · 급여일 …",
            nextPeriodTitle: "11월 1일부터", nextPeriodDetail: "다음 급여 기간 시작일",
            impactTitle: "11월 예상 급여",
            impact: ContractChangeImpact(basis: basis, detailText: "근무 78시간 + 주휴 포함",
                                         differenceWon: 47_000,
                                         noticeText: "김하늘님이 서명하면 11월 1일부터 적용돼요"))
    }()

    /// 바뀐 조건이 있는지 — 없으면 보내기 비활성
    var hasChanges: Bool { basis.newHourlyWon != currentHourlyWon }

    var oldWageText: String { PumFormat.amount(currentHourlyWon) }
    var newWageText: String { PumFormat.amount(basis.newHourlyWon) + "원" }
    var wageSpoken: String { "시급, \(oldWageText)원에서 \(PumFormat.amount(basis.newHourlyWon))원으로" }
    var unchangedTitle: String { "그대로인 조건 \(unchangedCount)개" }
    var unchangedSpoken: String { "\(unchangedTitle), \(unchangedSummary)" }

    /// 지금 선택과 같은 조건으로 계산한 결과만
    func visibleImpact(for selected: ContractChangeStart) -> ContractChangeImpact? {
        guard let impact, impact.basis == ContractChangeBasis(newHourlyWon: basis.newHourlyWon, start: selected) else { return nil }
        return impact
    }

    /// 「+47,000원」 — 부호만 붙인다(값은 서버)
    static func differenceText(_ won: Int) -> String {
        (won > 0 ? "+" : "") + PumFormat.amount(won) + "원"
    }

    static func startSpoken(title: String, detail: String?, isOn: Bool) -> String {
        ([title, detail].compactMap { $0 } + [isOn ? "선택됨" : "선택 안 됨"]).joined(separator: ", ")
    }
}

/// 보내기는 한 번만 — 누르는 즉시 잠그고 실패일 때만 푼다(되돌릴 수 없는 일: 성공이면 잠근 채).
nonisolated struct ContractChangeSendLock: Equatable, Sendable {
    private(set) var isSending = false
    mutating func begin() -> Bool {
        guard !isSending else { return false }
        isSending = true
        return true
    }
    mutating func finish(success: Bool) { if !success { isSending = false } }
}
