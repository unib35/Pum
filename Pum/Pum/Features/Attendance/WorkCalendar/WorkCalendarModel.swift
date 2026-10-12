// UI-IOS-1g · REQ-006 · REQ-107 — 근무 캘린더(월 보기) 데이터와 달력 칸 배치
// 금액 · 시간은 서버가 준 값을 그대로 표시한다 — 화면에서 급여를 계산하지 않는다(AGENTS.md · REQ-071).
import Foundation

/// 날짜 아래 상태 점 종류(디자인 1g 범례)
nonisolated enum WorkCalendarDot: CaseIterable, Equatable, Sendable {
    case confirmed   // 확정 — 초록 채운 점
    case planned     // 예정 — 파랑 테두리 빈 원
    case substitute  // 대타 요청 중 — 주황 채운 점
    case absent      // 결근 — 빨강 채운 점

    /// 범례 · VoiceOver 문구
    var title: String {
        switch self {
        case .confirmed: "확정"
        case .planned: "예정"
        case .substitute: "대타 요청 중"
        case .absent: "결근"
        }
    }
}

/// 한 날짜 칸의 표시: 상태 점 하나, 또는 휴무
nonisolated enum WorkCalendarMark: Equatable, Sendable {
    case dot(WorkCalendarDot)
    case dayOff

    var title: String {
        switch self {
        case .dot(let d): d.title
        case .dayOff: "휴무"
        }
    }
}

/// 한 달의 칸 배치. 일요일 시작, 서울 기준 그레고리력.
nonisolated struct WorkCalendarLayout: Equatable, Sendable {
    let year: Int
    let month: Int
    /// 1일 앞의 빈 칸 수(일요일 시작: 일 0 … 토 6)
    let leadingBlanks: Int
    let dayCount: Int

    static let weekdayNames = ["일", "월", "화", "수", "목", "금", "토"]
    static let columns = 7

    static let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Seoul") ?? .current
        c.firstWeekday = 1
        return c
    }()

    init?(year: Int, month: Int) {
        let cal = Self.calendar
        guard let first = cal.date(from: DateComponents(year: year, month: month, day: 1)),
              cal.component(.month, from: first) == month,
              let days = cal.range(of: .day, in: .month, for: first)
        else { return nil }
        self.year = year
        self.month = month
        self.leadingBlanks = cal.component(.weekday, from: first) - 1 // 1 = 일요일
        self.dayCount = days.count
    }

    var weekCount: Int { (leadingBlanks + dayCount + Self.columns - 1) / Self.columns }

    /// 칸 번호(0부터) → 날짜. 앞 · 뒤 빈 칸이면 nil
    func day(atSlot slot: Int) -> Int? {
        let d = slot - leadingBlanks + 1
        return (1...dayCount).contains(d) ? d : nil
    }

    /// 0 = 일요일 … 6 = 토요일
    func weekdayIndex(of day: Int) -> Int { (leadingBlanks + day - 1) % Self.columns }
    func isSunday(_ day: Int) -> Bool { weekdayIndex(of: day) == 0 }
    func weekdayName(of day: Int) -> String { Self.weekdayNames[weekdayIndex(of: day)] }

    /// 「10월 12일 월요일, 대타 요청 중」
    func accessibilityLabel(day: Int, mark: WorkCalendarMark?, isToday: Bool) -> String {
        var s = "\(month)월 \(day)일 \(weekdayName(of: day))요일"
        if let mark { s += ", \(mark.title)" }
        if isToday { s += ", 오늘" }
        return s
    }
}

/// 선택한 날 카드(디자인 1g ③)
nonisolated struct WorkCalendarSelectedDay: Equatable, Sendable {
    var day: Int
    var weekday: String
    var actualStart: Int, actualEnd: Int       // 하루 안의 분
    var plannedStartHour: Int, plannedEndHour: Int
    /// 서버가 계산한 인정 근무(분) · 금액(정수 원)
    var recognizedMinutes: Int
    var pay: Int
    var statusText: String

    var actualRange: String { PumFormat.timeRange(HomeFormat.clock(actualStart), HomeFormat.clock(actualEnd)) }
    var plannedText: String { "(예정 \(plannedStartHour)\u{2013}\(plannedEndHour))" }
    var recognizedText: String { "인정 \(PumFormat.duration(minutes: recognizedMinutes)) \u{00B7} \(PumFormat.amount(pay))원" }
}

