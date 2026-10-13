// UI-IOS-20c · REQ-007 — 직접 등록 2/3 근로조건
import Testing
@testable import Pum

struct DirectRegisterTermsTests {
    @Test func 원문_값() {
        let s = DirectRegisterTermsState.sample
        #expect(s.hourlyWage == 10_320)
        #expect(s.weekdays == [1, 3, 5])
        #expect(s.minimumWageText == "2026 최저 10,320원")
        #expect(s.timeRangeText == "17:00 \u{2013} 22:00")
        #expect(s.breakAndDurationText == "휴게 30분 · 하루 4시간 30분")
        #expect(s.paydayText == "매월 10일")
        #expect(s.deductionText == "3.3%")
        #expect(s.accountValueText == "추가")
        #expect(DirectRegisterTermsState.accountHint == "지급할 때 복사용 · 나중에 넣어도 돼요")
        #expect(DirectRegisterTermsState.currentStep == 2)
        #expect(s.canProceed(s.initialDraft))
    }

    @Test func 최저_미만이면_다음_잠금() {
        let s = DirectRegisterTermsState.sample
        let low = DirectRegisterTermsDraft(hourlyWage: 10_319, weekdays: [1])
        #expect(s.isBelowMinimum(low))
        #expect(!s.canProceed(low))
        #expect(DirectRegisterTermsState.belowMinimumHint == "최저임금 이상이어야 해요")
        let exact = DirectRegisterTermsDraft(hourlyWage: 10_320, weekdays: [1])
        #expect(s.canProceed(exact))
    }

    @Test func 요일_0개면_다음_잠금() {
        let s = DirectRegisterTermsState.sample
        #expect(!s.canProceed(.init(hourlyWage: 11_000, weekdays: [])))
    }

    @Test func 숫자만_받는다() {
        #expect(DirectRegisterTermsState.wage(fromInput: "10,320원") == 10_320)
        #expect(DirectRegisterTermsState.wage(fromInput: "") == 0)
        #expect(DirectRegisterTermsState.wage(fromInput: "abc") == 0)
        #expect(DirectRegisterTermsState.wage(fromInput: "12345678901") == 123_456_789)
    }

    @Test func 넘기는_값() {
        let s = DirectRegisterTermsState.sample
        let v = s.value(.init(hourlyWage: 11_000, weekdays: [5, 1, 3]))
        #expect(v == DirectRegisterTermsValue(hourlyWage: 11_000, weekdays: [1, 3, 5]))
    }

    @Test func 읽기_문구() {
        let s = DirectRegisterTermsState.sample
        #expect(s.timeReadout() == "17:00 \u{2013} 22:00, 휴게 30분 · 하루 4시간 30분")
        #expect(s.accountReadout() == "계좌, 지급할 때 복사용 · 나중에 넣어도 돼요, 추가")
        #expect(s.paydayReadout() == "급여일, 매월 10일")
        #expect(s.deductionReadout() == "공제, 3.3%")
        #expect(DirectRegisterTermsState.stepReadout == "3단계 중 2단계")
        #expect(DirectRegisterTermsState.won(10_320) == "10,320원")
    }
}
