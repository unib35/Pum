// UI-IOS-19c · REQ-082 · REQ-060 — 직원 · 변경 계약서 받음(시급만 바뀜).
// 금액 · 날짜 · 문구 · 예상 월 급여는 서버 값 그대로 — 화면에서 계산하지 않는다. 모든 값 let, 금액은 정수(원).
// 서명은 호출하는 쪽 몫(onSign).
import Foundation

nonisolated struct WageChangeContractState: Equatable, Sendable {
    static let backTitle = "소식"
    static let needsDecisionTitle = "결정 필요"
    static let headerTitle = "변경 근로계약서"
    static let nowLabel = "지금"
    static let restHeading = "나머지 조건"
    static let impactHeading = "바뀌면"
    static let impactTitle = "예상 월 급여"
    static let fullTitle = "계약서 전문"
    static let signTitle = "서명하기"

    /// 「오늘 10:40」
    let sentText: String
    /// 「박」 — 서버가 준 보낸 사람 첫 글자
    let senderInitial: String
    /// 「박민수 사장님 · 종민김밥 본점」
    let senderText: String
    /// 「2027년 1월 1일」
    let effectiveDateText: String
    /// 「1월」 — 「1월부터」 칸 이름
    let effectiveMonthText: String
    /// 지금 시급(원, 정수)
    let currentHourlyWon: Int
    /// 바뀌는 시급(원, 정수)
    let newHourlyWon: Int
    /// 「근무일 · 시간 · 휴게」
    let workRowTitle: String
    /// 「그대로」
    let workRowValue: String
    /// 「급여일」
    let payDayTitle: String
    /// 「매월 10일 그대로」
    let payDayValue: String
    /// 「9월 근무 기준 · 주휴 포함」
    let impactBasisText: String
    /// 예상 월 급여 차이(원, 정수, 서버 값)
    let impactDifferenceWon: Int
    /// 「서명하지 않아도 1월 1일부터 10,700원으로 계산돼요」
    let footerNotice: String

    /// 「시급 · 2027년 1월 1일부터」
    var wageHeading: String { "시급 · \(effectiveDateText)부터" }
    /// 「1월부터」
    var newLabel: String { "\(effectiveMonthText)부터" }
    /// 「10,320원」
    var currentWageText: String { Self.wonText(currentHourlyWon) }
    /// 「10,700원」
    var newWageText: String { Self.wonText(newHourlyWon) }
    /// 「+16,530원」
    var impactDifferenceText: String { Self.differenceText(impactDifferenceWon) }

    /// 「시급, 2027년 1월 1일부터, 지금 10,320원, 1월부터 10,700원」
    var wageSpoken: String {
        "시급, \(effectiveDateText)부터, \(Self.nowLabel) \(currentWageText), \(newLabel) \(newWageText)"
    }
    /// 두 칸만 — 제목은 따로 헤더로 읽는다. 「지금 10,320원, 1월부터 10,700원」
    var wageTilesSpoken: String { "\(Self.nowLabel) \(currentWageText), \(newLabel) \(newWageText)" }
    /// 「예상 월 급여, 9월 근무 기준 · 주휴 포함, +16,530원」
    var impactSpoken: String { "\(Self.impactTitle), \(impactBasisText), \(impactDifferenceText)" }
    var workRowSpoken: String { "\(workRowTitle), \(workRowValue)" }
    var payDaySpoken: String { "\(payDayTitle), \(payDayValue)" }
    /// 「결정 필요, 오늘 10:40」
    var sentSpoken: String { "\(Self.needsDecisionTitle), \(sentText)" }

    static func wonText(_ won: Int) -> String { PumFormat.amount(won) + "원" }
    static func differenceText(_ won: Int) -> String { (won > 0 ? "+" : "") + wonText(won) }

    /// 원문 캡처 값
    static let sample = WageChangeContractState(
        sentText: "오늘 10:40", senderInitial: "박", senderText: "박민수 사장님 · 종민김밥 본점",
        effectiveDateText: "2027년 1월 1일", effectiveMonthText: "1월",
        currentHourlyWon: 10_320, newHourlyWon: 10_700,
        workRowTitle: "근무일 · 시간 · 휴게", workRowValue: "그대로",
        payDayTitle: "급여일", payDayValue: "매월 10일 그대로",
        impactBasisText: "9월 근무 기준 · 주휴 포함", impactDifferenceWon: 16_530,
        footerNotice: "서명하지 않아도 1월 1일부터 10,700원으로 계산돼요")
}
