// UI-IOS-7a · REQ-076 — 지급 체크리스트: 원문 값 · 서버 값 문구 · 마스킹 계좌 · VoiceOver 문구 · 비율
import Testing
@testable import Pum

struct PaymentChecklistTests {
    let s = PaymentChecklistState.sample

    @Test func 요약_원문_값() {
        #expect(s.title == "10월 급여 지급")
        #expect(s.payDateText == "지급일 11월 10일 (화) · 오늘")
        #expect(s.statusBadgeText == "지급 중")
        #expect(s.totalText == "4,210,000원")
        #expect(s.employeeCountText == "직원 4명")
        #expect(s.paidSummaryText == "지급 완료 2 / 4 · 2,268,000원")
        #expect(s.remainingSummaryText == "남은 2명 · 1,942,000원")
        #expect(s.pendingHeaderText == "지급 대기 2")
        #expect(s.paidHeaderText == "지급 완료 2")
    }

    @Test func 막대_비율은_완료수_나누기_전체() {
        #expect(s.progress == 0.5)
        var z = s; z.employeeCount = 0
        #expect(z.progress == 0)
    }

    @Test func 행_문구() {
        #expect(s.pending.map(\.amountText) == ["1,062,000원", "880,000원"])
        #expect(s.pending.map(\.accountText) == ["국민은행 ••••-••-••1234", "신한은행 ••••-•••-••5521"])
        #expect(s.paid.map(\.processedText) == ["10:31 처리", "10:24 처리"])
        #expect(s.pending.allSatisfy { !$0.isPaid } && s.paid.allSatisfy(\.isPaid))
    }

    @Test func 음성_안내는_마스킹_점을_읽지_않는다() {
        #expect(s.pending[0].accessibilityText == "김하늘, 국민은행 끝자리 1234, 1,062,000원, 지급 대기")
        #expect(s.paid[0].accessibilityText == "이종민, 카카오뱅크 끝자리 4821, 1,188,000원, 지급 완료, 10:31 처리")
        #expect(!s.pending[0].accessibilityText.contains("•"))
        #expect(!s.summaryAccessibilityText.contains("•"))
    }

    @Test func 끝자리_숫자() {
        #expect(s.pending[1].accountLastDigits == "5521")
    }

    @Test func 막대_비율은_0과_1_사이() {
        var over = s; over.paidCount = 5
        #expect(over.progress == 1)
        var none = s; none.paidCount = 0
        #expect(none.progress == 0)
    }

    @Test func 숫자_없는_마스킹은_은행만_읽는다() {
        var p = s.pending[0]; p.maskedAccount = "••••"
        #expect(p.accountLastDigits.isEmpty)
        #expect(p.accessibilityText == "김하늘, 국민은행, 1,062,000원, 지급 대기")
    }

    @Test func 전원_완료면_대기_머리는_0() {
        var all = s; all.paid += all.pending; all.pending = []
        #expect(all.pendingHeaderText == "지급 대기 0")
        #expect(all.paidHeaderText == "지급 완료 4")
    }
}
