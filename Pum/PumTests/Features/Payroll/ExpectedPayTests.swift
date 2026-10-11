// UI-IOS-1l — 예상 급여: 구성 비율 · 확정 + 예정 = 예상 · 공제 표기(F4) · 펼침 토글 · 계산 근거 그대로
import Testing
@testable import Pum

struct ExpectedPayTests {
    let r = ExpectedPayRecord.sample

    @Test func 구성_비율과_합() {
        #expect(r.barParts == [990_000, 198_000, 30_000])
        #expect(r.barTotal == 1_218_000)
        #expect(abs(r.barFraction(0) - 990_000.0 / 1_218_000) < 1e-9)
        #expect(abs((0..<3).map { r.barFraction($0) }.reduce(0, +) - 1) < 1e-9)
    }

    @Test func 확정_더하기_남은_예정은_예상_급여() {
        #expect(r.confirmedAmount + r.remainingAmount == r.expectedTotal)
        #expect(r.confirmedAmount == 121_200 && r.remainingAmount == 1_066_800 && r.expectedTotal == 1_188_000)
        #expect(r.isConsistent)
        #expect(r.totalText == "1,188,000")
        #expect(r.confirmedText == "121,200원")
    }

    @Test func 합이_어긋나도_표시는_서버_값() {
        var x = r
        x.remainingAmount = 1
        #expect(!x.isConsistent)
        #expect(x.remainingText == "1원")
    }

    @Test func 공제는_U2212() {
        #expect(r.deductionText == "\u{2212}30,000")
        #expect(r.items[3].amountText == "\u{2212}30,000원")
        #expect(!r.items[3].amountText.contains("-"))
        #expect(r.items[1].amountText == "198,000원")
    }

    @Test func 펼침_토글() {
        var d = ExpectedPayDisclosure()
        #expect(d.isExpanded && d.stateText == "펼쳐짐")
        d.toggle()
        #expect(!d.isExpanded && d.stateText == "접힘")
        d.toggle()
        #expect(d.isExpanded)
    }

    @Test func 계산_근거는_받은_그대로() {
        let lines = r.items[1].calcLines
        #expect(r.items[1].isExpandable && !r.items[0].isExpandable)
        #expect(lines.map(\.label) == ["1주 소정근로 15시간 이상", "주휴시간 = 15h ÷ 40h × 8h", "3시간 × 12,000원", "× 10월 5.5주"])
        #expect(lines.map(\.value) == ["충족", "3시간", "36,000원 / 주", "198,000원"])
        #expect(lines[0].tone == .positive && lines[3].tone == .strong && lines[3].separatorAbove)
    }

    @Test func VoiceOver_구성_막대_한_문장() {
        #expect(r.barAccessibilityText == "급여 구성, 기본급 990,000원, 주휴 198,000원, 기타 30,000원, 공제 30,000원")
    }

    @Test func 구성_합_빼기_공제는_예상_급여() {
        let r = ExpectedPayRecord.sample
        #expect(r.basePay + r.holidayPay + r.otherPay - r.deductionTotal == r.expectedTotal)
    }

    @Test func 음수_구성은_막대에서_0() {
        var r = ExpectedPayRecord.sample
        r.otherPay = -10
        #expect(r.barFraction(2) == 0)
        #expect(r.barFraction(0) + r.barFraction(1) == 1)
    }
}
