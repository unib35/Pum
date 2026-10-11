// UI-IOS-1n — 여러 사업장: 막대 비율 · 예상/확정 개수 · 합계 방어 · 문구 원문
import Testing
@testable import Pum

struct MultiWorkplaceTests {
    let r = MultiWorkplaceRecord.sample

    @Test func 막대_비율과_합() {
        #expect(r.barParts == [1_188_000, 642_300, 377_000])
        #expect(r.barTotal == 2_207_300)
        #expect(r.isConsistent)
        #expect(abs(r.barFraction(0) - 1_188_000.0 / 2_207_300) < 1e-9)
        #expect(abs((0..<3).map { r.barFraction($0) }.reduce(0, +) - 1) < 1e-9)
    }

    @Test func 예상_확정_개수() {
        #expect(r.expectedCount == 2 && r.confirmedCount == 1)
        #expect(r.countText == "예상 2곳 · 확정 1곳")
    }

    @Test func 음수_0_합계_방어() {
        var x = r
        x.entries = x.entries.map {
            MultiWorkplaceEntry(id: $0.id, name: $0.name, initial: $0.initial, colorIndex: $0.colorIndex,
                workMinutes: $0.workMinutes, hourlyWage: $0.hourlyWage, payDayText: $0.payDayText, amount: 0, status: $0.status)
        }
        #expect(x.barTotal == 0)
        #expect((0..<3).allSatisfy { x.barFraction($0) == 0 })
        var y = r
        y.entries = [.init(id: "a", name: "A", initial: "A", colorIndex: 0, workMinutes: 0, hourlyWage: 0,
                           payDayText: "1/1", amount: -500, status: .expected)]
        #expect(y.barParts == [0] && y.barFraction(0) == 0)
    }

    @Test func 문구_원문() {
        #expect(r.titleText == "10월 내가 번 돈 · 3곳")
        #expect(r.totalText == "2,207,300")
        #expect(r.totalWorkText == "총 근무 156시간 30분 · 32일")
        #expect(r.entries[0].detailText == "82시간 30분 · 12,000원/h · 급여일 11/10")
        #expect(r.entries[1].detailText == "49시간 · 11,500원/h · 급여일 11/5")
        #expect(r.entries[2].detailText == "25시간 · 15,000원/h · 급여일 11/25")
        #expect(r.entries.map(\.amountText) == ["1,188,000", "642,300", "377,000"])
        #expect(r.entries.map(\.status.text) == ["예상", "예상", "확정"])
    }

    @Test func 음성_안내() {
        #expect(r.entries[0].accessibilityText == "종민김밥 본점, 1,188,000원 예상, 82시간 30분 · 12,000원/h · 급여일 11/10")
        #expect(r.barAccessibilityText.hasPrefix("사업장별 금액, 종민김밥 본점 1,188,000원"))
    }
}
