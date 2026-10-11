// UI-IOS-1av · REQ-105 · REQ-024 — 직원 홈(근무 중) 화면 데이터와 계산
// 예정 퇴근 시각이 지나도 화면 · 상태가 스스로 퇴근 처리하지 않는다(REQ-024). 퇴근은 사용자가 누를 때만.
import Foundation

nonisolated enum WorkStatus: Equatable, Sendable {
    case working
}

nonisolated struct EmployeeHomeWorkingState: Equatable, Sendable {
    /// 주간 · 이번 달 · 사업장 등 1at와 공유하는 값
    var base: EmployeeHomeState
    /// 실제 출근 시각(하루 안의 분)
    var clockInMinute: Int
    /// 지금 시각(하루 안의 분) — 화면이 주입받는다
    var nowMinute: Int
    /// 근무 중에서 스스로 바뀌는 경로는 없다
    private(set) var status: WorkStatus = .working

    init(base: EmployeeHomeState, clockInMinute: Int, nowMinute: Int) {
        self.base = base
        self.clockInMinute = clockInMinute
        self.nowMinute = nowMinute
    }

    var plan: ShiftPlan { base.today }

    /// 지난 시간(분). 출근 전 값이면 0
    var elapsedMinutes: Int { max(0, nowMinute - clockInMinute) }

    /// 예정 구간 기준 진행 비율(0–1로 자름). 막대 시작은 예정 시작 기준
    var progress: Double {
        let total = plan.endMinute - plan.startMinute
        guard total > 0 else { return 0 }
        return min(1, max(0, Double(nowMinute - plan.startMinute) / Double(total)))
    }

    var plannedPay: Int { plan.plannedPay(hourlyWage: base.hourlyWage) }
}

nonisolated enum WorkingFormat {
    /// 102 → (1, 42), 42 → (0, 42)
    static func parts(_ minutes: Int) -> (hours: Int, minutes: Int) { (minutes / 60, minutes % 60) }

    /// 접근성: 「1시간 42분 근무 중」
    static func elapsedLabel(_ minutes: Int) -> String {
        let p = parts(minutes)
        return (p.hours == 0 ? "\(p.minutes)분" : "\(p.hours)시간 \(p.minutes)분") + " 근무 중"
    }

    /// 지금 시각의 하루 안 분
    static func minuteOfDay(_ date: Date, calendar: Calendar = .current) -> Int {
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
