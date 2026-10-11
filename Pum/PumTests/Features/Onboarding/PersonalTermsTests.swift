// UI-IOS-2e — 개인 근로조건: 시작 조건 · 금액 숫자만 · 요일 · 표시 문구
import Foundation
import Testing
@testable import Pum

struct PersonalTermsTests {
    @Test func 원문_샘플() {
        let s = PersonalTermsState.sample
        #expect(s.timeRangeText == "17:00 \u{2013} 22:00")
        #expect(s.breakText == "30분")
        #expect(s.paydayText == "매월 10일")
        #expect(s.estimateText == "약 1,184,000원")
        #expect(s.amountText == "12,000")
        #expect(s.amountAccessibilityValue == "12,000원")
        #expect(s.days == [1, 3, 5])
        #expect(s.canStart)
    }

    @Test func 시작_조건() {
        var s = PersonalTermsState.entry
        #expect(!s.canStart)
        s.amount = 12_000
        #expect(!s.canStart)
        s.days = [2]
        #expect(s.canStart)
        s.amount = 0
        #expect(!s.canStart)
    }

    @Test func 금액은_숫자만_정수() {
        #expect(PersonalTermsState.sanitizedAmount("12,000원") == 12_000)
        #expect(PersonalTermsState.sanitizedAmount("") == 0)
        #expect(PersonalTermsState.sanitizedAmount("1.5") == 15)
        #expect(PersonalTermsState.sanitizedAmount("12345678901234") == 123_456_789)
    }

    @Test func 요일_여러개_토글() {
        var s = PersonalTermsState.entry
        s.toggleDay(1)
        s.toggleDay(7)
        let both = s.isSelected(1) && s.isSelected(7)
        #expect(both)
        s.toggleDay(1)
        let afterOff = s.isSelected(1)
        #expect(!afterOff)
        #expect(PersonalTermsState.weekdays.count == 7)
        #expect(PersonalTermsState.weekdays[6].short == "일")
    }

    @Test func 급여방식_이름과_예상값_없음() {
        #expect(PersonalTermsState.PayType.allCases.map(\.title) == ["시급", "일급", "월급"])
        #expect(PersonalTermsState.entry.estimateText == nil)
    }
}
