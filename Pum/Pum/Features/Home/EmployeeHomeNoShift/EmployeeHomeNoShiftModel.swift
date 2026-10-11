// UI-IOS-1au · REQ-105 — 직원 홈(근무 없는 날) 화면 데이터와 문구
// 예정 시간은 안내용이다. 실제 근무시간 · 급여는 서버 계산으로만 만든다(REQ-024 · DEC-008).
import Foundation

nonisolated struct NoShiftHomeState: Equatable, Sendable {
    var workplaceName: String
    var workplaceInitial: String
    var weekTitle: String
    var week: [WeekDay]
    var weekPlannedMinutes: Int
    var todayTitle: String
    var nextShiftLabel: String       // "내일 월요일"
    var hourlyWage: Int
    var nextShift: ShiftPlan
    var upcoming: [UpcomingShift]
    var monthTitle: String
    var monthPlannedMinutes: Int
    var monthDaysSummary: String
    var monthExpectedPay: Int
    var hasUnreadNotification: Bool

    /// 「이번 주 4일 · 19시간」 — 근무일 점 개수와 주간 예정 분으로 만든다
    var weekSummary: String {
        "이번 주 \(week.filter(\.hasShift).count)일 · \(HomeFormat.hours(weekPlannedMinutes))"
    }

    /// 「다음 근무 · 내일 월요일」
    var nextShiftCaption: String { "다음 근무 · \(nextShiftLabel)" }

    /// 「인정 근무 4시간 30분 · 54,000원 예정」
    var plannedSummary: String {
        "인정 근무 \(HomeFormat.hours(nextShift.plannedPaidMinutes)) · \(PumFormat.amount(nextShift.plannedPay(hourlyWage: hourlyWage)))원 예정"
    }

    var nextShiftRange: String {
        PumFormat.timeRange(HomeFormat.clock(nextShift.startMinute), HomeFormat.clock(nextShift.endMinute))
    }

    /// 기존 이번 달 카드(MonthSummaryCard)가 받는 형태로 옮긴다
    var monthCardState: EmployeeHomeState {
        var s = EmployeeHomeState.sample
        s.monthTitle = monthTitle
        s.monthPlannedMinutes = monthPlannedMinutes
        s.monthDaysSummary = monthDaysSummary
        s.monthExpectedPay = monthExpectedPay
        return s
    }
}

extension NoShiftHomeState {
    /// 디자인 1au 예시 값(가짜 데이터)
    static let sample = NoShiftHomeState(
        workplaceName: "종민김밥 본점",
        workplaceInitial: "종",
        weekTitle: "10월 첫째 주",
        week: [
            .init(id: 0, day: 28, hasShift: true, isToday: false),
            .init(id: 1, day: 29, hasShift: false, isToday: false),
            .init(id: 2, day: 30, hasShift: true, isToday: false),
            .init(id: 3, day: 1, hasShift: false, isToday: false),
            .init(id: 4, day: 2, hasShift: true, isToday: false),
            .init(id: 5, day: 3, hasShift: true, isToday: false),
            .init(id: 6, day: 4, hasShift: false, isToday: true),
        ],
        weekPlannedMinutes: 19 * 60,
        todayTitle: "오늘 · 10월 4일 일",
        nextShiftLabel: "내일 월요일",
        hourlyWage: 12_000,
        nextShift: ShiftPlan(startMinute: 17 * 60, endMinute: 22 * 60, breakMinutes: 30, breakStartMinute: 19 * 60 + 30),
        upcoming: [
            .init(id: "수 7일", start: "17:00", end: "22:00", paidMinutes: 300),
            .init(id: "금 9일", start: "17:00", end: "22:00", paidMinutes: 300),
            .init(id: "토 10일", start: "17:00", end: "22:00", paidMinutes: 300),
        ],
        monthTitle: "10월",
        monthPlannedMinutes: 82 * 60 + 30,
        monthDaysSummary: "17일 · 확정 2일",
        monthExpectedPay: 1_188_000,
        hasUnreadNotification: true
    )
}
