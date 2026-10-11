// UI-IOS-1w — 전체 사업장: 요약 문구 · 카드 문구 · 배지 · 막대 비율 · 색 번호 방어
import Testing
@testable import Pum

struct OwnerWorkplacesTests {
    let r = OwnerWorkplacesRecord.sample

    private func entry(expected: Int = 0, confirmed: Int = 0, colorIndex: Int = 0) -> OwnerWorkplaceEntry {
        OwnerWorkplaceEntry(id: "x", name: "X", initial: "X", colorIndex: colorIndex, staffCount: 0, workingCount: 0,
            expectedAmount: expected, confirmedAmount: confirmed, attentionCount: 0, editRequestCount: 0,
            substituteCount: 0, invitingCount: 0)
    }

    @Test func 요약_문구() {
        #expect(r.titleText == "10월 전체 예상 인건비")
        #expect(r.totalText == "7,330,000")
        #expect(r.countText == "2곳 · 직원 7명")
        #expect(r.workingText == "4명" && r.attentionText == "6건" && r.dDayText == "D-7")
        #expect(r.summaryAccessibilityText == "10월 전체 예상 인건비 7,330,000원, 확정 4,085,000원, 남은 예정 3,245,000원, 2곳, 직원 7명, 지금 근무 중 4명, 확인 필요 6건, 급여 정산 D-7")
    }

    @Test func D_day_오늘() {
        var x = r
        x.payrollDaysLeft = 0
        #expect(x.dDayText == "D-day")
    }

    @Test func 사업장_카드_문구와_배지() {
        let a = r.entries[0], b = r.entries[1]
        #expect(a.staffText == "직원 4명 · 근무 중 2명" && a.amountText == "4,210,000")
        #expect(a.badges.map(\.text) == ["확인 필요 4", "수정 요청 1", "대타 1"])
        #expect(a.badges.map(\.isAttention) == [true, false, false])
        #expect(b.badges.map(\.text) == ["확인 필요 2", "초대 중 1"])
        #expect(a.accessibilityText == "종민김밥 본점, 직원 4명, 근무 중 2명, 예상 인건비 4,210,000원, 확정 2,525,000원, 확인 필요 4건, 수정 요청 1건, 대타 1건")
    }

    @Test func 건수_0이면_배지_없음() {
        #expect(entry().badges.isEmpty)
    }

    @Test func 요약_막대_비율() {
        #expect(r.barParts == [4_085_000, 3_245_000])
        #expect(abs(r.barFraction(0) + r.barFraction(1) - 1) < 1e-9)
        var z = r
        z.confirmedAmount = 0
        z.scheduledAmount = 0
        #expect(z.barFraction(0) == 0 && z.barFraction(1) == 0)
        z.confirmedAmount = -100
        z.scheduledAmount = 500
        #expect(z.barParts == [0, 500] && z.barFraction(0) == 0 && z.barFraction(1) == 1)
    }

    @Test func 카드_막대_비율_방어() {
        #expect(abs(r.entries[1].confirmedFraction - 0.5) < 1e-9)
        #expect(entry(expected: 0, confirmed: 100).confirmedFraction == 0)
        #expect(entry(expected: -5, confirmed: 3).confirmedFraction == 0)
        #expect(entry(expected: 100, confirmed: -1).confirmedFraction == 0)
        #expect(entry(expected: 100, confirmed: 250).confirmedFraction == 1)
    }

    @Test func 사업장_색_번호_방어() {
        let n = OwnerWorkplaceTileColor.colors.count
        #expect(OwnerWorkplaceTileColor.color(at: -1) == OwnerWorkplaceTileColor.color(at: n - 1))
        #expect(OwnerWorkplaceTileColor.color(at: n) == OwnerWorkplaceTileColor.color(at: 0))
        #expect(OwnerWorkplaceTileColor.color(at: 99) == OwnerWorkplaceTileColor.color(at: 99 % n))
        #expect(entry(colorIndex: -7).tileColor == OwnerWorkplaceTileColor.color(at: -7))
    }
}
