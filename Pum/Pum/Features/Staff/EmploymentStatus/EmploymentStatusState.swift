// UI-IOS-6j · REQ-063 — 재직 상태 변경(퇴사 상태). 날짜 · 건수 · 문구는 모두 서버 값(화면이 계산하지 않음).
// 세그먼트 선택 · 사유는 저장 전 초안(Draft).
import Foundation

nonisolated enum EmploymentStatus: String, CaseIterable, Identifiable, Equatable, Sendable {
    case active, leave, left

    var id: String { rawValue }
    var title: String {
        switch self {
        case .active: "재직"
        case .leave: "휴직"
        case .left: "퇴사"
        }
    }
}

nonisolated enum LeaveReason: String, CaseIterable, Identifiable, Equatable, Sendable {
    case contractEnd, voluntary, other

    var id: String { rawValue }
    var title: String {
        switch self {
        case .contractEnd: "계약 만료"
        case .voluntary: "자진 퇴사"
        case .other: "기타"
        }
    }
}

nonisolated struct EmploymentStatusDraft: Equatable, Sendable {
    var status: EmploymentStatus
    var reason: LeaveReason
}

/// 퇴사 정보 카드 한 줄 — 왼쪽 라벨 · 오른쪽 값(둘 다 서버 값)
nonisolated struct EmploymentInfoRow: Identifiable, Equatable, Sendable {
    let id: String
    let label: String
    let value: String
    var spoken: String { "\(label), \(value)" }
}

nonisolated struct EmploymentStatusState: Equatable, Sendable {
    static let headerTitle = "재직 상태"
    static let reasonHeader = "사유"
    static let noticeEmphasis = "재초대"
    /// 퇴사일 행 id — 이 행만 눌린다
    static let leaveDateRowID = "leaveDate"

    let targetName: String
    /// 「2026.03.02 입사 · 토·일 09–15 · 시급 11,000원」
    let subtitle: String
    let status: EmploymentStatus
    let reason: LeaveReason
    let rows: [EmploymentInfoRow]
    /// 「3년」 — 법정 보존 기간(서버 값)
    let retentionPeriod: String

    var confirmTitle: String { "퇴사 처리 · \(targetName)에게 알림" }
    var initialDraft: EmploymentStatusDraft { EmploymentStatusDraft(status: status, reason: reason) }

    var noticeBefore: String { "퇴사 후에도 근무기록 · 명세서 · 계약서는 법정 보존 기간(\(retentionPeriod)) 동안 보관되고, 직원도 자기 문서함에서 계속 볼 수 있어요. 다시 함께하려면 " }
    var noticeAfter: String { "하면 돼요." }
    var noticeSpoken: String { noticeBefore + Self.noticeEmphasis + noticeAfter }
    var headerSpoken: String { "\(targetName), \(subtitle)" }

    func choosing(_ draft: EmploymentStatusDraft, status: EmploymentStatus) -> EmploymentStatusDraft {
        var d = draft
        d.status = status
        return d
    }

    func choosing(_ draft: EmploymentStatusDraft, reason: LeaveReason) -> EmploymentStatusDraft {
        var d = draft
        d.reason = reason
        return d
    }

    /// 초안이 서버 값과 다른가 — 서버 값이 새로 올 때 편집 중인 초안을 지우지 않기 위한 판정
    func hasChanges(_ draft: EmploymentStatusDraft) -> Bool { draft != initialDraft }

    static let sample = EmploymentStatusState(
        targetName: "박서준",
        subtitle: "2026.03.02 입사 · 토·일 09–15 · 시급 11,000원",
        status: .left,
        reason: .contractEnd,
        rows: [
            EmploymentInfoRow(id: "leaveDate", label: "퇴사일", value: "2027.03.31 (수)"),
            EmploymentInfoRow(id: "lastWork", label: "마지막 근무", value: "2027.03.28 (일)"),
            EmploymentInfoRow(id: "remaining", label: "남은 근무 일정", value: "4건 · 퇴사일 후 자동 취소"),
            EmploymentInfoRow(id: "lastPay", label: "마지막 급여", value: "4월 10일 · 3월분 정산"),
            EmploymentInfoRow(id: "contract", label: "근로계약", value: "2027.03.31 종료"),
        ],
        retentionPeriod: "3년"
    )
}
