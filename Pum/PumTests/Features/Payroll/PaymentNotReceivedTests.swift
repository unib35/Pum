// UI-IOS-21c · REQ-076 — 아직 입금 안 됐어요: 단일 선택 · 메모 자르기 · 보내기 한 번만 · 지급 완료에서만 열림
import Testing
import Foundation
@testable import Pum

struct PaymentNotReceivedTests {
    let s = PaymentNotReceivedState.sample

    @Test func 원문_값() {
        #expect(s.summaryText == "종민김밥 본점 \u{00B7} 10월분")
        #expect(s.netPayText == "1,062,000원")
        #expect(s.paidDetail == "11월 10일 14:20 \u{00B7} 국민은행 \u{2022}\u{2022}1234")
        #expect(s.reasons.map(\.title) == ["아직 들어오지 않았어요", "금액이 달라요"])
        #expect(s.defaultReasonId == "not_arrived")
    }

    @Test func 사유는_하나만_선택() {
        var d = PaymentNotReceivedDraft(reasonId: s.defaultReasonId)
        d.select("amount_differs")
        #expect(d.reasonId == "amount_differs")
        #expect(d.canSend)
    }

    @Test func 사유가_없으면_보낼_수_없다() {
        let d = PaymentNotReceivedDraft()
        #expect(!d.canSend)
    }

    @Test func 메모는_100자로_자른다() {
        var d = PaymentNotReceivedDraft()
        d.setMemo(String(repeating: "가", count: 150))
        #expect(d.memo.count == PaymentNotReceivedState.memoLimit)
        #expect(PaymentNotReceivedDraft(memo: String(repeating: "a", count: 101)).memo.count == 100)
    }

    @Test func 빈_메모는_보내지_않는다() {
        var d = PaymentNotReceivedDraft(reasonId: "not_arrived")
        d.setMemo("   ")
        #expect(d.memoToSend == nil)
        d.setMemo(" 확인했어요 ")
        #expect(d.memoToSend == "확인했어요")
    }

    @Test func 보내기는_한_번만() {
        var lock = PaymentNotReceivedLock()
        let first = lock.begin(canSend: true)
        let second = lock.begin(canSend: true)
        #expect(first)
        #expect(!second)
        #expect(lock.isSending)
    }

    @Test func 실패하면_풀리고_성공이면_그대로() {
        var lock = PaymentNotReceivedLock()
        _ = lock.begin(canSend: true)
        lock.finish(success: false)
        #expect(!lock.isSending)
        _ = lock.begin(canSend: true)
        lock.finish(success: true)
        #expect(lock.isSending)
    }

    @Test func 사유가_없으면_잠그지_않는다() {
        var lock = PaymentNotReceivedLock()
        let ok = lock.begin(canSend: false)
        #expect(!ok)
        #expect(!lock.isSending)
    }

    @Test func 지급_완료가_아니면_시트가_열리지_않는다() {
        #expect(PaymentNotReceivedState.canOpenSheet(isPaidOut: true))
        #expect(!PaymentNotReceivedState.canOpenSheet(isPaidOut: false))
        var unpaid = s
        unpaid.isPaidOut = false
        #expect(!PaymentNotReceivedState.canOpenSheet(isPaidOut: unpaid.isPaidOut))
    }

    @Test func 보내는_중에는_닫히지_않는다() {
        #expect(!PaymentNotReceivedState.allowsSheetChange(to: false, isSending: true))
        #expect(PaymentNotReceivedState.allowsSheetChange(to: false, isSending: false))
        #expect(PaymentNotReceivedState.allowsSheetChange(to: true, isSending: true))
    }
}
