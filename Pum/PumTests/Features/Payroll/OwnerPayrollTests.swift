// UI-IOS-1u — 단계 상태 · 경고 · 확정 버튼 · 행 문구 · 전월 대비 부호
import Testing
@testable import Pum

struct OwnerPayrollTests {
    let r = OwnerPayrollRecord.sample

    @Test func 단계_상태() {
        let s = OwnerPayrollStage.allCases.map { $0.phase(current: r.stage) }
        #expect(s == [.done, .current, .waiting, .waiting, .waiting])
        #expect(r.stageAccessibilityText == "급여 진행, 5단계 중 2단계, 확인 필요")
    }

    @Test func 경고_문구() {
        #expect(r.showsWarning)
        #expect(r.warningTitle == "미처리 근무기록 2건")
        #expect(r.warningAccessibilityText == "미처리 근무기록 2건, 급여를 확정하려면 먼저 처리해야 해요, 처리")
        #expect(!OwnerPayrollRecord.sampleClear.showsWarning)
    }

    @Test func 확정_버튼() {
        #expect(!r.canConfirm)
        #expect(r.confirmTitle == "급여 확정하기 \u{00B7} 미처리 2건 남음")
        let c = OwnerPayrollRecord.sampleClear
        #expect(c.canConfirm && c.confirmTitle == "급여 확정하기")
    }

    @Test func 행_문구() {
        let e = r.employees
        #expect(e[0].statusText == "기록 모두 확정" && !e[0].hasPending)
        #expect(e[1].statusText == "미처리 1건" && e[1].hasPending)
        #expect(e[0].detailText == "82시간 30분 \u{00B7} 17일 \u{00B7} 시급")
        #expect(e[1].detailText == "74시간 \u{00B7} 16일 \u{00B7} 시급")
        #expect(e[3].detailText == "78시간 30분 \u{00B7} 15일 \u{00B7} 시급")
        #expect(e[0].accessibilityText == "이종민, 82시간 30분, 17일, 1,188,000원, 기록 모두 확정")
        #expect(e[0].amountText == "1,188,000")
    }

    @Test func 요약_문구() {
        #expect(r.summaryTitle == "10월 총 지급 예정")
        #expect(r.totalText == "4,210,000" && r.headcountText == "직원 4명" && r.totalWorkText == "총 근무 331시간")
        #expect(r.payDayLabel == "지급일 11월 10일")
    }

    @Test func 전월_대비_부호() {
        var x = r
        #expect(x.deltaText == "+230,000")
        x.deltaAmount = -230_000
        #expect(x.deltaText == "\u{2212}230,000")
        x.deltaAmount = 0
        #expect(x.deltaText == "0")
    }
}
