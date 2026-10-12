// UI-IOS-6p · REQ-095 — 근무 달력 빈 상태: 기본 nil · 원문 값 · 읽기 문구
import Testing
@testable import Pum

struct WorkCalendarEmptyTests {
    @Test func 기본_상태는_빈_상태가_아니다() {
        #expect(WorkCalendarState.sample.empty == nil)
    }

    @Test func 원문_값() {
        let s = WorkCalendarState.empty
        #expect(s.monthTitle == "2026년 10월")
        #expect(s.marks.isEmpty)
        #expect(s.empty?.nextWorkText == "10월 5일 월 17:00")
        #expect(s.empty?.plannedDays.contains(5) == true)
        #expect(s.empty?.plannedDays.contains(6) == false)
    }

    @Test func 원문_문구() {
        let e = WorkCalendarEmpty.sample
        #expect(WorkCalendarEmpty.title == "아직 근무기록이 없어요")
        #expect(WorkCalendarEmpty.hint == "첫 근무를 기록하면 여기에 날짜별로 쌓여요.")
        #expect(e.nextWorkLine == "다음 근무는 10월 5일 월 17:00이에요.")
        #expect(WorkCalendarEmpty.scheduleButton == "스케줄 보기")
    }

    @Test func 읽기_문구() {
        let e = WorkCalendarEmpty.sample
        #expect(e.accessibilityText == "아직 근무기록이 없어요, 첫 근무를 기록하면 여기에 날짜별로 쌓여요. 다음 근무는 10월 5일 월 17:00이에요.")
        #expect(e.dayLabel(5) == "5일, 근무 예정")
        #expect(e.dayLabel(6) == "6일")
    }
}
