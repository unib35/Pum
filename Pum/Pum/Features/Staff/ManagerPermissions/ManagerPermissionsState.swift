// UI-IOS-6h · REQ-014 — 관리자 권한(RBAC) 상태. 역할별 기본값 · 잠금 여부는 모두 서버 값(화면이 정하지 않음).
// 저장 전 바뀐 값은 화면의 초안(Draft)이 들고, 순수 로직은 이 파일의 함수로 둔다.
import Foundation

nonisolated enum ManagerRole: String, CaseIterable, Identifiable, Equatable, Sendable {
    case owner, admin, manager

    var id: String { rawValue }
    var title: String {
        switch self {
        case .owner: "대표"
        case .admin: "관리자"
        case .manager: "점장"
        }
    }
}

nonisolated enum ManagerPermissionGroup: Equatable, Sendable { case operations, sensitive }

nonisolated struct ManagerPermissionItem: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let group: ManagerPermissionGroup
    /// 이 역할일 때 토글을 잠그는 역할들 — 서버 값
    let lockedRoles: Set<ManagerRole>
    /// 잠겼을 때 보이는 회색 문구 — 서버 값
    let lockedNote: String?

    func isLocked(for role: ManagerRole) -> Bool { lockedRoles.contains(role) }
}

/// 저장 전 편집 값
nonisolated struct ManagerPermissionsDraft: Equatable, Sendable {
    var role: ManagerRole
    var enabled: Set<String>
}

nonisolated struct ManagerPermissionsState: Equatable, Sendable {
    static let headerTitle = "관리자 권한"
    static let operationsHeader = "근태 · 운영"
    static let sensitiveHeader = "급여 · 계약 · 개인정보"

    let targetName: String
    /// 「종민김밥 본점 · 10/10 지정 · 대표 박민수 위임」
    let subtitle: String
    /// 「점장 기본값 꺼짐」 — 급여 섹션 제목 뒤 회색 문구
    let sensitiveSuffix: String
    let items: [ManagerPermissionItem]
    /// 저장된 역할 · 켜진 권한
    let role: ManagerRole
    let enabled: Set<String>
    /// 역할별 서버 기본값(켜진 권한 id)
    let roleDefaults: [ManagerRole: Set<String>]

    var saveTitle: String { "저장 · \(targetName)에게 알림" }

    var initialDraft: ManagerPermissionsDraft { ManagerPermissionsDraft(role: role, enabled: enabled) }

    func items(in group: ManagerPermissionGroup) -> [ManagerPermissionItem] { items.filter { $0.group == group } }

    func isLocked(_ item: ManagerPermissionItem, in draft: ManagerPermissionsDraft) -> Bool {
        item.isLocked(for: draft.role)
    }

    /// 역할을 바꾸면 토글이 그 역할의 서버 기본값으로 바뀐다. 대표는 별도 화면(17j)이라 초안을 바꾸지 않는다.
    func changingRole(_ draft: ManagerPermissionsDraft, to newRole: ManagerRole) -> ManagerPermissionsDraft {
        guard newRole != .owner, newRole != draft.role else { return draft }
        return ManagerPermissionsDraft(role: newRole, enabled: roleDefaults[newRole] ?? [])
    }

    /// 잠긴 행은 바뀌지 않는다.
    func setting(_ draft: ManagerPermissionsDraft, id: String, isOn: Bool) -> ManagerPermissionsDraft {
        guard let item = items.first(where: { $0.id == id }), !item.isLocked(for: draft.role) else { return draft }
        var next = draft
        if isOn { next.enabled.insert(id) } else { next.enabled.remove(id) }
        return next
    }

    func isOn(_ item: ManagerPermissionItem, in draft: ManagerPermissionsDraft) -> Bool { draft.enabled.contains(item.id) }

    /// 저장된 값과 다른지 — 다르지 않으면 저장 버튼 비활성(원문 없음, 화면에서 정함)
    func hasChanges(_ draft: ManagerPermissionsDraft) -> Bool { draft != initialDraft }

    /// 저장에 보내는 권한 목록 — 화면 순서
    func enabledIDs(_ draft: ManagerPermissionsDraft) -> [String] {
        items.map(\.id).filter { draft.enabled.contains($0) }
    }

    func spoken(_ item: ManagerPermissionItem, in draft: ManagerPermissionsDraft) -> String {
        if item.isLocked(for: draft.role), let note = item.lockedNote { return "\(item.title), \(note)" }
        return item.title
    }

    static let sample: ManagerPermissionsState = {
        let items = [
            ManagerPermissionItem(id: "staff-list", title: "직원 목록 보기", group: .operations, lockedRoles: [], lockedNote: nil),
            ManagerPermissionItem(id: "schedule", title: "근무 일정 관리", group: .operations, lockedRoles: [], lockedNote: nil),
            ManagerPermissionItem(id: "attendance", title: "출퇴근 기록 확인 · 수정 요청 승인", group: .operations, lockedRoles: [], lockedNote: nil),
            ManagerPermissionItem(id: "notice", title: "공지 작성", group: .operations, lockedRoles: [], lockedNote: nil),
            ManagerPermissionItem(id: "payroll-view", title: "급여 조회", group: .sensitive, lockedRoles: [], lockedNote: nil),
            ManagerPermissionItem(id: "payroll-confirm", title: "급여 확정 · 명세서 발행", group: .sensitive, lockedRoles: [.manager], lockedNote: "대표 · 관리자만 켤 수 있어요"),
            ManagerPermissionItem(id: "contract", title: "근로계약 작성 · 발송", group: .sensitive, lockedRoles: [], lockedNote: nil),
            ManagerPermissionItem(id: "documents", title: "직원 서류 · 계좌 조회", group: .sensitive, lockedRoles: [], lockedNote: nil),
            ManagerPermissionItem(id: "workplace", title: "사업장 설정", group: .sensitive, lockedRoles: [], lockedNote: nil),
        ]
        let operations: Set<String> = ["staff-list", "schedule", "attendance", "notice"]
        let all = Set(items.map(\.id))
        return ManagerPermissionsState(
            targetName: "김민지",
            subtitle: "종민김밥 본점 · 10/10 지정 · 대표 박민수 위임",
            sensitiveSuffix: "점장 기본값 꺼짐",
            items: items,
            role: .manager,
            enabled: operations,
            roleDefaults: [.admin: all, .manager: operations])
    }()
}
