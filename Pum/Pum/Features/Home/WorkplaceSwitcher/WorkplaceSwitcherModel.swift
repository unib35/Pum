// UI-IOS-1y · REQ-008 — 사업장 전환 시트 데이터
// 근무 시간 · 시급 · 합산 금액 · 일수는 서버가 준 값을 그대로 보여 준다. 화면에서 계산하지 않는다.
import SwiftUI

nonisolated struct SwitcherWorkplace: Equatable, Sendable, Identifiable {
    let id: String
    let name: String
    let initial: String
    /// 사업장 색은 팔레트 번호로 가진다(PumAvatarPalette.stores)
    let colorIndex: Int
    /// 서버가 준 근무 안내(예: 「오늘 17:00 – 22:00」 · 「다음 근무 10/6 화 19:00」). 시간 범위는 en dash
    let scheduleText: String
    /// VoiceOver용 같은 내용(예: 「오늘 17:00부터 22:00」)
    let scheduleSpoken: String
    let hourlyWage: Int
    /// 확인할 것 건수(0이면 배지 없음)
    let pendingCount: Int

    var tileColor: Color {
        let n = PumAvatarPalette.stores.count
        return PumAvatarPalette.stores[((colorIndex % n) + n) % n] // 음수 · 범위 밖 번호 방어(서버 값)
    }
    var wageText: String { "시급 \(PumFormat.amount(hourlyWage))원" }
    /// 「오늘 17:00 – 22:00 · 시급 12,000원」
    var detailText: String { "\(scheduleText) · \(wageText)" }
    var pendingBadgeText: String { Self.pendingText(pendingCount) }
    static func pendingText(_ n: Int) -> String { "확인 \(n)" }
}

/// 오른쪽 표시. 선택됨과 확인이 겹치면 체크가 우선(디자인에 없는 경우 — 보고 항목)
nonisolated enum SwitcherMark: Equatable, Sendable {
    case selected
    case pending(Int)
    case none
}

nonisolated struct WorkplaceSwitcherState: Equatable, Sendable {
    var workplaces: [SwitcherWorkplace]
    var selectedID: String
    /// 서버가 준 합산(예: 10월, 2,207,300원, 32일)
    var summaryMonth: String
    var summaryAmount: Int
    var summaryDays: Int
    // 뒤 화면(시트에 덮여 어둡게)
    var todayTitle: String
    var shiftStart: String
    var shiftEnd: String
    var hasUnreadNotification: Bool

    var selected: SwitcherWorkplace? { workplaces.first { $0.id == selectedID } }
    var countText: String { "\(workplaces.count)곳에서 일하고 있어요" }
    var summaryText: String { "\(summaryMonth) 합산 \(PumFormat.amount(summaryAmount))원 · \(summaryDays)일" }
    var shiftRangeSpoken: String { "\(shiftStart)부터 \(shiftEnd)" }

    func mark(for w: SwitcherWorkplace) -> SwitcherMark {
        if w.id == selectedID { return .selected }
        return w.pendingCount > 0 ? .pending(w.pendingCount) : .none
    }

    func accessibilityText(for w: SwitcherWorkplace) -> String {
        var s = "\(w.name), \(w.scheduleSpoken), \(w.wageText)"
        // 「선택됨」은 .isSelected 특성이 읽는다(라벨에 넣으면 두 번 읽힘)
        if w.pendingCount > 0 { s += ", 확인할 것 \(w.pendingCount)건" }
        return s
    }

    /// 목록에 없는 id는 무시한다. 바뀌었으면 true(같은 사업장을 다시 누르면 false — 바깥에 전환을 알리지 않음)
    @discardableResult
    mutating func select(_ id: String) -> Bool {
        guard workplaces.contains(where: { $0.id == id }), id != selectedID else { return false }
        selectedID = id
        return true
    }

    /// 디자인 1y 예시 값(가짜 데이터)
    static let sample = WorkplaceSwitcherState(
        workplaces: [
            .init(id: "w1", name: "종민김밥 본점", initial: "종", colorIndex: 0,
                  scheduleText: "오늘 17:00 \u{2013} 22:00", scheduleSpoken: "오늘 17:00부터 22:00",
                  hourlyWage: 12_000, pendingCount: 0),
            .init(id: "w2", name: "B카페 서면점", initial: "B", colorIndex: 1,
                  scheduleText: "내일 09:00 \u{2013} 14:00", scheduleSpoken: "내일 09:00부터 14:00",
                  hourlyWage: 11_500, pendingCount: 1),
            .init(id: "w3", name: "C학원", initial: "C", colorIndex: 2,
                  scheduleText: "다음 근무 10/6 화 19:00", scheduleSpoken: "다음 근무 10월 6일 화요일 19:00",
                  hourlyWage: 15_000, pendingCount: 0),
        ],
        selectedID: "w1",
        summaryMonth: "10월", summaryAmount: 2_207_300, summaryDays: 32,
        todayTitle: "10월 3일 토요일 · 오늘", shiftStart: "17:00", shiftEnd: "22:00",
        hasUnreadNotification: false // 원문 1y는 알림 점 없음
    )
}
