// UI-IOS-17h · REQ-014 — 사장님 · 관리자 초대. 역할 설명 · 사업장 인증 · 유효기간 문구는 서버 값(화면이 정하지 않음).
// 역할 · 이름 · 번호 · 방법은 화면 초안이고, 번호는 입력 그대로 보낸다(형식을 바꾸지 않음).
import Foundation

nonisolated enum ManagerInviteRole: String, CaseIterable, Identifiable, Equatable, Sendable {
    case admin, manager

    var id: String { rawValue }
    var title: String {
        switch self {
        case .admin: "관리자"
        case .manager: "점장"
        }
    }
}

nonisolated enum ManagerInviteMethod: String, CaseIterable, Identifiable, Equatable, Sendable {
    case alimtalk, sms

    var id: String { rawValue }
    var title: String {
        switch self {
        case .alimtalk: "알림톡"
        case .sms: "문자"
        }
    }
}

/// 화면 초안 — 서버 초기값에서 시작
nonisolated struct ManagerInviteDraft: Equatable, Sendable {
    var role: ManagerInviteRole
    var name: String
    var phone: String
    var method: ManagerInviteMethod
}

nonisolated struct ManagerInviteState: Equatable, Sendable {
    static let backTitle = "관리자"
    static let title = "관리자 초대"
    static let verifiedBadge = "✓ 인증된 사업장"
    static let roleHeader = "역할"
    static let nameLabel = "이름"
    static let phoneLabel = "휴대폰 번호"
    static let methodLabel = "보내는 방법"
    static let sendTitle = "초대 보내기"
    static let sendingTitle = "보내는 중"
    /// 원문 없음 — 미인증 사업장일 때 보내기 비활성 이유(VoiceOver 힌트)
    static let unverifiedHint = "인증된 사업장만 초대할 수 있어요"
    /// 원문 없음 — 이름 · 번호가 비었을 때 비활성 이유
    static let incompleteHint = "이름과 휴대폰 번호를 입력해 주세요"

    /// 「종민김밥 본점 · 대표 박민수」
    let businessText: String
    /// 사업장 인증 여부 — 서버 값
    let isVerified: Bool
    /// 역할별 설명 — 서버 값
    let roleDescriptions: [ManagerInviteRole: String]
    /// 「7일 동안 · 이 번호로만 수락 · 활동 기록에 남아요」 — 서버 값
    let footerNotice: String
    let initialDraft: ManagerInviteDraft

    func description(of role: ManagerInviteRole) -> String { roleDescriptions[role] ?? "" }

    /// 「관리자, 급여 확정 · …」 — 선택 여부는 특성으로 읽는다
    func roleReadout(_ role: ManagerInviteRole) -> String { "\(role.title), \(description(of: role))" }

    var verifiedReadout: String { "인증된 사업장, \(businessText)" }

    /// 이름 · 번호가 비어 있지 않고(공백만도 빈 것) 인증된 사업장일 때만 보낼 수 있다
    func canSend(_ draft: ManagerInviteDraft) -> Bool {
        isVerified && !Self.isBlank(draft.name) && !Self.isBlank(draft.phone)
    }

    /// 보내기가 꺼진 이유 — 켜져 있으면 nil
    func disabledReason(_ draft: ManagerInviteDraft) -> String? {
        if !isVerified { return Self.unverifiedHint }
        if Self.isBlank(draft.name) || Self.isBlank(draft.phone) { return Self.incompleteHint }
        return nil
    }

    private static func isBlank(_ s: String) -> Bool { s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    static let sample = ManagerInviteState(
        businessText: "종민김밥 본점 · 대표 박민수",
        isVerified: true,
        roleDescriptions: [
            .admin: "급여 확정 · 지급 · 직원 정보까지 · 대표 변경과 사업장 삭제는 제외",
            .manager: "스케줄 · 근태 · 요청만 · 금액과 개인정보는 안 보임 · 권한은 켜서 주기",
        ],
        footerNotice: "7일 동안 · 이 번호로만 수락 · 활동 기록에 남아요",
        initialDraft: ManagerInviteDraft(role: .admin, name: "이종민", phone: "010-2291-4410", method: .alimtalk)
    )
}
