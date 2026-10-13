// UI-IOS-17h · REQ-014 — 관리자 초대 원문 값 · 보내기 조건 · 읽기 문구
import Testing
@testable import Pum

struct ManagerInviteTests {
    private let state = ManagerInviteState.sample

    @Test func 원문_값() {
        #expect(state.businessText == "종민김밥 본점 · 대표 박민수")
        #expect(state.isVerified)
        #expect(state.initialDraft.role == .admin)
        #expect(state.initialDraft.name == "이종민")
        #expect(state.initialDraft.phone == "010-2291-4410")
        #expect(state.initialDraft.method == .alimtalk)
        #expect(ManagerInviteRole.allCases.map(\.title) == ["관리자", "점장"])
        #expect(ManagerInviteMethod.allCases.map(\.title) == ["알림톡", "문자"])
        #expect(state.footerNotice == "7일 동안 · 이 번호로만 수락 · 활동 기록에 남아요")
    }

    @Test func 보내기_가능_조건() {
        let draft = state.initialDraft
        #expect(state.canSend(draft))
        let noName = ManagerInviteDraft(role: .admin, name: "  ", phone: draft.phone, method: .sms)
        #expect(!state.canSend(noName))
        let noPhone = ManagerInviteDraft(role: .manager, name: "이종민", phone: "", method: .sms)
        #expect(!state.canSend(noPhone))
        #expect(state.disabledReason(noPhone) == ManagerInviteState.incompleteHint)
        #expect(state.disabledReason(draft) == nil)
    }

    @Test func 미인증_사업장은_보낼_수_없다() {
        let unverified = ManagerInviteState(businessText: state.businessText, isVerified: false,
                                            roleDescriptions: state.roleDescriptions,
                                            footerNotice: state.footerNotice, initialDraft: state.initialDraft)
        #expect(!unverified.canSend(unverified.initialDraft))
        #expect(unverified.disabledReason(unverified.initialDraft) == ManagerInviteState.unverifiedHint)
    }

    @Test func 번호는_입력_그대로() {
        let draft = ManagerInviteDraft(role: .admin, name: "a", phone: "01022914410", method: .alimtalk)
        #expect(draft.phone == "01022914410")
    }

    @Test func 읽기_문구() {
        #expect(state.roleReadout(.admin) == "관리자, 급여 확정 · 지급 · 직원 정보까지 · 대표 변경과 사업장 삭제는 제외")
        #expect(state.roleReadout(.manager).hasPrefix("점장, 스케줄 · 근태 · 요청만"))
        #expect(state.verifiedReadout == "인증된 사업장, 종민김밥 본점 · 대표 박민수")
    }
}
