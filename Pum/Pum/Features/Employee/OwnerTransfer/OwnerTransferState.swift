// UI-IOS-17j · REQ-014 — 사장님 · 대표 변경. 받을 수 있는지 · 이름 · 색은 서버 값(화면이 정하지 않음).
// 받을 사람 · 나는 선택은 화면 초안이고, 상대가 수락할 때까지 아무것도 바뀌지 않는다.
import Foundation

/// 받을 사람 후보 한 명 — 점장처럼 아직 관리자가 아니면 선택할 수 없다(서버 값)
nonisolated struct OwnerTransferCandidate: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    /// 아바타 색 번호 — 서버 값
    let colorIndex: Int
    /// 「관리자」 · 「점장 · 관리자가 된 뒤 받을 수 있어요」 — 서버 값
    let detail: String
    let isSelectable: Bool
}

nonisolated enum OwnerTransferMyRole: String, CaseIterable, Identifiable, Equatable, Sendable {
    case stayAdmin, leave

    var id: String { rawValue }
    var title: String {
        switch self {
        case .stayAdmin: "관리자로 남기"
        case .leave: "사업장 떠나기"
        }
    }
}

/// 화면 초안 — 서버 초기값에서 시작
nonisolated struct OwnerTransferDraft: Equatable, Sendable {
    var recipientID: String?
    var myRole: OwnerTransferMyRole
}

nonisolated struct OwnerTransferState: Equatable, Sendable {
    static let backTitle = "사업장 설정"
    static let title = "대표 변경"
    static let currentHeader = "지금"
    static let recipientHeader = "받을 사람"
    static let myRoleHeader = "나는"
    static let sendTitle = "본인인증 후 요청 보내기"
    static let sendingTitle = "보내는 중"
    /// 원문 없음 — 받을 수 있는 관리자가 없을 때 보내기 비활성 이유
    static let noCandidateHint = "받을 수 있는 관리자가 없어요"
    /// 원문 없음 — 받을 사람을 고르지 않았을 때
    static let pickHint = "받을 사람을 골라 주세요"

    /// 지금 대표 — 「박민수」
    let currentOwnerName: String
    /// 회색 원 글자 — 원문 「박」(공통 아바타의 이름 규칙과 달리 성)
    let currentOwnerInitial: String
    /// 「사업자 대표자 · 지금 대표」
    let currentOwnerDetail: String
    let candidates: [OwnerTransferCandidate]
    let initialDraft: OwnerTransferDraft

    func candidate(_ id: String?) -> OwnerTransferCandidate? { candidates.first { $0.id == id } }

    /// 선택된 받을 사람 — 선택할 수 없는 사람이면 nil
    func recipient(_ draft: OwnerTransferDraft) -> OwnerTransferCandidate? {
        candidate(draft.recipientID).flatMap { $0.isSelectable ? $0 : nil }
    }

    /// 「이종민님은 「위임받은 대표」로 표시」
    func delegateTitle(_ draft: OwnerTransferDraft) -> String {
        "\(recipient(draft)?.name ?? "")님은 「위임받은 대표」로 표시"
    }

    /// 「사업자 대표자는 박민수 그대로 · 내 본인인증이 위임 동의가 돼요」
    var delegateDetail: String { "사업자 대표자는 \(currentOwnerName) 그대로 · 내 본인인증이 위임 동의가 돼요" }

    /// 「이종민님이 수락하면 바뀌어요 · 활동 기록에 남아요」
    func footerNotice(_ draft: OwnerTransferDraft) -> String {
        "\(recipient(draft)?.name ?? "")님이 수락하면 바뀌어요 · 활동 기록에 남아요"
    }

    /// 「이종민, 관리자」 · 「오세진, 점장 · …, 선택할 수 없음」 — 선택됨은 특성으로 읽는다
    func recipientReadout(_ c: OwnerTransferCandidate) -> String {
        c.isSelectable ? "\(c.name), \(c.detail)" : "\(c.name), \(c.detail), 선택할 수 없음"
    }

    var hasSelectable: Bool { candidates.contains { $0.isSelectable } }

    func canSend(_ draft: OwnerTransferDraft) -> Bool { recipient(draft) != nil }

    /// 보내기가 꺼진 이유 — 켜져 있으면 nil
    func disabledReason(_ draft: OwnerTransferDraft) -> String? {
        if !hasSelectable { return Self.noCandidateHint }
        if recipient(draft) == nil { return Self.pickHint }
        return nil
    }

    static let sample = OwnerTransferState(
        currentOwnerName: "박민수",
        currentOwnerInitial: "박",
        currentOwnerDetail: "사업자 대표자 · 지금 대표",
        candidates: [
            OwnerTransferCandidate(id: "jongmin", name: "이종민", colorIndex: 0, detail: "관리자", isSelectable: true),
            OwnerTransferCandidate(id: "sejin", name: "오세진", colorIndex: 4, detail: "점장 · 관리자가 된 뒤 받을 수 있어요", isSelectable: false),
        ],
        initialDraft: OwnerTransferDraft(recipientID: "jongmin", myRole: .stayAdmin)
    )
}
