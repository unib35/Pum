// UI-IOS-1g — 근무 캘린더 달력 칸 배치 · 상태 점 매핑 · 표시 문구
import Foundation
import Testing
@testable import Pum

struct WorkCalendarTests {
    let state = WorkCalendarState.sample

    @Test func 서울_그레고리력_일요일_시작() {
        #expect(WorkCalendarLayout.calendar.timeZone.identifier == "Asia/Seoul")
        #expect(WorkCalendarLayout.calendar.firstWeekday == 1)
    }

    @Test func 월_2026년_10월은_앞_빈칸_4개_31일_5주() throws {
        let l = try #require(WorkCalendarLayout(year: 2026, month: 10))
        #expect(l.leadingBlanks == 4) // 10/1 목요일
        #expect(l.dayCount == 31)
        #expect(l.weekCount == 5)
        #expect(l.weekdayName(of: 1) == "목")
        #expect(l.weekdayName(of: 3) == "토")
        #expect(l.day(atSlot: 3) == nil)
        #expect(l.day(atSlot: 4) == 1)
        #expect(l.day(atSlot: 34) == 31)
        #expect(l.day(atSlot: 35) == nil)
    }

    @Test func 월_2026년_2월은_28일_4주_앞_빈칸_0개() throws {
        let l = try #require(WorkCalendarLayout(year: 2026, month: 2)) // 2/1 일요일
        #expect(l.leadingBlanks == 0)
        #expect(l.dayCount == 28)
        #expect(l.weekCount == 4)
    }

    @Test func 윤년_2월은_29일() throws {
        let l = try #require(WorkCalendarLayout(year: 2028, month: 2))
        #expect(l.dayCount == 29)
        #expect(l.leadingBlanks == 2) // 2028-02-01 화요일
    }

    @Test func 월_6주가_필요한_달() throws {
        let l = try #require(WorkCalendarLayout(year: 2026, month: 8)) // 8/1 토요일, 31일
        #expect(l.leadingBlanks == 6)
        #expect(l.weekCount == 6)
    }

    @Test func 잘못된_월은_nil() {
        #expect(WorkCalendarLayout(year: 2026, month: 13) == nil)
    }

    @Test func 일요일_판정() throws {
        let l = try #require(WorkCalendarLayout(year: 2026, month: 10))
        let sundays = (1...l.dayCount).filter(l.isSunday)
        #expect(sundays == [4, 11, 18, 25])
    }

    @Test func 상태_점_종류_매핑() {
        let m = state.marks
        for d in [2, 3] { #expect(m[d] == .dot(.confirmed)) }
        for d in [5, 7, 9, 14, 16, 19, 21, 23, 26, 28, 30] { #expect(m[d] == .dot(.planned)) }
        #expect(m[12] == .dot(.substitute))
        #expect(m[29] == .dayOff)
        #expect(!m.values.contains(.dot(.absent))) // 이번 달 결근 없음
        #expect(m[1] == nil)
    }

    @Test func 범례_문구_순서() {
        #expect(WorkCalendarDot.allCases.map(\.title) == ["확정", "예정", "대타 요청 중", "결근"])
    }

    @Test func 칸_읽기_문구() {
        let l = state.layout
        #expect(l.accessibilityLabel(day: 12, mark: .dot(.substitute), isToday: false) == "10월 12일 월요일, 대타 요청 중")
        #expect(l.accessibilityLabel(day: 29, mark: .dayOff, isToday: false) == "10월 29일 목요일, 휴무")
        #expect(l.accessibilityLabel(day: 3, mark: .dot(.confirmed), isToday: true) == "10월 3일 토요일, 확정, 오늘")
        #expect(l.accessibilityLabel(day: 1, mark: nil, isToday: false) == "10월 1일 목요일")
    }

    @Test func 서버_값을_그대로_표시() {
        let s = state.selected
        #expect(s.actualRange == "16:58 \u{2013} 22:31")
        #expect(s.plannedText == "(예정 17\u{2013}22)")
        #expect(s.recognizedText == "인정 5시간 03분 \u{00B7} 60,600원")
        let m = state.summary
        #expect(m.confirmedText == "확정 2일 \u{00B7} 10시간 06분")
        #expect(m.workDaysText == "17일")
        #expect(m.totalText == "82시간 30분")
        #expect(m.overtimeText == "6시간 30분")
        #expect(m.payText == "1,188,000원")
        #expect(state.monthTitle == "2026년 10월")
    }
}
