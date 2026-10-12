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
}
