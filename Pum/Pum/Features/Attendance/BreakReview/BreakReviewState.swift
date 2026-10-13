// UI-IOS-19i · REQ-030 — 사장님 · 휴게 못 씀 확인.
// 시간 · 금액 · 반복 횟수 · 법 문구는 서버 값 그대로 — 화면에서 계산하지 않는다. 모든 값 let, 금액은 정수(원).
import Foundation

nonisolated struct BreakReviewState: Equatable, Sendable {
    /// 서버가 주는 반복 경고(이번 달 횟수 · 법 문구). 없으면 카드를 그리지 않는다.
    nonisolated struct Repeat: Equatable, Sendable {
        /// 이번 달 N번째(서버 값)
        let countThisMonth: Int
        /// 「4시간 이상 근무에는 휴게 30분 이상 · 근로기준법 54조」
        let lawText: String
    }

    static let backTitle = "처리할 일"
    static let needsCheckTitle = "확인 필요"
    static let headerTitle = "휴게 못 씀"
    static let plannedLabel = "예정 휴게"
    static let actualLabel = "실제"
    static let reasonLabel = "사유"
    static let ifApprovedTitle = "인정하면"
    static let workedLabel = "인정 근무"
    static let costLabel = "예상 인건비"
    static let otherTimeTitle = "다른 시간으로"
    static let approveTitle = "인정"

    /// 「김하늘」
    let staffName: String
    /// 「어제 22:10」
    let sentText: String
    /// 「10월 6일 화 · 17:00 – 22:00」
    let shiftText: String
    /// 예정 휴게(분, 서버 값)
    let plannedBreakMinutes: Int
    /// 실제 휴게(분, 서버 값)
    let actualBreakMinutes: Int
    /// 「주문이 몰려서」
    let reasonText: String
    /// 지금 인정 근무(분, 서버 값)
    let workedBeforeMinutes: Int
    /// 인정하면 인정 근무(분, 서버 값)
    let workedAfterMinutes: Int
    /// 「소정근로 초과 가산 포함」
    let costBasisText: String
    /// 예상 인건비 증가(원, 정수, 서버 값)
    let costDifferenceWon: Int
    let repeatWarning: Repeat?

    var senderText: String { "\(staffName) · \(sentText)" }
    var plannedText: String { "\(plannedBreakMinutes)분" }
    var actualText: String { "\(actualBreakMinutes)분" }
    var workedChangeText: String { "\(Self.clock(workedBeforeMinutes)) → \(Self.clock(workedAfterMinutes))" }
    var costText: String { (costDifferenceWon > 0 ? "+" : "") + PumFormat.amount(costDifferenceWon) + "원" }
    var footerNotice: String { "\(staffName)님에게 알림 · 원래 기록은 이력으로 남아요" }
    var repeatTitle: String? { repeatWarning.map { "\(staffName) · 이번 달 \($0.countThisMonth)번째" } }

    /// 「4h 30m」 — 서버가 준 분의 표기만 바꾼다
    static func clock(_ minutes: Int) -> String {
        let m = minutes % 60
        return "\(minutes / 60)h \(m < 10 ? "0" : "")\(m)m"
    }

    /// 「4시간 30분」 · 「5시간」
    static func spokenDuration(_ minutes: Int) -> String {
        let h = minutes / 60, m = minutes % 60
        if h == 0 { return "\(m)분" }
        return m == 0 ? "\(h)시간" : "\(h)시간 \(m)분"
    }

    var breakTilesSpoken: String { "\(Self.plannedLabel) \(plannedText), \(Self.actualLabel) \(actualText)" }
    var reasonSpoken: String { "\(Self.reasonLabel), \(reasonText)" }
    /// 「인정 근무, 4시간 30분에서 5시간으로」
    var workedSpoken: String {
        "\(Self.workedLabel), \(Self.spokenDuration(workedBeforeMinutes))에서 \(Self.spokenDuration(workedAfterMinutes))으로"
    }
    var costSpoken: String { "\(Self.costLabel), \(costBasisText), \(costText)" }
    var repeatSpoken: String? {
        guard let r = repeatWarning, let t = repeatTitle else { return nil }
        return "\(t), \(r.lawText)"
    }
    var sentSpoken: String { "\(Self.needsCheckTitle), \(senderText)" }

    /// 원문 캡처 값
    static let sample = BreakReviewState(
        staffName: "김하늘", sentText: "어제 22:10", shiftText: "10월 6일 화 · 17:00 – 22:00",
        plannedBreakMinutes: 30, actualBreakMinutes: 0, reasonText: "주문이 몰려서",
        workedBeforeMinutes: 270, workedAfterMinutes: 300,
        costBasisText: "소정근로 초과 가산 포함", costDifferenceWon: 9_000,
        repeatWarning: Repeat(countThisMonth: 3, lawText: "4시간 이상 근무에는 휴게 30분 이상 · 근로기준법 54조"))

    /// 반복 경고 없는 예시
    static let sampleNoWarning = BreakReviewState(
        staffName: "김하늘", sentText: "어제 22:10", shiftText: "10월 6일 화 · 17:00 – 22:00",
        plannedBreakMinutes: 30, actualBreakMinutes: 0, reasonText: "주문이 몰려서",
        workedBeforeMinutes: 270, workedAfterMinutes: 300,
        costBasisText: "소정근로 초과 가산 포함", costDifferenceWon: 9_000, repeatWarning: nil)
}
