// UI-IOS-1av · REQ-105 · REQ-024 — 직원 홈(근무 중) 화면 데이터와 계산
// 예정 퇴근 시각이 지나도 화면 · 상태가 스스로 퇴근 처리하지 않는다(REQ-024). 퇴근은 사용자가 누를 때만.
// UI-IOS-6q · REQ-029 · REQ-095 — 오프라인: 같은 화면의 상태. 오프라인 여부 · 전송 대기는 연결 계층이 주는 값(nil이면 1av 그대로).
import Foundation

nonisolated struct EmployeeHomeWorkingState: Equatable, Sendable {
    /// 주간 · 이번 달 · 사업장 등 1at와 공유하는 값
    var base: EmployeeHomeState
    /// 실제 출근 시각(하루 안의 분)
    var clockInMinute: Int
    /// 지금 시각(하루 안의 분) — 화면이 주입받는다
    var nowMinute: Int
    /// 오프라인 표시(6q). nil이면 온라인 1av. 화면은 네트워크를 감지하지 않는다 — 호출자가 준다.
    var offline: EmployeeHomeOffline?
    init(base: EmployeeHomeState, clockInMinute: Int, nowMinute: Int, offline: EmployeeHomeOffline? = nil) {
        self.base = base
        self.clockInMinute = clockInMinute
        self.nowMinute = nowMinute
        self.offline = offline
    }

    var plan: ShiftPlan { base.today }

    /// 지난 시간(분). 자정을 넘겨도 이어서 센다 — 자동 퇴근이 없으니(REQ-024) 퇴근을 잊으면 자정을 넘길 수 있다.
    /// 근무 세션은 예정 퇴근 +6시간에 끝나므로(DEC-004) 24시간을 넘지 않는다.
    var elapsedMinutes: Int { WorkingFormat.minutesBetween(clockInMinute, nowMinute) }

    /// 예정 구간 기준 진행 비율(0–1로 자름). 막대 시작은 예정 시작 기준, 자정 넘김 포함
    var progress: Double {
        let total = plan.endMinute - plan.startMinute
        guard total > 0 else { return 0 }
        // 출근 이후 흐른 시간을 예정 시작 기준으로 옮긴다(자정 넘김 처리)
        let sinceStart = WorkingFormat.minutesBetween(clockInMinute, nowMinute) + (clockInMinute - plan.startMinute)
        return min(1, max(0, Double(sinceStart) / Double(total)))
    }

    var plannedPay: Int { plan.plannedPay(hourlyWage: base.hourlyWage) }
}

nonisolated enum WorkingFormat {
    /// 102 → (1, 42), 42 → (0, 42)
    static func parts(_ minutes: Int) -> (hours: Int, minutes: Int) { (minutes / 60, minutes % 60) }

    /// 분 표시: 시간이 있으면 두 자리(F4 「N시간 NN분」) — 5시간 05분
    static func minuteText(_ p: (hours: Int, minutes: Int)) -> String {
        p.hours == 0 ? "\(p.minutes)" : String(format: "%02d", p.minutes)
    }

    /// 접근성: 「1시간 42분 근무 중」
    static func elapsedLabel(_ minutes: Int) -> String {
        let p = parts(minutes)
        return (p.hours == 0 ? "\(p.minutes)분" : "\(p.hours)시간 \(minuteText(p))분") + " 근무 중"
    }

    /// 하루 안의 분 두 개 사이(뒤가 앞보다 작으면 자정을 넘긴 것으로 본다)
    static func minutesBetween(_ from: Int, _ to: Int) -> Int {
        to >= from ? to - from : to + 24 * 60 - from
    }

    /// 서울 기준 달력(기기 시간대와 무관하게) — AGENTS.md 「시간은 Asia/Seoul」
    static let seoulCalendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Seoul")!
        return c
    }()

    /// 지금 시각의 하루 안 분(서울 기준)
    static func minuteOfDay(_ date: Date, calendar: Calendar = seoulCalendar) -> Int {
        let c = calendar.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }
}

extension EmployeeHomeWorkingState {
    /// 디자인 1av 예시 값(가짜 데이터): 출근 16:58, 지금 18:40
    static let sample = EmployeeHomeWorkingState(
        base: .sample,
        clockInMinute: 16 * 60 + 58,
        nowMinute: 18 * 60 + 40
    )
}

/// UI-IOS-6q — 오프라인 표시 값(문구는 연결 계층이 주며, 기본값은 디자인 원문)
nonisolated struct EmployeeHomeOffline: Equatable, Sendable {
    /// 전송 대기 기록 한 줄씩 — 예: 「출근 16:58 · 매장 QR · 위치 확인됨」
    var pending: [String]
    /// 오늘 카드 맨 아래 — 예: 「출근 16:58 · 이 기기에 저장됨」
    var savedNote: String
    var bannerTitle = "인터넷에 연결되어 있지 않아요"
    var retryTitle = "다시 시도"
    var badgeText = "전송 대기"
    var pendingNote = "기록 시각은 누른 순간으로 저장돼요. 나중에 전송돼도 바뀌지 않아요."
    var clockOutHint = "연결이 없어도 퇴근을 기록할 수 있어요"

    var pendingTitle: String { "전송 대기 \(pending.count)건" }
}

extension EmployeeHomeOffline {
    /// 디자인 6q 예시 값(가짜 데이터)
    static let sample = EmployeeHomeOffline(
        pending: ["출근 16:58 · 매장 QR · 위치 확인됨"],
        savedNote: "출근 16:58 · 이 기기에 저장됨"
    )
}

extension EmployeeHomeWorkingState {
    /// 디자인 6q 예시 값: 출근 16:58, 지금 17:10(12분 근무)
    static let offline = EmployeeHomeWorkingState(
        base: .sample,
        clockInMinute: 16 * 60 + 58,
        nowMinute: 17 * 60 + 10,
        offline: .sample
    )
}
