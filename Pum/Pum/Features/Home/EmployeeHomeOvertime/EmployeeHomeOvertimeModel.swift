// UI-IOS-1ak · REQ-024 · REQ-026 — 직원 홈(연장 근무 중) 화면 데이터와 계산
// 예정 퇴근을 넘겨도 화면 · 상태가 스스로 퇴근 처리하지 않고 묻지도 않는다(REQ-024). 퇴근은 사용자가 누를 때만.
// 인정 예상 금액은 서버(엔진) 값을 그대로 받아 보여 준다 — 화면에서 급여를 계산하지 않는다.
import Foundation

nonisolated struct EmployeeHomeOvertimeState: Equatable, Sendable {
    var workplaceName: String
    var workplaceInitial: String
    var hasUnreadNotification: Bool
    /// 「10월 3일 토」 — 서버가 준 오늘 날짜 표기
    var dateText: String
    /// 예정 근무(시작 · 퇴근 · 휴게)
    var plan: ShiftPlan
    /// 실제 출근 시각(하루 안의 분)
    var clockInMinute: Int
    /// 지금 시각(하루 안의 분) — 화면이 주입받는다
    var nowMinute: Int
    /// 인정 예상 금액(원, 정수) — 서버(엔진) 값. 「N원~」로 보여 준다(REQ-026)
    var recognizedPayEstimate: Int

    /// 기기 시계가 출근 기록보다 조금 앞서 있을 때(지금 < 출근) 허용하는 폭(분) — 이 안이면 경과 0
    static let clockSkewToleranceMinutes = 10
    /// 세션은 예정 퇴근 + 6시간에 끝난다(DEC-004) — 출근이 예정 퇴근 「뒤」인지 판단하는 범위
    static let sessionTailMinutes = 6 * 60

    /// 지난 시간(분). 자정을 넘겨도 이어서 센다. 지금이 출근보다 조금 이르면(시계 어긋남) 0
    var elapsedMinutes: Int {
        if WorkingFormat.minutesBetween(nowMinute, clockInMinute) <= Self.clockSkewToleranceMinutes { return 0 }
        return WorkingFormat.minutesBetween(clockInMinute, nowMinute)
    }

    /// 출근부터 예정 퇴근까지(분). 예정 퇴근이 출근보다 작은 시각이면 자정을 넘긴 것.
    /// 예정 퇴근 이후(6시간 안)에 출근했으면 0 — 일한 시간 전부가 예정 초과
    var scheduledSpanMinutes: Int {
        let afterEnd = WorkingFormat.minutesBetween(plan.endMinute, clockInMinute)
        if afterEnd <= Self.sessionTailMinutes { return 0 }
        return WorkingFormat.minutesBetween(clockInMinute, plan.endMinute)
    }

    /// 예정 퇴근을 넘긴 분. 0이면 아직 예정 안(연장 아님)
    var overtimeMinutes: Int { max(0, elapsedMinutes - scheduledSpanMinutes) }

    /// 홈은 이 값이 참일 때만 1ak를 띄운다(아니면 1av 근무 중) — 화면은 0분 연장을 그리지 않는다
    var isOvertime: Bool { overtimeMinutes > 0 }

    /// 진행 막대에서 초과 구간 비율(0–1) = 초과분 / 전체 경과
    var overtimeRatio: Double {
        guard elapsedMinutes > 0 else { return 0 }
        return min(1, Double(overtimeMinutes) / Double(elapsedMinutes))
    }
}

nonisolated enum OvertimeFormat {
    /// 255 → "4:15", 75 → "1:15", 5 → "0:05"
    static func clockStyle(_ minutes: Int) -> String {
        String(format: "%d:%02d", minutes / 60, minutes % 60)
    }

    /// 73 → "+1:13"
    static func plusClock(_ minutes: Int) -> String { "+" + clockStyle(minutes) }

    /// 73 → "+1시간 13분", 60 → "+1시간", 20 → "+20분"
    static func plusDuration(_ minutes: Int) -> String { "+" + HomeFormat.hours(minutes) }

    /// 접근성: 「연장 근무 중, 4시간 15분 근무, 예정 퇴근 20:00보다 1시간 13분 초과」
    static func cardLabel(elapsed: Int, plannedEnd: String, overtime: Int) -> String {
        "연장 근무 중, \(HomeFormat.hours(elapsed)) 근무, 예정 퇴근 \(plannedEnd)보다 \(HomeFormat.hours(overtime)) 초과"
    }
}

extension EmployeeHomeOvertimeState {
    /// 디자인 1ak 예시 값(가짜 데이터): 예정 17:00–20:00, 출근 16:58, 지금 21:13
    static let sample = EmployeeHomeOvertimeState(
        workplaceName: "종민김밥 본점",
        workplaceInitial: "종",
        hasUnreadNotification: false, // 원문은 알림 점 없음
        dateText: "10월 3일 토",
        plan: ShiftPlan(startMinute: 17 * 60, endMinute: 20 * 60, breakMinutes: 0, breakStartMinute: nil),
        clockInMinute: 16 * 60 + 58,
        nowMinute: 21 * 60 + 13,
        recognizedPayEstimate: 45_000
    )

    func with(now: Int) -> EmployeeHomeOvertimeState {
        var copy = self
        copy.nowMinute = now
        return copy
    }
}
