// UI-IOS-17j · REQ-014 — 대표 변경 원문 값 · 선택 불가 행 · 안내 문구 · 보내기 조건
import Testing
@testable import Pum

struct OwnerTransferTests {
    private let state = OwnerTransferState.sample

    @Test func 원문_값() {
        #expect(OwnerTransferState.title == "대표 변경")
        #expect(OwnerTransferState.backTitle == "사업장 설정")
        #expect(OwnerTransferState.sendTitle == "본인인증 후 요청 보내기")
        #expect(state.currentOwnerName == "박민수")
        #expect(state.currentOwnerInitial == "박")
        #expect(state.currentOwnerDetail == "사업자 대표자 · 지금 대표")
        #expect(state.candidates.map(\.name) == ["이종민", "오세진"])
        #expect(state.candidates.map(\.detail) == ["관리자", "점장 · 관리자가 된 뒤 받을 수 있어요"])
        #expect(OwnerTransferMyRole.allCases.map(\.title) == ["관리자로 남기", "사업장 떠나기"])
        #expect(state.initialDraft.recipientID == "jongmin")
        #expect(state.initialDraft.myRole == .stayAdmin)
        #expect(state.delegateDetail == "사업자 대표자는 박민수 그대로 · 내 본인인증이 위임 동의가 돼요")
    }

    @Test func 선택_불가_행() {
        let sejin = state.candidates[1]
        #expect(!sejin.isSelectable)
        #expect(state.recipientReadout(sejin) == "오세진, 점장 · 관리자가 된 뒤 받을 수 있어요, 선택할 수 없음")
        #expect(state.recipientReadout(state.candidates[0]) == "이종민, 관리자")
        let picked = OwnerTransferDraft(recipientID: "sejin", myRole: .stayAdmin)
        #expect(state.recipient(picked) == nil)
        #expect(!state.canSend(picked))
    }

    @Test func 안내_문구에_선택_이름이_들어간다() {
        let draft = state.initialDraft
        #expect(state.delegateTitle(draft) == "이종민님은 「위임받은 대표」로 표시")
        #expect(state.footerNotice(draft) == "이종민님이 수락하면 바뀌어요 · 활동 기록에 남아요")
        let other = OwnerTransferState(
            currentOwnerName: "박민수", currentOwnerInitial: "박", currentOwnerDetail: "사업자 대표자 · 지금 대표",
            candidates: [
                OwnerTransferCandidate(id: "a", name: "이종민", colorIndex: 0, detail: "관리자", isSelectable: true),
                OwnerTransferCandidate(id: "b", name: "김하늘", colorIndex: 1, detail: "관리자", isSelectable: true),
            ],
            initialDraft: OwnerTransferDraft(recipientID: "a", myRole: .leave))
        let draftB = OwnerTransferDraft(recipientID: "b", myRole: .leave)
        #expect(other.delegateTitle(draftB) == "김하늘님은 「위임받은 대표」로 표시")
        #expect(other.footerNotice(draftB) == "김하늘님이 수락하면 바뀌어요 · 활동 기록에 남아요")
    }

    @Test func 보내기_가능_조건() {
        #expect(state.canSend(state.initialDraft))
        #expect(state.disabledReason(state.initialDraft) == nil)
        let none = OwnerTransferDraft(recipientID: nil, myRole: .leave)
        #expect(!state.canSend(none))
        #expect(state.disabledReason(none) == OwnerTransferState.pickHint)
    }

    @Test func 받을_수_있는_관리자가_없으면_보낼_수_없다() {
        let empty = OwnerTransferState(
            currentOwnerName: "박민수", currentOwnerInitial: "박", currentOwnerDetail: "사업자 대표자 · 지금 대표",
            candidates: [state.candidates[1]],
            initialDraft: OwnerTransferDraft(recipientID: nil, myRole: .stayAdmin))
        #expect(!empty.hasSelectable)
        #expect(!empty.canSend(empty.initialDraft))
        #expect(empty.disabledReason(empty.initialDraft) == OwnerTransferState.noCandidateHint)
    }
}
