// UI-IOS-1ao · REQ-026 · REQ-029 · DEC-005 — 조기 퇴근 사유 시트 데이터
// 인정 시간 · 금액은 서버(엔진)가 준 값을 그대로 보여 준다 — 화면에서 계산하지 않는다.
// 「일찍」 분 수와 「자동 인정 기준 밖」 판단만 여기서 한다(예정 퇴근 − 지금). 기록은 어떤 경우에도 막지 않는다(REQ-029).
import Foundation

nonisolated enum EarlyLeaveReason: CaseIterable, Sendable {
    case ownerSentHome, personal, unwell, other

    var title: String {
        switch self {
        case .ownerSentHome: "사장님이 일찍 보내주셨어요"
        case .personal: "개인 사정"
        case .unwell: "몸이 안 좋아요"
        case .other: "기타"
        }
    }
}

nonisolated struct EarlyLeaveState: Equatable, Sendable {
    var workplaceName: String
    var workplaceInitial: String
    /// 출근 · 지금 · 예정 구간 (하루 안의 분)
    var clockInMinute: Int
    var nowMinute: Int
    var plannedStartMinute: Int
    var plannedEndMinute: Int
    /// 사업장 자동 인정 기준(분) — 주입(DEC-005)
    var autoApproveMinutes: Int
    /// 서버가 준 인정 문구 값(화면에서 계산하지 않음)
    var plannedRecognizedText: String
    var actualRecognizedText: String
    var actualRecognizedPay: Int
    /// 뒤 화면 「근무 중」 지난 시간(분) — 서버/홈 값
    var elapsedMinutes: Int
    var selected: EarlyLeaveReason?

    /// 예정 퇴근 − 지금 (분)
    var earlyMinutes: Int { max(0, plannedEndMinute - nowMinute) }
    /// 45분 = 기준 안, 46분부터 사장님 확인 대상(경계는 기준 안)
    var needsOwnerCheck: Bool { earlyMinutes > autoApproveMinutes }

    var nowText: String { EarlyLeaveFormat.clock(nowMinute) }
    /// 80 → 「1시간 20분 일찍」, 120 → 「2시간 일찍」, 30 → 「30분 일찍」
    var earlyText: String { HomeFormat.hours(earlyMinutes) + " 일찍" }
    var subtitlePrefix: String { "지금 \(nowText) · 예정 퇴근 \(EarlyLeaveFormat.clock(plannedEndMinute)) · " }
    var plannedRange: String { PumFormat.timeRange(EarlyLeaveFormat.clock(plannedStartMinute), EarlyLeaveFormat.clock(plannedEndMinute)) }
    var actualRange: String { PumFormat.timeRange(EarlyLeaveFormat.clock(clockInMinute), nowText) }
    var plannedRecognizedLine: String { "인정 \(plannedRecognizedText)" }
    var actualRecognizedLine: String { "인정 \(actualRecognizedText) · \(PumFormat.amount(actualRecognizedPay))원" }
    var recordTitle: String { "\(nowText) 퇴근 기록" }
    var noticeLead: String { "실제 퇴근 \(nowText)으로 기록돼요. 예정과 \(autoApproveMinutes)분 넘게 차이 나서 " }
    static let noticeStrong = "사장님 확인 대상"
    static let noticeTail = "이 되고, 사유가 함께 전달돼요."

    /// 사유 없이도 기록된다(REQ-029) — 미선택이면 nil
    var recordedReason: EarlyLeaveReason? { selected }
}

nonisolated enum EarlyLeaveFormat {
    static func clock(_ minute: Int) -> String { String(format: "%02d:%02d", (minute / 60) % 24, minute % 60) }
}

extension EarlyLeaveState {
    /// 디자인 1ao 예시 값(가짜 데이터): 출근 16:58, 지금 20:40, 예정 17:00–22:00
    static let sample = EarlyLeaveState(
        workplaceName: "종민김밥 본점", workplaceInitial: "종",
        clockInMinute: 16 * 60 + 58, nowMinute: 20 * 60 + 40,
        plannedStartMinute: 17 * 60, plannedEndMinute: 22 * 60,
        autoApproveMinutes: 45,
        plannedRecognizedText: "4시간 30분", actualRecognizedText: "3시간 12분", actualRecognizedPay: 38_400,
        elapsedMinutes: 3 * 60 + 42,
        selected: .ownerSentHome
    )
}
