// UI-IOS-2f · REQ-005 · REQ-006 · REQ-105 — 개인 모드 홈 화면 데이터
// 시간 · 금액 · 예상 값은 모두 엔진 · 저장소에서 받은 값을 그대로 보여 준다. 화면에서 계산하지 않는다(REQ-024 · DEC-008).
import Foundation

nonisolated struct PersonalRecord: Equatable, Sendable, Identifiable {
    let id: String       // 예: "금 2일"
    let start: String    // "17:02"
    let end: String      // "22:31"
    let paidMinutes: Int
}

nonisolated struct PersonalHomeState: Equatable, Sendable {
    var workplaceName: String        // "종민김밥" (칩에는 「개인 · 」을 앞에 붙인다)
    var workplaceInitial: String     // "개"
    var weekTitle: String
    var weekSummary: String
    var week: [WeekDay]
    var todayTitle: String
    var nowMinute: Int
    var today: ShiftPlan             // 내 예정 (개인이 입력한 예정)
    var minutesUntilStart: Int       // 저장소 · 시계 값 (화면에서 빼지 않는다)
    var hourlyWage: Int              // 내 시급
    var plannedPay: Int              // 예정 금액(정수 원) — 서버 계산 값
    var monthTitle: String           // "10월"
    var monthPlannedMinutes: Int
    var monthDaysSummary: String     // "14일 · 급여일 11월 10일"
    var monthExpectedPay: Int
    var recent: [PersonalRecord]     // 비어 있으면 「최근 기록」 카드 숨김
    var hasUnreadNotification: Bool
}

extension PersonalHomeState {
    /// 디자인 2f 예시 값(가짜 데이터). 원문 캡처는 「금 2일」 한 줄만 보인다(둘째 줄 「수 30일」은 카드 아래로 잘림).
    static let sample = PersonalHomeState(
        workplaceName: "종민김밥",
        workplaceInitial: "개",
        weekTitle: "10월 첫째 주",
        weekSummary: "이번 주 3일 · 14시간 30분",
        week: [
            .init(id: 0, day: 28, hasShift: true, isToday: false),
            .init(id: 1, day: 29, hasShift: true, isToday: false),
            .init(id: 2, day: 30, hasShift: true, isToday: false),
            .init(id: 3, day: 1, hasShift: false, isToday: false),
            .init(id: 4, day: 2, hasShift: true, isToday: false),
            .init(id: 5, day: 3, hasShift: true, isToday: true),
            .init(id: 6, day: 4, hasShift: false, isToday: false),
        ],
        todayTitle: "오늘 · 10월 3일 토",
        nowMinute: 16 * 60 + 53,
        today: ShiftPlan(startMinute: 17 * 60, endMinute: 22 * 60, breakMinutes: 30, breakStartMinute: 19 * 60 + 30),
        minutesUntilStart: 7,
        hourlyWage: 12_000,
        plannedPay: 54_000,
        monthTitle: "10월",
        monthPlannedMinutes: 68 * 60 + 20,
        monthDaysSummary: "14일 · 급여일 11월 10일",
        monthExpectedPay: 824_300,
        recent: [
            .init(id: "금 2일", start: "17:02", end: "22:31", paidMinutes: 299),
        ],
        hasUnreadNotification: true
    )
}
