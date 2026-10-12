// UI-IOS-10e · REQ-074 — 발행 확인: 서버 값 그대로 · 한 번만 · 처리 중 닫기 막기
import Testing
import Foundation
@testable import Pum

struct PayslipIssueConfirmTests {
    let s = PayslipIssueConfirmState.sample

    @Test func 원문_값() {
        #expect(s.title == "명세서 3장 발행")
        #expect(s.subtitle == "10월분 \u{00B7} 지급 완료 처리할 때 직원에게 보내요")
        #expect(s.rows.map(\.name) == ["김하늘", "이종민", "최유나"])
        #expect(s.rows.map(\.amountText) == ["1,062,000원", "1,218,000원", "624,000원"])
        #expect(s.rows[0].accessibilityText == "김하늘, 1,062,000원")
        #expect(PayslipIssueConfirmState.editValue == "정정 명세서로")
        #expect(PayslipIssueConfirmState.recordValue == "활동 기록에 남음")
    }

    @Test func 장수는_서버_값_그대로() {
        var x = s
        x.issueCount = 2
        #expect(x.title == "명세서 2장 발행")
    }

    @Test func 처리_중에는_닫기_무시() {
        #expect(!PayslipIssueConfirmState.allowsSheetChange(to: false, isIssuing: true))
        #expect(PayslipIssueConfirmState.allowsSheetChange(to: false, isIssuing: false))
        #expect(PayslipIssueConfirmState.allowsSheetChange(to: true, isIssuing: true))
    }

    @Test func 발행은_한_번만_실패일_때만_풀림() {
        var lock = WorkClosingLock()
        let first = lock.begin(canClose: true)
        let second = lock.begin(canClose: true)
        #expect(first && !second)
        lock.finish(success: true)
        let stillLocked = lock.isClosing
        #expect(stillLocked)
        lock.finish(success: false)
        let unlocked = !lock.isClosing
        #expect(unlocked)
    }
}
