// UI-IOS-17e · REQ-050 — 게시 후 다음 주: 원문 값 · 읽기 문구 · 새로 게시 아니면 배지 없음
import Testing
@testable import Pum

struct PublishedScheduleTests {
    @Test func 캡처_상태는_원문_값() {
        let s = PublishedScheduleState.sample
        #expect(s.nextWeekTitle == "다음 주 · 10월 5일 – 11일")
        #expect(s.shifts.map(\.dateText) == ["월 5일", "수 7일", "금 9일", "토 10일"])
        #expect(s.shifts.allSatisfy { $0.rangeText == "17:00 – 22:00" && $0.hoursText == "4.5h" })
        #expect(s.shifts.map(\.isHolidayPremium) == [false, false, true, false])
        #expect(s.nextWeekHoursText == "18시간")
        #expect(s.workDaysText == "4일")
        #expect(s.expectedPayText == "243,000원")
        #expect(s.payCaption == "휴일 가산 포함")
        #expect(s.thisWeekSummary == "3일 · 14시간 30분")
        #expect(s.thisWeekTitle == "이번 주 · 9월 28일 – 10월 4일")
    }

    @Test func 읽기_문구() {
        let s = PublishedScheduleState.sample
        #expect(s.shifts[2].accessibilityText == "금 9일, 17:00부터 22:00, 휴일 가산, 4.5시간")
        #expect(s.shifts[0].accessibilityText == "월 5일, 17:00부터 22:00, 4.5시간")
        #expect(s.hoursAccessibility == "다음 주 근무, 18시간, 4일")
        #expect(s.payAccessibility == "예상 급여, 243,000원, 휴일 가산 포함")
    }

    @Test func 새로_게시가_아니면_배지_없음_휴일_가산이_없으면_문구_없음() {
        var s = PublishedScheduleState.sample
        #expect(s.isNewlyPublished)
        s.isNewlyPublished = false
        let published = s.isNewlyPublished
        #expect(!published)
        s.includesHolidayPremium = false
        let caption = s.payCaption
        let spoken = s.payAccessibility
        #expect(caption == nil)
        #expect(spoken == "예상 급여, 243,000원")
    }

    @Test func 시간_표기는_소수_한_자리() {
        #expect(PublishedFormat.decimalHours(300) == "5h")
        #expect(PublishedFormat.decimalHours(270) == "4.5h")
    }
}
