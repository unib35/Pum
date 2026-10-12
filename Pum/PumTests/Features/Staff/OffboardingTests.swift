// UI-IOS-10n · REQ-080 — 퇴사 정산: 서버 값 표시 · 읽기 문구
import Testing
import Foundation
@testable import Pum

struct OffboardingTests {
    let s = OffboardingState.sample

    @Test func 원문_문구() {
        #expect(s.name == "박서준")
        #expect(s.periodText == "2025.8.18 입사 \u{00B7} 10월 31일 퇴사")
        #expect(s.statusText == "퇴사 예정")
        #expect(s.deadlineText == "지급 기한 11월 14일")
        #expect(s.deadlineNote == "퇴사 후 14일 안")
        #expect(s.payItems.map(\.amountText) == ["880,000원", "약 1,790,000원", "88,000원"])
        #expect(s.payItems[1].detail == "1년 2개월 \u{00B7} 주 18시간 \u{00B7} 지급 대상")
        #expect(s.nextStepTitle == "10월 근무 마감하기")
    }

    @Test func 단계_완료는_서버_값() {
        #expect(s.steps.map(\.isDone) == [true, false, false, false, false])
        #expect(s.steps.count == 5)
        #expect(s.steps[1].detail == nil)
    }

    @Test func 읽기_문구() {
        #expect(s.deadlineSpoken == "지급 기한 11월 14일, 퇴사 후 14일 안")
        #expect(s.stepSpoken(s.steps[0]) == "퇴사일 확정, 10월 31일 \u{00B7} 사직서 받음, 완료, 5단계 중 1번째")
        #expect(s.stepSpoken(s.steps[1]) == "10월 근무 마감, 아직, 5단계 중 2번째")
        #expect(s.payItems[2].spoken == "미사용 연차 수당, 남은 8시간 \u{00D7} 11,000, 88,000원")
    }

    @Test func 값_종류_10n은_금액() {
        #expect(s.payItems.allSatisfy { if case .won = $0.value { true } else { false } })
        #expect(s.addAgreedPay == nil)
    }

    @Test func 대상_아님_10r_원문() {
        let n = OffboardingState.notEligible
        #expect(n.name == "최유나")
        #expect(n.periodText == "2026.3.2 \u{2013} 10.31 \u{00B7} 주 12시간")
        #expect(n.deadlineText == "지급 기한 11월 14일")
        #expect(n.payItems.map(\.value) == [.won("624,000원"), .badge("대상 아님"), .badge("대상 아님")])
        #expect(n.payItems[1].detail == "근속 8개월 \u{00B7} 1년 미만")
        #expect(n.payItems[2].detail == "주 12시간 \u{00B7} 15시간 미만")
        #expect(n.addAgreedPay == OffboardingAddRow(title: "약정 지급 추가", detail: "대상이 아니어도 매장이 주는 금액"))
        #expect(n.steps.map(\.title) == ["퇴사일 확정", "10월 근무 마감", "최종 급여 확정 \u{00B7} 지급 \u{00B7} 명세서", "고용보험 상실 신고"])
        #expect(n.steps[3].detail == "3개월 이상 근무 \u{00B7} 직접 신고")
        #expect(n.steps.map(\.isDone) == [true, false, false, false])
        #expect(n.payItems[1].spoken == "퇴직금, 대상 아님, 근속 8개월 \u{00B7} 1년 미만")
        #expect(n.addAgreedPay?.spoken == "약정 지급 추가, 대상이 아니어도 매장이 주는 금액")
        #expect(n.stepSpoken(n.steps[3]) == "고용보험 상실 신고, 3개월 이상 근무 \u{00B7} 직접 신고, 아직, 4단계 중 4번째")
    }

    @Test func 퇴직연금_DC_10s_원문() {
        let d = OffboardingState.dcPension
        #expect(d.name == "이종민")
        #expect(d.statusText == "퇴직연금 DC")
        #expect(d.periodText == "2024.3.4 \u{2013} 10.31 \u{00B7} 주 20시간")
        #expect(d.deadlineText == "지급 \u{00B7} 적립 기한 11월 14일")
        #expect(d.payItems.map(\.value) == [.won("1,218,000원"), .won("432,000원"), .note("DC 계좌")])
        #expect(d.payItems[1].detail == "남은 36시간 \u{00D7} 12,000")
        #expect(d.addAgreedPay == nil)
        #expect(d.steps.count == 5)
        #expect(d.steps[3].title == "퇴직연금 미납 부담금 적립")
        #expect(d.steps[3].detail == "\u{25CB}\u{25CB}은행 퇴직연금 \u{00B7} 11월 14일까지")
        #expect(d.steps[4].detail == "직접 신고 \u{00B7} 11월 15일까지")
        #expect(d.payItems[2].spoken == "퇴직급여, DC 계좌, 연금사업자가 지급 \u{00B7} 앱에서 계산 안 함")
    }
}
