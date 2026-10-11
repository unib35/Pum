// UI-IOS-1l · REQ-107 · REQ-071 — 예상 급여 화면 데이터
// 금액 · 계산 근거는 서버(급여 엔진)가 준 값을 그대로 쓴다. 화면에서 급여 · 주휴를 계산하지 않는다
// (주휴 규칙은 노무 검토 대상 — 개발 명세서 부록 B). 아래 합 · 비율은 구성 막대의 폭과 샘플 일관성 확인용이다.
import Foundation

/// 서버가 준 계산 근거 한 줄. 문구(라벨 · 값)는 서버가 만든 그대로 보여 준다.
nonisolated struct ExpectedPayCalcLine: Equatable, Sendable, Identifiable {
    /// 값의 모양: 보통 / 충족 같은 긍정(초록) / 결과 줄(굵게)
    enum Tone: Equatable, Sendable { case normal, positive, strong }

    let id: String
    let label: String
    let value: String
    var tone: Tone = .normal
    /// true면 이 줄 위에 구분선을 그린다(결과 줄 앞)
    var separatorAbove = false
}

nonisolated struct ExpectedPayItem: Equatable, Sendable, Identifiable {
    enum Kind: Equatable, Sendable { case base, holiday, other, deduction }

    let id: String
    let kind: Kind
    let label: String
    /// 양수 원. 공제는 표시할 때 U+2212를 붙인다.
    let amount: Int
    /// 펼쳐서 보여 줄 계산 근거. 비어 있으면 펼침 없는 이동 행.
    var calcLines: [ExpectedPayCalcLine] = []

    var isExpandable: Bool { !calcLines.isEmpty }
    var amountText: String {
        (kind == .deduction ? PumFormat.deduction(amount) : PumFormat.amount(amount)) + "원"
    }
}

/// 펼침 · 접힘 상태(M11). 주휴수당 행 하나.
nonisolated struct ExpectedPayDisclosure: Equatable, Sendable {
    var isExpanded = true
    mutating func toggle() { isExpanded.toggle() }
    var stateText: String { isExpanded ? "펼쳐짐" : "접힘" }
}

nonisolated struct ExpectedPayRecord: Equatable, Sendable {
    var workplaceName: String
    var workplaceInitial: String
    var titleText: String          // 「10월 예상 급여」
    var payDateText: String        // 「11월 10일 지급」
    /// 서버가 준 예상 급여 · 구성 · 확정 · 남은 예정
    var expectedTotal: Int
    var basePay: Int
    var holidayPay: Int
    var otherPay: Int
    var deductionTotal: Int
    var confirmedAmount: Int
    var confirmedDetail: String    // 「2일 · 10시간 06분」
    var remainingAmount: Int
    var remainingDetail: String    // 「15일 · 72시간 24분」
    var items: [ExpectedPayItem]

    var totalText: String { PumFormat.amount(expectedTotal) }
    var deductionText: String { PumFormat.deduction(deductionTotal) }
    var confirmedText: String { PumFormat.amount(confirmedAmount) + "원" }
    var remainingText: String { PumFormat.amount(remainingAmount) + "원" }

    /// 구성 막대 조각(기본급 · 주휴 · 기타). 폭은 이 금액들의 비율.
    var barParts: [Int] { [basePay, holidayPay, otherPay].map { max(0, $0) } }
    var barTotal: Int { barParts.reduce(0, +) }
    func barFraction(_ index: Int) -> Double {
        barTotal > 0 ? Double(barParts[index]) / Double(barTotal) : 0
    }

    /// 확인용: 확정 + 남은 예정 = 예상 급여
    var isConsistent: Bool { confirmedAmount + remainingAmount == expectedTotal }

    /// VoiceOver: 구성 막대 한 문장
    var barAccessibilityText: String {
        "급여 구성, 기본급 \(PumFormat.amount(basePay))원, 주휴 \(PumFormat.amount(holidayPay))원, 기타 \(PumFormat.amount(otherPay))원, 공제 \(PumFormat.amount(deductionTotal))원"
    }

    static let sample = ExpectedPayRecord(
        workplaceName: "종민김밥 본점",
        workplaceInitial: "종",
        titleText: "10월 예상 급여",
        payDateText: "11월 10일 지급",
        expectedTotal: 1_188_000,
        basePay: 990_000,
        holidayPay: 198_000,
        otherPay: 30_000,
        deductionTotal: 30_000,
        confirmedAmount: 121_200,
        confirmedDetail: "2일 · 10시간 06분",
        remainingAmount: 1_066_800,
        remainingDetail: "15일 · 72시간 24분",
        items: [
            .init(id: "base", kind: .base, label: "기본급", amount: 990_000),
            .init(id: "holiday", kind: .holiday, label: "주휴수당", amount: 198_000, calcLines: [
                .init(id: "c1", label: "1주 소정근로 15시간 이상", value: "충족", tone: .positive),
                .init(id: "c2", label: "주휴시간 = 15h ÷ 40h × 8h", value: "3시간"),
                .init(id: "c3", label: "3시간 × 12,000원", value: "36,000원 / 주"),
                .init(id: "c4", label: "× 10월 5.5주", value: "198,000원", tone: .strong, separatorAbove: true),
            ]),
            .init(id: "other", kind: .other, label: "기타수당", amount: 30_000),
            .init(id: "deduction", kind: .deduction, label: "공제", amount: 30_000),
        ]
    )
}
