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
    /// 6u 업데이트 권장 시트 — nil이면 1au 그대로. 보일지(하루 한 번 · 근무 중/출근 30분 전 제외)는 호출자가 정한다
    var updateNotice: AppUpdateNotice? = nil
    /// 6v 점검 예고 한 줄 — nil이면 1au 그대로. 24시간 전부터 · 닫으면 다시 안 보임은 호출자가 정한다
    var maintenanceNotice: MaintenanceNotice? = nil

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

// MARK: - 6u 업데이트 권장 · 6v 점검 예고 (UI-IOS-6u · 6v · REQ-094)

/// 업데이트 권장 시트 내용(앱 버전 · 릴리스 노트는 서버/스토어 값)
nonisolated struct AppUpdateNotice: Equatable, Sendable {
    var version: String
    var sizeMB: Int
    var highlights: [String]

    static let title = "새 버전이 있어요"
    static let laterTitle = "나중에"
    static let updateTitle = "업데이트"

    /// 「1.4.3 · 12MB」
    var meta: String { "\(version) · \(sizeMB)MB" }
    /// VoiceOver 제목 헤더
    var spokenTitle: String { "\(Self.title), \(version), \(sizeMB)MB" }
}

/// 점검 예고 한 줄 내용(점검 일정은 서버 값)
nonisolated struct MaintenanceNotice: Equatable, Sendable {
    var dateText: String        // "10월 12일 월"
    var startClock: String      // "02:00"
    var endClock: String        // "04:00"

    static let detail = "출퇴근은 그대로 기록돼요 · 급여 · 요청은 점검 후"
    static let dismissTitle = "닫기"

    /// 「10월 12일 월 02:00 – 04:00 점검」
    var title: String { "\(dateText) \(PumFormat.timeRange(startClock, endClock)) 점검" }
    /// VoiceOver 한 문장
    var spoken: String { "\(title), \(Self.detail)" }
}

extension AppUpdateNotice {
    /// 디자인 6u 예시 값(가짜 데이터)
    static let sample = AppUpdateNotice(
        version: "1.4.3",
        sizeMB: 12,
        highlights: ["출근 QR 인식이 빨라졌어요", "명세서를 PDF로 저장할 수 있어요"]
    )
}

extension MaintenanceNotice {
    /// 디자인 6v 예시 값(가짜 데이터)
    static let sample = MaintenanceNotice(dateText: "10월 12일 월", startClock: "02:00", endClock: "04:00")
}

extension NoShiftHomeState {
    /// 6u — 1au 위에 업데이트 권장 시트
    static var updateAvailable: NoShiftHomeState {
        var s = NoShiftHomeState.sample
        s.updateNotice = .sample
        return s
    }

    /// 6v — 1au 맨 위에 점검 예고 한 줄
    static var maintenanceNotice: NoShiftHomeState {
        var s = NoShiftHomeState.sample
        s.maintenanceNotice = .sample
        return s
    }
}
