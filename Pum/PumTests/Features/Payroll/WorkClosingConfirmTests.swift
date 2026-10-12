// UI-IOS-8c · REQ-028 · REQ-070 — 근무 마감 확인 문구 · 한 번만 잠금
import Testing
import Foundation
@testable import Pum

struct WorkClosingConfirmTests {
    let s = WorkClosingConfirmState.sample

    @Test func 원문_문구() {
        #expect(s.sheetTitle == "10월 근무를 마감할까요?")
        #expect(s.employeeText == "5명" && s.recordText == "76건")
        #expect(s.totalWorkText == "382시간 20분")
        #expect(s.laborCostText == "4,210,000원")
        #expect(s.checkedTitle == "모든 기록을 확인했어요")
        #expect(s.checkedSubtitle == "76건 \u{00B7} 처리 필요 0건")
        #expect(s.lockNoticeSpoken == "마감 후 10월 기록은 잠기고, 바꾸려면 정정 절차를 거쳐요")
        #expect(s.calcNotice == "바로 10월 급여 계산이 시작되고 직원에게 알림이 가요")
        #expect(s.confirmTitle == "10월 근무 마감 \u{00B7} 급여 계산 시작")
    }

    @Test func 금액은_서버_정수_그대로() {
        var t = s
        t.expectedLaborCost = 0
        #expect(t.laborCostText == "0원")
        t.expectedLaborCost = 12_345_678
        #expect(t.laborCostText == "12,345,678원")
    }

    @Test func 마감은_한_번만() {
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

    @Test func 처리_필요가_남으면_마감_안_함() {
        var s = WorkClosingConfirmState.sample
        #expect(s.canClose)
        s.problemCount = 3
        #expect(!s.canClose)
    }

    @Test func 마감_중에는_시트가_닫히지_않는다() {
        #expect(!WorkClosingConfirmState.allowsSheetChange(to: false, isClosing: true))
        #expect(WorkClosingConfirmState.allowsSheetChange(to: false, isClosing: false))
        #expect(WorkClosingConfirmState.allowsSheetChange(to: true, isClosing: true))
    }
}
