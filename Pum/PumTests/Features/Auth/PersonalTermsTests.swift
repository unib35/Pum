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
        #expect(PersonalTermsState.sanitizedAmount("1.5") == 1)
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

    @Test func 조건이_바뀌면_옛_예상은_숨김() {
        var s = PersonalTermsState.sample
        #expect(s.estimateText == "약 1,184,000원")
        s.amount = 13_000
        #expect(s.estimateText == nil)
        s.amount = 12_000
        #expect(s.estimateText == "약 1,184,000원")
        s.workplace = "다른 곳" // 금액에 영향 없는 값은 그대로
        #expect(s.estimateText != nil)
    }

    @Test func 시트에서_고른_같은_값이면_서버_예상_유지() {
        let s = PersonalTermsState.sample
        let r = s.applying(pickedStart: 17 * 60, end: 22 * 60, breakMinutes: 30)
        #expect(r == s)
        #expect(r.estimateText == "약 1,184,000원")
    }

    @Test func 시트에서_고른_값이_바뀌면_옛_예상_숨김() {
        let s = PersonalTermsState.sample
        let r = s.applying(pickedStart: 18 * 60 + 30, end: 23 * 60, breakMinutes: 60)
        #expect(r.timeRangeText == "18:30 \u{2013} 23:00")
        #expect(r.breakText == "60분")
        #expect(r.estimateText == nil)
        #expect(r.days == s.days && r.amount == s.amount && r.payday == s.payday)
        let b = s.applying(pickedStart: 17 * 60, end: 22 * 60, breakMinutes: 0)
        #expect(b.estimateText == nil)
    }

    @Test func 시트에서_고른_값_하루_경계() {
        let s = PersonalTermsState.sample
        let overnight = s.applying(pickedStart: 22 * 60, end: 6 * 60, breakMinutes: 30) // 끝이 시작보다 이르면 다음 날
        #expect(overnight.startMinute == 1320 && overnight.endMinute == 360)
        let low = s.applying(pickedStart: -30, end: 0, breakMinutes: 30)
        #expect(low.startMinute == 0 && low.endMinute == 0)
        let high = s.applying(pickedStart: 24 * 60, end: 24 * 60 + 30, breakMinutes: 30)
        #expect(high.startMinute == 1439 && high.endMinute == 1439)
        let badBreak = s.applying(pickedStart: 17 * 60, end: 22 * 60, breakMinutes: 45) // 알약에 없는 값은 무시
        #expect(badBreak.breakMinutes == 30)
    }
}
