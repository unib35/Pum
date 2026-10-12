// UI-IOS-8d · REQ-052 — 인건비 시뮬레이터: 계산 조건 일치 · 요일 토글 · 결과 숨김 · 원문 문구
import Testing
import Foundation
@testable import Pum

struct LaborSimulatorTests {
    let s = LaborSimulatorState.sample

    @Test func 원문_문구() {
        #expect(LaborSimulatorState.title == "인건비 계산")
        #expect(LaborSimulatorMode.allCases.map(\.title) == ["직원 추가", "시간 변경", "시급 변경"])
        #expect(s.wageText == "12,000원")
        #expect(s.timeText == "17:00 \u{2013} 22:00")
        #expect(s.breakText == "30분")
        #expect(s.inputs.periodText == "10/10 \u{2013} 10/31")
        #expect(s.totalText == "약 504,000원")
        #expect(s.visibleResult?.lines.map(\.title) == [
            "기본급 \u{00B7} 9일 \u{00D7} 4.5h \u{00D7} 12,000",
            "주휴수당 \u{00B7} 계약 소정근로 4주 평균 기준",
            "사업주 부담 4대보험 \u{00B7} 약",
        ])
        #expect(s.visibleResult?.lines.map { LaborSimulatorState.amountText($0.amountWon) } == ["486,000원", "0원", "18,000원"])
        #expect(s.resultSpoken == "예상 추가 인건비 약 504,000원")
        #expect(LaborSimulatorState.detailTitle == "결과 자세히 보기")
        #expect(s.mode == .addEmployee)
        #expect(s.inputs.weekdays == [1, 3, 5])
    }

    @Test func 원문_상태는_입력이_계산_조건과_같다() {
        #expect(s.resultIsCurrent)
        #expect(s.canShowDetail)
    }

    @Test func 요일_토글() {
        var t = s
        t.toggleWeekday(2)
        #expect(t.isWeekdaySelected(2))
        t.toggleWeekday(1)
        #expect(!t.isWeekdaySelected(1))
        #expect(t.inputs.weekdays == [2, 3, 5])
    }

    @Test func 입력이_바뀌면_결과를_숨기고_자세히_보기를_막는다() {
        var t = s
        t.toggleWeekday(2)
        #expect(!t.resultIsCurrent)
        #expect(t.visibleResult == nil)
        #expect(t.totalText == nil)
        #expect(!t.canShowDetail)
        #expect(t.resultSpoken == "예상 추가 인건비")
    }

    @Test func 원래대로_돌리면_결과가_다시_보인다() {
        var t = s
        t.toggleWeekday(2)
        t.toggleWeekday(2)
        #expect(t.resultIsCurrent)
        #expect(t.totalText == "약 504,000원")
    }

    @Test func 시급_시간_휴게_기간이_다르면_숨김() {
        var a = s; a.inputs.hourlyWon = 13_000
        var b = s; b.inputs.endMinutes = 23 * 60
        var c = s; c.inputs.breakMinutes = 60
        var d = s; d.inputs.periodText = "10/10 \u{2013} 11/30"
        for t in [a, b, c, d] { #expect(!t.resultIsCurrent) }
    }

    @Test func 결과가_없으면_숨김() {
        var t = s
        t.result = nil
        #expect(!t.resultIsCurrent && !t.canShowDetail)
    }

    @Test func 부모가_새_결과를_주면_다시_보임() {
        var t = s
        t.inputs.hourlyWon = 13_000
        t.result = LaborSimulatorResult(basis: t.inputs, expectedWon: 546_000, lines: [])
        #expect(t.resultIsCurrent)
        #expect(t.totalText == "약 546,000원")
    }

    @Test func 시트_완료는_시간과_휴게만_가져온다() {
        var t = s
        var v = t.pickerValue
        v.startMinutes = 9 * 60
        v.endMinutes = 13 * 60 + 30
        v.breakMinutes = 0
        v.weekdays = [7]
        t.apply(picked: v)
        #expect(t.timeText == "09:00 \u{2013} 13:30")
        #expect(t.breakText == "없음")
        #expect(t.inputs.weekdays == [1, 3, 5])
        #expect(t.inputs.hourlyWon == 12_000)
    }
}
