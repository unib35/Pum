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
        let first = lock.begin("a", .reject)
        let again = lock.begin("a", .approve)
        #expect(first && !again)
        #expect(lock.decision("a") == .reject) // 처리 중 표시는 누른 거절 버튼에
        #expect(!lock.isLocked("b"))
        lock.finish("a", success: false)
        #expect(!lock.isLocked("a"))
    }

    @Test func 새_목록에서_바뀐_카드만_잠금이_풀린다() {
        let items = RequestInboxState.sample.items
        var lock = RequestRowLock()
        _ = lock.begin(items[0].id, .approve)
        _ = lock.begin(items[1].id, .approve)
        lock.finish(items[0].id, success: true)
        // 첫 카드는 처리돼 사라지고, 두 번째 카드는 아직 처리 중 — 그대로 잠겨 있어야 한다
        lock.refresh(old: items, new: [items[1]])
        #expect(!lock.isLocked(items[0].id))
        #expect(lock.isLocked(items[1].id))
    }
}
