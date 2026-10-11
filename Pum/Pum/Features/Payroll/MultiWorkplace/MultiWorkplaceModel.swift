// UI-IOS-1n · REQ-008 · REQ-107 — 여러 사업장 급여 화면 데이터
// 금액 · 시간 · 합계는 서버가 준 값을 그대로 보여 준다. 화면에서 급여를 계산하지 않는다.
// 아래 합 · 비율은 막대 폭과 샘플 일관성 확인용이다(직원 × 사업장 조건 — REQ-008).
import SwiftUI

nonisolated struct MultiWorkplaceEntry: Equatable, Sendable, Identifiable {
    /// 지급 상태: 예상(아직 확정 전) · 확정
    enum Status: Equatable, Sendable {
        case expected, confirmed
        var text: String { self == .expected ? "예상" : "확정" }
    }

    let id: String
    let name: String
    let initial: String
    /// 사업장 색은 팔레트 번호로 가진다(PumAvatarPalette.stores)
    let colorIndex: Int
    let workMinutes: Int
    let hourlyWage: Int
    let payDayText: String      // 「11/10」
    let amount: Int             // 서버가 준 원
    let status: Status

    var amountText: String { PumFormat.amount(amount) }
    var durationText: String { MultiWorkplaceRecord.durationText(minutes: workMinutes) }
    /// 「82시간 30분 · 12,000원/h · 급여일 11/10」
    var detailText: String { "\(durationText) · \(PumFormat.amount(hourlyWage))원/h · 급여일 \(payDayText)" }
    var tileColor: Color { PumAvatarPalette.stores[colorIndex % PumAvatarPalette.stores.count] }
    var badgeKind: PumBadge.Kind { status == .confirmed ? .done : .waiting }

    /// VoiceOver: 카드 한 문장
    var accessibilityText: String {
        "\(name), \(amountText)원 \(status.text), \(durationText), 시간당 \(PumFormat.amount(hourlyWage))원, 급여일 \(payDayText)"
    }
}

nonisolated struct MultiWorkplaceRecord: Equatable, Sendable {
    var titleText: String           // 「10월 내가 번 돈 · 3곳」
    /// 서버가 준 합계 · 총 근무
    var totalAmount: Int
    var totalMinutes: Int
    var workDays: Int
    var entries: [MultiWorkplaceEntry]

    /// 원문 1n 표기: 딱 떨어지면 「49시간」(분 생략 — 원문 그대로), 아니면 F4대로 분 두 자리 「82시간 05분」
    static func durationText(minutes: Int) -> String {
        let h = minutes / 60, m = minutes % 60
        if m == 0 { return "\(h)시간" }
        return h == 0 ? "\(m)분" : PumFormat.duration(minutes: minutes)
    }

    var totalText: String { PumFormat.amount(totalAmount) }
    var totalWorkText: String { "총 근무 \(Self.durationText(minutes: totalMinutes)) · \(workDays)일" }
    var expectedCount: Int { entries.filter { $0.status == .expected }.count }
    var confirmedCount: Int { entries.filter { $0.status == .confirmed }.count }
    var countText: String { "예상 \(expectedCount)곳 · 확정 \(confirmedCount)곳" }

    /// 막대 조각 값(음수는 0으로 방어). 폭은 이 금액들의 비율.
    var barParts: [Int] { entries.map { max(0, $0.amount) } }
    var barTotal: Int { barParts.reduce(0, +) }
    func barFraction(_ index: Int) -> Double {
        barTotal > 0 ? Double(barParts[index]) / Double(barTotal) : 0
    }

    /// 확인용: 사업장 금액의 합 = 서버 합계
    var isConsistent: Bool { entries.reduce(0) { $0 + $1.amount } == totalAmount }

    /// VoiceOver: 막대 한 문장
    var barAccessibilityText: String {
        "사업장별 금액, " + entries.map { "\($0.name) \($0.amountText)원" }.joined(separator: ", ")
    }

    var summaryAccessibilityText: String { "\(titleText), \(totalText)원, \(totalWorkText), \(countText)" }

    static let sample = MultiWorkplaceRecord(
        titleText: "10월 내가 번 돈 · 3곳",
        totalAmount: 2_207_300,
        totalMinutes: 9_390,
        workDays: 32,
        entries: [
            .init(id: "w1", name: "종민김밥 본점", initial: "종", colorIndex: 0, workMinutes: 4_950,
                  hourlyWage: 12_000, payDayText: "11/10", amount: 1_188_000, status: .expected),
            .init(id: "w2", name: "B카페 서면점", initial: "B", colorIndex: 1, workMinutes: 2_940,
                  hourlyWage: 11_500, payDayText: "11/5", amount: 642_300, status: .expected),
            .init(id: "w3", name: "C학원", initial: "C", colorIndex: 2, workMinutes: 1_500,
                  hourlyWage: 15_000, payDayText: "11/25", amount: 377_000, status: .confirmed),
        ]
    )
}
