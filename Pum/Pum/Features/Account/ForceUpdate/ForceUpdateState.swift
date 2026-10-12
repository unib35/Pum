// UI-IOS-6t · REQ-029 · REQ-094 — 업데이트 필수(계산 기준이 바뀔 때만). 버전 · 크기 · 문구 · 근무 중 값은 모두 호출자(서버) 값.
// 근무 중이면 퇴근 기록은 막지 않는다 — 이 화면은 업데이트 전에도 「퇴근만 기록」을 항상 열어 둔다.
import Foundation

/// 카드 한 줄 — 왼쪽 라벨 · 오른쪽 값
nonisolated struct ForceUpdateRow: Identifiable, Equatable, Sendable {
    let id: String
    let label: String
    let value: String
    var spoken: String { "\(label), \(value)" }
}

/// 근무 중일 때만 있는 값(출근 시각은 서버가 준 글자)
nonisolated struct ForceUpdateWorking: Equatable, Sendable {
    let title: String
    let message: String
}

nonisolated struct ForceUpdateState: Equatable, Sendable {
    static let title = "업데이트가 필요해요"
    static let updateTitle = "App Store에서 업데이트"
    static let clockOutTitle = "퇴근만 기록"

    let message: String
    let rows: [ForceUpdateRow]
    /// nil이면 근무 중이 아님 — 근무 카드 · 퇴근 버튼 숨김
    let working: ForceUpdateWorking?

    var isWorking: Bool { working != nil }
    /// 퇴근 버튼은 근무 중일 때만 보인다
    var showsClockOut: Bool { isWorking }

    init(message: String, currentVersion: String, requiredVersion: String, size: String, working: ForceUpdateWorking?) {
        self.message = message
        self.rows = [
            ForceUpdateRow(id: "current", label: "지금 버전", value: currentVersion),
            ForceUpdateRow(id: "required", label: "필요한 버전", value: requiredVersion),
            ForceUpdateRow(id: "size", label: "크기", value: size),
        ]
        self.working = working
    }

    /// 원문 6t — 근무 중(16:58 출근)
    static let sample = ForceUpdateState(
        message: "2027년 1월 1일부터 바뀌는 최저임금과 계산 기준은 새 버전에서만 계산돼요.",
        currentVersion: "1.4.2", requiredVersion: "1.5.0", size: "18MB",
        working: ForceUpdateWorking(title: "근무 중 · 16:58 출근",
                                    message: "업데이트하지 않아도 퇴근은 기록할 수 있어요. 기록은 그대로 이어져요."))

    /// 근무 아님 — 원문 없는 상태(원문 제목 「근무 중이면」의 반대). 같은 틀에서 카드 · 퇴근 버튼만 숨긴다.
    static let notWorking = ForceUpdateState(
        message: sample.message, currentVersion: "1.4.2", requiredVersion: "1.5.0", size: "18MB", working: nil)
}
