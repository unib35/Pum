// UI-IOS-1y — 개수 문구 · 선택/확인 표시 규칙 · 원문 문구 · 선택 바꾸기
import Foundation
import Testing
@testable import Pum

struct WorkplaceSwitcherTests {
    @Test func 개수_문구는_사업장_수를_따른다() {
        var s = WorkplaceSwitcherState.sample
        #expect(s.countText == "3곳에서 일하고 있어요")
        s.workplaces.removeLast()
        #expect(s.countText == "2곳에서 일하고 있어요")
    }

    @Test func 선택은_체크_확인은_배지_나머지는_없음() {
        let s = WorkplaceSwitcherState.sample
        #expect(s.mark(for: s.workplaces[0]) == .selected)
        #expect(s.mark(for: s.workplaces[1]) == .pending(1))
        #expect(s.mark(for: s.workplaces[2]) == .none)
    }

    @Test func 선택된_사업장에_확인이_있으면_체크가_우선이다() {
        var s = WorkplaceSwitcherState.sample
        s.select("w2")
        #expect(s.mark(for: s.workplaces[1]) == .selected)
        #expect(s.mark(for: s.workplaces[0]) == .none)
    }

    @Test func 문구는_원문_그대로_en_dash() {
        let s = WorkplaceSwitcherState.sample
        #expect(s.workplaces[0].detailText == "오늘 17:00 \u{2013} 22:00 · 시급 12,000원")
        #expect(s.workplaces[1].detailText == "내일 09:00 \u{2013} 14:00 · 시급 11,500원")
        #expect(s.workplaces[2].detailText == "다음 근무 10/6 화 19:00 · 시급 15,000원")
        #expect(s.summaryText == "10월 합산 2,207,300원 · 32일")
        #expect(s.workplaces[1].pendingBadgeText == "확인 1")
    }

    @Test func 선택을_바꾸고_없는_id는_무시한다() {
        var s = WorkplaceSwitcherState.sample
        s.select("w3")
        #expect(s.selected?.name == "C학원")
        s.select("zzz")
        #expect(s.selectedID == "w3")
    }

    @Test func 읽어주기_문구() {
        var s = WorkplaceSwitcherState.sample
        #expect(s.accessibilityText(for: s.workplaces[0]) == "종민김밥 본점, 오늘 17:00부터 22:00, 시급 12,000원") // 「선택됨」은 특성이 읽음
        #expect(s.accessibilityText(for: s.workplaces[1]) == "B카페 서면점, 내일 09:00부터 14:00, 시급 11,500원, 확인할 것 1건")
        s.select("w2")
        #expect(s.accessibilityText(for: s.workplaces[1]).hasSuffix("시급 11,500원, 확인할 것 1건"))
    }

    @Test func 같은_사업장을_다시_고르면_바뀌지_않음() {
        var s = WorkplaceSwitcherState.sample
        let same = s.select(s.selectedID)
        let other = s.select("w2")
        let missing = s.select("없는-id")
        #expect(!same && other && !missing)
    }

    @Test func 사업장_색_번호_방어() {
        var s = WorkplaceSwitcherState.sample
        let n = PumAvatarPalette.stores.count
        s.workplaces[0] = SwitcherWorkplace(id: s.workplaces[0].id, name: s.workplaces[0].name, initial: s.workplaces[0].initial,
            colorIndex: -1, scheduleText: s.workplaces[0].scheduleText, scheduleSpoken: s.workplaces[0].scheduleSpoken,
            hourlyWage: s.workplaces[0].hourlyWage, pendingCount: 0)
        #expect(s.workplaces[0].tileColor == PumAvatarPalette.stores[n - 1])
    }
}
