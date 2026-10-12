// UI-IOS-6b · REQ-090 — 회원 탈퇴 상태
import Testing
@testable import Pum

struct WithdrawTests {
    @Test func 원문_값() {
        let s = WithdrawState.sample
        #expect(s.workplaces.count == 1)
        #expect(s.workplaces[0].name == "종민김밥 본점")
        #expect(s.workplaces[0].initial == "종")
        #expect(s.workplaces[0].statusText == "박민수님이 유일한 대표(Owner)예요")
        #expect(s.consequencesTitle == "탈퇴하면")
        #expect(s.consequences.count == 4)
        #expect(s.withdrawTitle == "소유권 이전 후 탈퇴할 수 있어요")
        #expect(s.staffNote.hasPrefix("직원으로 소속된 사업장이"))
    }

    @Test func 굵은_부분은_보관_기간만() {
        let retain = WithdrawState.sample.consequences[1]
        let bold = retain.runs.filter(\.isBold).map(\.text)
        #expect(bold == ["3년간 분리 보관"])
        #expect(retain.plainText == "근무기록 \u{00B7} 급여대장 \u{00B7} 근로계약서처럼 법정 보존 대상인 기록은 3년간 분리 보관 후 파기돼요")
    }

    @Test func 정리할_사업장이_있으면_탈퇴_비활성() {
        let s = WithdrawState.sample
        #expect(!s.canWithdraw)
        #expect(s.blockedReason == "정리할 사업장이 1곳 남아 있어요")
    }

    @Test func 정리할_사업장이_없으면_탈퇴_활성() {
        let s = WithdrawState.cleared
        #expect(s.canWithdraw)
        #expect(s.blockedReason == nil)
    }

    @Test func 사업장_카드_읽기() {
        let w = WithdrawState.sample.workplaces[0]
        #expect(w.spoken.hasPrefix("종민김밥 본점, 박민수님이 유일한 대표(Owner)예요, 계정을 삭제하기 전에"))
    }
}