/// 월 요약 카드(디자인 1g ④)
nonisolated struct WorkCalendarSummary: Equatable, Sendable {
    var title: String
    var confirmedDays: Int
    var confirmedMinutes: Int
    var workDays: Int
    var totalMinutes: Int
    var overtimeMinutes: Int
    var expectedPay: Int

    var confirmedText: String { "확정 \(confirmedDays)일 \u{00B7} \(HomeFormat.hours(confirmedMinutes))" }
    var workDaysText: String { "\(workDays)일" }
    var totalText: String { HomeFormat.hours(totalMinutes) }
    var overtimeText: String { HomeFormat.hours(overtimeMinutes) }
    var payText: String { PumFormat.amount(expectedPay) + "원" }
}

nonisolated struct WorkCalendarState: Equatable, Sendable {
    var workplaceName: String
    var workplaceInitial: String
    var layout: WorkCalendarLayout
    var marks: [Int: WorkCalendarMark]
    var today: Int?
    var selected: WorkCalendarSelectedDay
    var summary: WorkCalendarSummary
    /// 6p 빈 상태(근무기록 0건) — 서버 값. nil이면 1g 그대로
    var empty: WorkCalendarEmpty? = nil

    var monthTitle: String { "\(layout.year)년 \(layout.month)월" }

    /// 디자인 1g 예시 값(가짜 데이터)
    static let sample: WorkCalendarState = {
        var marks: [Int: WorkCalendarMark] = [:]
        for d in [2, 3] { marks[d] = .dot(.confirmed) }
        for d in [5, 7, 9, 14, 16, 19, 21, 23, 26, 28, 30] { marks[d] = .dot(.planned) }
        marks[12] = .dot(.substitute)
        marks[29] = .dayOff
        return WorkCalendarState(
            workplaceName: "종민김밥 본점", workplaceInitial: "종",
            layout: WorkCalendarLayout(year: 2026, month: 10)!,
            marks: marks, today: 3,
            selected: WorkCalendarSelectedDay(
                day: 3, weekday: "토",
                actualStart: 16 * 60 + 58, actualEnd: 22 * 60 + 31,
                plannedStartHour: 17, plannedEndHour: 22,
                recognizedMinutes: 303, pay: 60_600, statusText: "확정"),
            summary: WorkCalendarSummary(
                title: "10월 예상", confirmedDays: 2, confirmedMinutes: 606,
                workDays: 17, totalMinutes: 82 * 60 + 30, overtimeMinutes: 6 * 60 + 30,
                expectedPay: 1_188_000))
    }()
}

/// 6p 근무 달력 빈 상태 — 날짜 · 다음 근무 글자는 서버가 준 값
nonisolated struct WorkCalendarEmpty: Equatable, Sendable {
    /// 예정 근무 날(일)
    var plannedDays: Set<Int>
    /// 다음 근무 글자(굵게 표시). 예: 「10월 5일 월 17:00」
    var nextWorkText: String

    static let title = "아직 근무기록이 없어요"
    static let hint = "첫 근무를 기록하면 여기에 날짜별로 쌓여요."
    static let scheduleButton = "스케줄 보기"

    /// 「다음 근무는 10월 5일 월 17:00이에요.」
    var nextWorkLine: String { "다음 근무는 \(nextWorkText)이에요." }
    /// VoiceOver 안내 한 덩어리
    var accessibilityText: String { "\(Self.title), \(Self.hint) \(nextWorkLine)" }

    /// 칸 읽기 문구: 「5일, 근무 예정」 · 그 밖은 「4일」
    func dayLabel(_ day: Int) -> String { plannedDays.contains(day) ? "\(day)일, 근무 예정" : "\(day)일" }

    /// 디자인 6p 원문 값
    static let sample = WorkCalendarEmpty(
        plannedDays: [5, 7, 9, 12, 14, 16, 19, 21, 23, 26, 28, 30], nextWorkText: "10월 5일 월 17:00")
}

extension WorkCalendarState {
    /// 6p 원문 값(2026년 10월, 기록 0건)
    static let empty: WorkCalendarState = {
        var s = WorkCalendarState.sample
        s.marks = [:]
        s.today = nil
        s.empty = .sample
        return s
    }()
}
