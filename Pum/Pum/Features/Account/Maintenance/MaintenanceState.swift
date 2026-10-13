// UI-IOS-6w · REQ-029 · REQ-094 — 점검 중. 시간 · 근무 중 값 · 대기 건수는 모두 호출자(서버/기기) 값. 네트워크 감지 · 시각 계산 없음.
// 출퇴근 기록은 점검 중에도 막지 않는다 — 기기에 저장 후 점검이 끝나면 전송.
import Foundation

/// 카드 한 줄 — 멈춘 기능(paused)은 옅게 보인다
nonisolated struct MaintenanceRow: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let message: String
    let paused: Bool
    let symbol: String
    var spoken: String { paused ? "\(title), 점검 중, \(message)" : "\(title), \(message)" }
}

/// 근무 중일 때만 있는 값(출근 시각 · 전송 대기 건수는 서버/기기가 준 글자)
nonisolated struct MaintenanceWorking: Equatable, Sendable {
    let title: String
    let message: String
}

/// 하단 버튼 종류 — 어느 쪽이든 잠그지 않는다
nonisolated enum MaintenanceActionKind: Equatable, Sendable { case clockOut, clockIn }

nonisolated struct MaintenanceAction: Equatable, Sendable {
    let title: String
    let kind: MaintenanceActionKind
    let caption: String
}

nonisolated struct MaintenanceState: Equatable, Sendable {
    static let title = "서비스 점검 중이에요"

    /// 서버 글자 — 예: 「02:00 – 04:00 · 끝나면 자동으로 다시 열려요.」
    let schedule: String
    let rows: [MaintenanceRow]
    /// nil이면 근무 중이 아님 — 근무 카드 숨김
    let working: MaintenanceWorking?
    /// 하단 버튼. 근무 중이 아닐 때의 원문은 없어 호출자가 정한다(nil이면 버튼 없음)
    let action: MaintenanceAction?

    var isWorking: Bool { working != nil }

    init(schedule: String, working: MaintenanceWorking?, action: MaintenanceAction?) {
        self.schedule = schedule
        self.rows = [
            MaintenanceRow(id: "clock", title: "출퇴근 기록",
                           message: "이 기기에 저장돼요. 점검이 끝나면 자동으로 보내요.", paused: false, symbol: "checkmark"),
            MaintenanceRow(id: "paused", title: "급여 · 명세서 · 요청",
                           message: "점검이 끝나면 다시 볼 수 있어요", paused: true, symbol: "clock"),
        ]
        self.working = working
        self.action = action
    }

    static let clockOutAction = MaintenanceAction(title: "퇴근하기", kind: .clockOut, caption: "누른 시각 그대로 저장돼요")

    /// 원문 6w — 근무 중(22:00 출근)
    static let sample = MaintenanceState(
        schedule: "02:00 – 04:00 · 끝나면 자동으로 다시 열려요.",
        working: MaintenanceWorking(title: "근무 중 · 22:00 출근", message: "이 기기에 저장됨 · 전송 대기 0건"),
        action: clockOutAction)
}
