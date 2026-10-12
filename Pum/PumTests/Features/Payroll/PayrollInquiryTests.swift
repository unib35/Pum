// UI-IOS-6n · REQ-096 — 급여 계산 문의 상태
import Testing
@testable import Pum

struct PayrollInquiryTests {
    let state = PayrollInquiryState.sample

    @Test func 원문_값() {
        #expect(PayrollInquiryState.headerTitle == "급여 문의")
        #expect(PayrollInquiryState.titleLines == ["급여 계산에", "문제가 있나요?"])
        #expect(state.rows.map(\.label) == ["사업장", "기간", "명세서 금액"])
        #expect(state.rows.map(\.value) == ["종민김밥 본점", "2026년 10월", "1,188,000원"])
        #expect(InquiryItem.allCases.map(\.title) == ["근무시간", "기본급", "주휴수당", "연장수당", "공제"])
        #expect(InquiryRecipient.owner.title == "사장님께 문의")
        #expect(InquiryRecipient.owner.detail == "근무 인정 · 급여 기준 관련")
        #expect(InquiryRecipient.support.title == "고객센터에 문의")
        #expect(InquiryRecipient.support.detail == "앱 계산 오류가 의심될 때")
        #expect(state.evidenceDetail == "10월 근무기록 17건 · 주휴 계산 과정")
    }

    @Test func 초안_기본값() {
        let d = state.initialDraft
        #expect(d.item == .weeklyHoliday)
        #expect(d.attachesEvidence)
        #expect(d.recipient == .owner)
        #expect(d.body == "10월 넷째 주에 15시간 넘게 일했는데 주휴수당이 빠진 것 같아요.")
        #expect(!state.hasChanges(d))
    }

    @Test func 보낼_내용_구성() {
        var d = state.initialDraft
        d.item = .deduction
        d.body = "  공제가 많아요.\n"
        d.attachesEvidence = false
        d.recipient = .support
        let s = state.submission(d)
        let expected = PayrollInquirySubmission(item: .deduction, body: "공제가 많아요.", attachesEvidence: false, recipient: .support)
        #expect(s == expected)
        #expect(state.hasChanges(d))
    }

    @Test func 내용이_비면_보낼_수_없다() {
        var d = state.initialDraft
        #expect(state.canSend(d))
        d.body = " \n "
        #expect(!state.canSend(d))
    }

    @Test func 읽기_문구() {
        #expect(state.summarySpoken == "사업장 종민김밥 본점, 기간 2026년 10월, 명세서 금액 1,188,000원")
        #expect(state.evidenceSpoken == "계산 근거 함께 보내기, 10월 근무기록 17건 · 주휴 계산 과정")
    }
}
