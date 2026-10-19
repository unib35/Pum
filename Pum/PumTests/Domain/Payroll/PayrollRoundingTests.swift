// DEC-031 — 월급 계산 모듈: 반올림 · 절사 · 표기 · 날짜 규칙 고정
import Testing
import Foundation
@testable import Pum

struct PayrollRoundingTests {
    @Test func 원_미만_반올림() {
        #expect(PayrollRounding.won(1, over: 2) == 1)        // 0.5 → 1
        #expect(PayrollRounding.won(1, over: 3) == 0)        // 0.33 → 0
        #expect(PayrollRounding.won(2, over: 3) == 1)        // 0.67 → 1
        #expect(PayrollRounding.won(501_725, over: 60) == 8_362) // 8,362.08 → 8,362
        #expect(PayrollRounding.won(0, over: 60) == 0)
        #expect(PayrollRounding.won(-5, over: 60) == 0)
    }

    @Test func 십원_미만_절사() {
        #expect(PayrollRounding.truncateToTen(2_969) == 2_960)
        #expect(PayrollRounding.truncateToTen(2_970) == 2_970)
        #expect(PayrollRounding.truncateToTen(9) == 0)
        #expect(PayrollRounding.truncateToTen(0) == 0)
    }

    @Test func 표기() {
        #expect(PayrollText.won(990_000) == "990,000원")
        #expect(PayrollText.won(0) == "0원")
        #expect(PayrollText.grouped(1_234_567) == "1,234,567")
        #expect(PayrollText.grouped(100) == "100")
        #expect(PayrollText.duration(4_950) == "82시간 30분")
        #expect(PayrollText.duration(480) == "8시간")
        #expect(PayrollText.duration(30) == "30분")
        #expect(PayrollText.duration(0) == "0분")
    }
}

struct PayrollDateTests {
    @Test func 요일() {
        #expect(PayrollDate(1970, 1, 1).weekday == .thursday)
        #expect(PayrollDate(2026, 10, 1).weekday == .thursday)
        #expect(PayrollDate(2026, 11, 1).weekday == .sunday)
        #expect(PayrollDate(2028, 2, 29).weekday == .tuesday)
        #expect(PayrollDate(2026, 10, 1).weekMonday == PayrollDate(2026, 9, 28))
    }

    @Test func 날짜_더하기_왕복() {
        let date = PayrollDate(2026, 12, 31)
        #expect(date.adding(days: 1) == PayrollDate(2027, 1, 1))
        #expect(PayrollDate(dayNumber: date.dayNumber) == date)
        #expect(PayrollDate(2024, 3, 1).adding(days: -1) == PayrollDate(2024, 2, 29))
    }

    @Test func 급여_기간() {
        #expect(PayrollPeriod(year: 2028, month: 2).lastDay == PayrollDate(2028, 2, 29))
        #expect(PayrollPeriod(year: 2026, month: 12).lastDay == PayrollDate(2026, 12, 31))
        let october = PayrollPeriod(year: 2026, month: 10)
        #expect(october.overlappingWeekMondays == [
            PayrollDate(2026, 9, 28), PayrollDate(2026, 10, 5), PayrollDate(2026, 10, 12),
            PayrollDate(2026, 10, 19), PayrollDate(2026, 10, 26),
        ])
    }

    @Test func 서울_기준_날짜() {
        // 2026-09-30 15:30 UTC = 2026-10-01 00:30 서울
        let instant = Date(timeIntervalSince1970: 1_790_782_200)
        #expect(PayrollDate(seoul: instant) == PayrollDate(2026, 10, 1))
    }
}
