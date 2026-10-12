// UI-IOS-1at · REQ-105 · REQ-024 — 직원 홈(출근 전) 화면 데이터와 계산
// 예정 시간은 안내용이다. 실제 근무시간 · 급여는 출퇴근 기록과 서버 계산(엔진)으로만 만든다(REQ-024 · DEC-008).
import Foundation

nonisolated struct ShiftPlan: Equatable, Sendable {
    /// 하루 안의 분(0–1439). 예: 17:00 → 1020
    let startMinute: Int
    let endMinute: Int
    let breakMinutes: Int
    /// 휴게 시작(타임라인 표시용). 없으면 nil
    let breakStartMinute: Int?

    /// 인정 예정 근무 = 예정 − 휴게 (화면 안내용, 실제 계산은 서버)
    var plannedPaidMinutes: Int { max(0, endMinute - startMinute - breakMinutes) }

    /// 예정 금액(정수 원) — 시급 × 인정 분 ÷ 60, 원 단위 버림
    func plannedPay(hourlyWage: Int) -> Int { hourlyWage * plannedPaidMinutes / 60 }
}

nonisolated struct WeekDay: Equatable, Sendable, Identifiable {
    let id: Int          // 0 = 월 … 6 = 일
    let day: Int         // 날짜 숫자
    let hasShift: Bool
    let isToday: Bool
    var label: String { ["월", "화", "수", "목", "금", "토", "일"][id] }
    var isSunday: Bool { id == 6 }
}

nonisolated struct UpcomingShift: Equatable, Sendable, Identifiable {
    let id: String       // 예: "월 5일"
    let start: String
    let end: String
    let paidMinutes: Int
}

nonisolated struct EmployeeHomeState: Equatable, Sendable {
    var workplaceName: String
    var workplaceInitial: String
    var weekTitle: String
    var weekSummary: String
    var week: [WeekDay]
    var todayTitle: String
    var nowMinute: Int
    var hourlyWage: Int
    var today: ShiftPlan
    var monthTitle: String           // "10월"
    var monthPlannedMinutes: Int
    var monthDaysSummary: String     // "17일 · 확정 2일"
    var monthExpectedPay: Int
    var upcoming: [UpcomingShift]
    var hasUnreadNotification: Bool

    /// 출근 예정까지 남은 분(지났으면 0)
    var minutesUntilStart: Int { max(0, today.startMinute - nowMinute) }
}

nonisolated enum HomeFormat {
    static func clock(_ minute: Int) -> String {
        String(format: "%02d:%02d", (minute / 60) % 24, minute % 60)
    }

    /// 7 → "7분 후", 75 → "1시간 15분 후", 0 → "지금"
    static func untilStart(_ minutes: Int) -> String {
        minutes == 0 ? "지금" : PumFormat.duration(minutes: minutes) + " 후"
    }

    /// 300 → "5시간", 270 → "4시간 30분", 305 → "5시간 05분" (F4 「N시간 NN분」, 딱 떨어지면 「N시간」)
    static func hours(_ minutes: Int) -> String {
        minutes % 60 == 0 ? "\(minutes / 60)시간" : PumFormat.duration(minutes: minutes)
    }
}

extension EmployeeHomeState {
    /// 디자인 1at 예시 값(가짜 데이터)
    nonisolated static let sample = EmployeeHomeState(
        workplaceName: "종민김밥 본점",
        workplaceInitial: "종",
        weekTitle: "10월 첫째 주",
        weekSummary: "이번 주 3일 · 14시간 30분",
        week: [
            .init(id: 0, day: 28, hasShift: true, isToday: false),
            .init(id: 1, day: 29, hasShift: false, isToday: false),
            .init(id: 2, day: 30, hasShift: true, isToday: false),
            .init(id: 3, day: 1, hasShift: false, isToday: false),
            .init(id: 4, day: 2, hasShift: true, isToday: false),
            .init(id: 5, day: 3, hasShift: true, isToday: true),
            .init(id: 6, day: 4, hasShift: false, isToday: false),
        ],
        todayTitle: "오늘 · 10월 3일 토",
        nowMinute: 16 * 60 + 53,
        hourlyWage: 12_000,
        today: ShiftPlan(startMinute: 17 * 60, endMinute: 22 * 60, breakMinutes: 30, breakStartMinute: 19 * 60 + 30),
        monthTitle: "10월",
        monthPlannedMinutes: 82 * 60 + 30,
        monthDaysSummary: "17일 · 확정 2일",
        monthExpectedPay: 1_188_000,
        upcoming: [
            .init(id: "월 5일", start: "17:00", end: "22:00", paidMinutes: 300),
            .init(id: "수 7일", start: "17:00", end: "22:00", paidMinutes: 300),
        ],
        hasUnreadNotification: true
    )
}
