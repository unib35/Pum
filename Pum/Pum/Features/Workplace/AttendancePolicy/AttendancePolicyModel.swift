// UI-IOS-1an · REQ-026 · REQ-093 · REQ-024 · REQ-025 · DEC-004 — 사업장 설정: 근태 정책 데이터
// 연장근무 정책 A/B/C와 자동 인정 기준(조기퇴근 · 지각 · 연장 공통). 리마인드 값은 서버 값 표시만(화면에서 바꾸지 않는다).
import Foundation

nonisolated enum OvertimePolicy: Int, CaseIterable, Equatable, Sendable, Identifiable {
    case autoApprove, confirmOverThreshold, preApproval
    var id: Int { rawValue }

    /// 「A · 자동 인정」
    var title: String {
        switch self {
        case .autoApprove: "A · 자동 인정"
        case .confirmOverThreshold: "B · 기준 초과분만 사장님 확인"
        case .preApproval: "C · 사전 승인 필요"
        }
    }

    var detail: String {
        switch self {
        case .autoApprove: "실제 기록 그대로 급여 반영. 확인 절차 없음"
        case .confirmOverThreshold: "예정과의 차이가 기준 이내면 자동 인정, 넘으면 확인 필요로"
        case .preApproval: "미리 승인한 연장 시간만 자동 인정, 나머지는 확인 필요로"
        }
    }

    /// 자동 인정 기준 알약은 B일 때만(REQ-026)
    var usesThreshold: Bool { self == .confirmOverThreshold }
}

/// 자동 인정 기준(분). 조기퇴근 · 지각 · 연장에 공통으로 적용(REQ-026)
nonisolated enum AutoApproveThreshold: Int, CaseIterable, Equatable, Sendable, Identifiable {
    case m15 = 15, m30 = 30, m45 = 45, m60 = 60
    var id: Int { rawValue }
    var minutes: Int { rawValue }
    /// 「15분」 · 「30분」 · 「45분」 · 「1시간」
    var label: String { minutes % 60 == 0 ? "\(minutes / 60)시간" : "\(minutes)분" }
}

nonisolated struct ReminderRow: Equatable, Sendable, Identifiable {
    let label: String
    let value: String
    /// 값 바로 뒤 덧붙임(12px 보조색). 없으면 nil
    var suffix: String? = nil
    var id: String { label }

    /// 「근무 상태 자동 종료, 예정 퇴근 +6시간, 미확정 처리」
    var accessibilityText: String {
        var parts = [label, value]
        if let suffix { parts.append(suffix.replacingOccurrences(of: "·", with: "").trimmingCharacters(in: .whitespaces)) }
        return parts.joined(separator: ", ")
    }
}

nonisolated struct AttendancePolicyRecord: Equatable, Sendable {
    var workplaceName: String
    var subtitle: String
    var policy: OvertimePolicy
    var threshold: AutoApproveThreshold
    var reminders: [ReminderRow]
    var noteLead: String     // 「자동 종료는 」
    var noteStrong: String   // 「세션만」
    var noteTail: String     // 「 닫아요. …」

    /// 자동 종료 = 예정 퇴근 + 6시간 고정(DEC-004). 서버 값과 같은 모델 상수.
    static let autoCloseHours = 6

    static let sample = AttendancePolicyRecord(
        workplaceName: "종민김밥 본점",
        subtitle: "예정 시간은 알림·이상 감지에만 쓰고, 급여는 실제 기록으로 계산해요",
        policy: .confirmOverThreshold, threshold: .m45,
        reminders: [
            .init(label: "알림 시점", value: "예정 시각 · +30분 · +1시간"),
            .init(label: "무응답 시", value: "근무 중 유지"),
            .init(label: "근무 상태 자동 종료", value: "예정 퇴근 +\(autoCloseHours)시간", suffix: " · 미확정 처리"),
            .init(label: "사장님에게 초과 알림", value: "예정 퇴근 +30분"),
        ],
        noteLead: "자동 종료는 ", noteStrong: "세션만",
        noteTail: " 닫아요. 퇴근시간은 미확정으로 남고, 직원 입력과 사장님 확인을 거쳐야 급여에 반영돼요.")
}
