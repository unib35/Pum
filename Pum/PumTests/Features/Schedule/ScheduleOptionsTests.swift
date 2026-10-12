// UI-IOS-9b · REQ-051 — 추천 3안 문구 · 서버 값 그대로
import Testing
import Foundation
@testable import Pum

struct ScheduleOptionsTests {
    let s = ScheduleOptionsState.sample

    @Test func 원문_문구() {
        #expect(s.title == "추천 스케줄")
        #expect(s.currentTitle == "현재 스케줄 \u{00B7} 10/12 \u{2013} 18 주간")
        #expect(s.currentText == "1,284,000")
        #expect(s.shortageText == "토 18\u{2013}22 1명 부족")
        #expect(s.notice == "금액은 실제 적용되는 수당과 사업주 부담을 모두 포함한 예상 총비용이에요.")
        #expect(s.options.map(\.name) == ["인건비 절감", "균형", "기존 일정 유지"])
        #expect(s.options.map(\.totalText) == ["1,241,000", "1,278,000", "1,324,000"])
        #expect(s.options.map(\.deltaText) == ["\u{2212}43,000", "\u{2212}6,000", "+40,000"])
        #expect(s.options.map(\.changeText) == ["변경 4건 \u{00B7} 근무자 5명", "변경 2건 \u{00B7} 기존 일정 변경 최소화", "변경 1건 \u{00B7} 부족한 시간대만 추가"])
        #expect(s.option(id: s.selectedID)?.detailTitle == "절감안 변경 내용 보기")
    }

    @Test func 음성_읽기() {
        #expect(s.options[0].accessibilityText == "인건비 절감, 1,241,000원, 현재보다 43,000원 적음, 변경 4건, 근무자 5명, 필요 인력 \u{00B7} 가능 시간 \u{00B7} 근로조건 충족")
        #expect(s.options[2].accessibilityText.contains("현재보다 40,000원 많음"))
        #expect(s.currentAccessibilityText == "현재 스케줄 10/12 \u{2013} 18 주간, 1,284,000원, 토 18\u{2013}22 1명 부족")
    }

    @Test func 방향은_서버_값으로만() {
        var o = s.options[0]
        o.direction = .increase; o.deltaAmount = 777
        #expect(o.deltaText == "+777") // 총비용과 현재를 비교하지 않는다
        #expect(o.accessibilityText.contains("현재보다 777원 많음"))
        o.direction = .same
        #expect(o.accessibilityText.contains("현재와 같음"))
    }

    @Test func 미충족_항목은_체크_없이_음성에_알린다() {
        var o = s.options[1]
        o.availabilityMet = false
        #expect(o.checks.map(\.met) == [true, false, true])
        #expect(o.accessibilityText.hasSuffix("필요 인력 \u{00B7} 근로조건 충족, 가능 시간 미충족"))
    }

    @Test func 부족_표시가_없으면_알약이_없다() {
        var t = s
        t.shortageText = nil
        #expect(t.currentAccessibilityText == "현재 스케줄 10/12 \u{2013} 18 주간, 1,284,000원")
    }

    @Test func 없는_안은_찾지_않는다() {
        #expect(ScheduleOptionsState.sample.option(id: "") == nil)
        #expect(ScheduleOptionsState.sample.option(id: ScheduleOptionsState.sample.selectedID) != nil)
    }
}
