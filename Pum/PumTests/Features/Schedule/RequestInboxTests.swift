// UI-IOS-10k · REQ-042 — 휴무·변경 요청 처리: 원문 값 · 카드별 잠금 · 음성 안내문
import Testing
@testable import Pum

struct RequestInboxTests {
    @Test func 캡처_상태는_원문_값() {
        let s = RequestInboxState.sample
        #expect(s.title == "요청 2건")
        #expect(s.items.map(\.name) == ["김하늘", "박서준"])
        let leave = s.items[0]
        #expect(leave.kindText == "휴무" && leave.relativeTime == "10분 전")
        #expect(leave.titleText == "10월 23일 금 · 17:00 – 22:00")
        #expect(leave.impacts[0].value == "3명 → 2명" && leave.impacts[0].shortageText == "필요 3명")
        #expect(leave.impacts[1].shortageText == nil)
        #expect(leave.approveText == "박서준 대타로 승인")
        let change = s.items[1]
        #expect(change.impacts[1].value == "+5,500원 · 야간 가산 1시간")
        #expect(change.approveText == "승인")
    }

    @Test func 음성_안내문은_대상을_포함한다() {
        let leave = RequestInboxState.sample.items[0]
        #expect(leave.accessibilityHeader == "김하늘, 휴무 요청, 10분 전")
        #expect(leave.rejectAccessibility == "김하늘 요청 거절")
        #expect(leave.accessibilityImpacts.contains("금 17–22 근무자, 3명 → 2명, 필요 3명"))
    }

    @Test func 누른_카드만_잠기고_실패하면_풀린다() {
        var lock = RequestRowLock()
        let first = lock.begin("a")
        let again = lock.begin("a")
        #expect(first && !again)
        #expect(!lock.isLocked("b"))
        lock.finish("a", success: false)
        #expect(!lock.isLocked("a"))
    }

    @Test func 성공해도_새_상태가_올_때까지_잠겨_있고_reset하면_풀린다() {
        var lock = RequestRowLock()
        _ = lock.begin("a")
        lock.finish("a", success: true)
        #expect(lock.isLocked("a"))
        lock.reset()
        #expect(!lock.isLocked("a"))
    }
}
