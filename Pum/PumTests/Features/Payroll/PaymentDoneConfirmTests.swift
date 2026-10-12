// UI-IOS-7c · REQ-076 — 지급 완료 확인: 서버 값 그대로 · 한 번만 · 처리 중 닫기 막기
import Testing
import Foundation
@testable import Pum

struct PaymentDoneConfirmTests {
    let s = PaymentDoneConfirmState.sample

    @Test func 원문_값() {
        #expect(s.title == "지급 완료로 처리할까요?")
        #expect(s.recipientName == "김하늘")
        #expect(s.maskedAccountText == "국민 ••••1234")
        #expect(s.amountText == "1,062,000원")
        #expect(s.noticeSpoken == "은행 앱에서 실제 송금이 끝났는지 확인해주세요.")
        #expect(s.cancelTitle == "취소" && s.confirmTitle == "지급 완료")
    }

    @Test func 금액은_정수_원() {
        var x = s
        x.amount = 880_000
        #expect(x.amountText == "880,000원")
    }

    @Test func 계좌_읽기는_점_없이_끝자리() {
        #expect(s.accountSpoken == "국민 끝자리 1234")
        #expect(!s.accountSpoken.contains("\u{2022}"))
    }

    @Test func 한_번만_누르면_잠기고_두_번째는_거절() {
        var lock = WorkClosingLock()
        let first = lock.begin(canClose: true)
        let second = lock.begin(canClose: true)
        #expect(first)
        #expect(!second)
        #expect(lock.isClosing)
    }

    @Test func 실패일_때만_풀린다() {
        var lock = WorkClosingLock()
        _ = lock.begin(canClose: true)
        lock.finish(success: true)
        #expect(lock.isClosing)
        lock.finish(success: false)
        #expect(!lock.isClosing)
        let again = lock.begin(canClose: true)
        #expect(again)
    }

    @Test func 처리_중에는_닫기_무시() {
        #expect(PaymentDoneConfirmState.allowsDismiss(isProcessing: false))
        #expect(!PaymentDoneConfirmState.allowsDismiss(isProcessing: true))
        #expect(s.processingTitle == "처리하는 중")
    }
}
