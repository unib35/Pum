// UI-IOS-1m — 급여명세서 금액 일관성(REQ-074 · REQ-071) · 표기(F4) · 지급 완료 문구(REQ-078)
import Testing
@testable import Pum

struct PayslipTests {
    let r = PayslipRecord.sample

    @Test func 지급_합계는_항목_합() {
        #expect(r.grossTotal == 1_218_000)
        #expect(r.grossTotal == 990_000 + 198_000 + 30_000)
        #expect(r.earnings.reduce(0) { $0 + $1.amount } == r.grossTotal)
    }

    @Test func 공제_합계와_실지급액() {
        #expect(r.deductionTotal == 30_000)
        #expect(r.deductions.reduce(0) { $0 + $1.amount } == 30_000)
        #expect(r.netPay == 1_188_000)
        #expect(r.netPay == r.grossTotal - r.deductionTotal)
        #expect(r.isConsistent)
        #expect(r.netPayText == "1,188,000원")
    }

    @Test func 공제는_U2212_마이너스() {
        #expect(r.deductionTotalText == "\u{2212}30,000")
        #expect(r.amountText(r.deductions[0], deduction: true) == "\u{2212}11,000")
        #expect(!r.deductionTotalText.contains("-"))
    }

    @Test func 합계가_어긋나도_표시는_서버_값() {
        var x = r
        x.grossTotal = 1_000_000
        #expect(!x.isConsistent)
        #expect(x.grossText == "1,000,000")
    }

    @Test func 기본급_근거_문구와_원문_표기() {
        #expect(r.earnings[0].note == "82.5h × 12,000")
        #expect(r.workSummary == "17일 · 82h 30m")
        #expect(r.headerCaption == "급여명세서 · 2026년 10월분")
    }

    @Test func 지급_완료_문구만_쓴다() {
        #expect(r.statusText == "지급 완료")
        #expect(!r.statusText.contains("입금"))
    }

    @Test func VoiceOver_문구() {
        #expect(r.accessibilityText(r.earnings[1], deduction: false) == "주휴수당 198,000원")
        #expect(r.accessibilityText(r.deductions[0], deduction: true) == "고용보험 공제 11,000원")
    }
}
